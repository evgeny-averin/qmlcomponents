import QtQuick 2.4

Item
{
    id: quotesProvider

    property bool logging: true

    function querySymbols(text, proc)
    {
        yahoo.querySymbols(text, proc);
    }

    function queryDailyData(symbol, handleRows, field)
    {
        return yahoo.queryDailyData(symbol, handleRows, field);
    }

    function queryWeeklyData(symbol, handleRows)
    {
        return yahoo.queryWeeklyData(symbol, handleRows);
    }

    function queryMonthlyData(symbol, handleRows)
    {
        return yahoo.queryMonthlyData(symbol, handleRows);
    }

    function queryYearData(symbol, handleRows)
    {
        return yahoo.queryYearData(symbol, handleRows);
    }

    function queryNews(symbol, proc)
    {
        return yahoo.queryNews(symbol, proc)
    }

    function subscribe(symbol, item, handler)
    {
        yahoo.subscribe(symbol, item, handler);
    }

    function unsubscribe(item)
    {
        yahoo.unsubscribe(item);
    }

    // Yahoo Finance query interface

    Item
    {
        id: yahoo

        property var subscriptions

        // Specific functions
        function querySymbols(text, proc)
        {
            var service = "http://autoc.finance.yahoo.com/autoc?";
            var query = "query=" + text + "&format=json&callback=YAHOO.Finance.SymbolSuggest.ssCallback"

            send(service + query, function(data)
            {
                data = data.substring("YAHOO.Finance.SymbolSuggest.ssCallback(".length, data.length - 1);

                var obj = JSON.parse(data);
                if (typeof(obj) == "object")
                {
                    var results = obj.ResultSet.Result;
                    var foundSymbols = [];

                    for (var i in results)
                    {
                        foundSymbols.push({
                            symbol:   results[i].symbol,
                            name:     results[i].name,
                            exch:     results[i].exch,
                            exchDisp: results[i].exchDisp,
                            typeDisp: results[i].typeDisp
                        });
                    }

                    if (proc)
                    {
                        proc(foundSymbols);
                    }
                }
            });
        }

        function queryDailyData(symbol, handleRows, field)
        {
            queryChartAPI(symbol, field, "1d", function (receivedRows)
            {
                var rows = [];
                for (var i = receivedRows.length - 1; i >= 0; --i)
                {
                    rows.push(receivedRows[i]);
                }

                if (handleRows)
                {
                    handleRows(rows);
                }
            });
        }

        function queryChartAPI(symbol, valueName, interval, handleRows)
        {
            var q = "http://chartapi.finance.yahoo.com/instrument/" +
                    "1.0/{symbol}/chartdata;type={valueName};range={interval}/json/";

            q = q.replace("{symbol}",    symbol)
                 .replace("{valueName}", valueName)
                 .replace("{interval}",  interval);

            send(q, function (json)
            {
                try
                {
                    json = json.substring("finance_charts_json_callback( ".length, json.length - 2);

                    var obj = JSON.parse(json);
                    if (typeof(obj) == "object")
                    {
                        var series = obj.series;
                        var foundSymbols = [];
                        var rows = [];

                        for (var i = 0; i < series.length; ++i)
                        {
                            var timestamp = checkField(series[i], "Timestamp");
                            var date = new Date();

                            if (timestamp)
                            {
                                date = new Date(timestamp * 1000);
                            }
                            else
                            {
                                var isoDate = "" + checkField(series[i], "Date");

                                if (isoDate)
                                {
                                    var day   = isoDate.substr(isoDate.length - 2, 2);
                                    var month = isoDate.substr(isoDate.length - 4, 2);
                                    var year  = isoDate.substr(0, isoDate.length - 4, 2);
                                    date = new Date(year, month, day);
                                }
                            }

                            var value = checkField(series[i], valueName);
                            if (!value)
                            {
                                value = 0;
                            }

                            var row = {date: date};
                            row[valueName] = value;

                            rows.push(row);
                        }

                        if (handleRows)
                        {
                            handleRows(rows);
                        }
                    }
                }
                catch (err)
                {
                    if (logging)
                    {
                        console.log(err);
                    }
                }
            });
        }

        function queryWeeklyData(symbol, handleRows)
        {
            var now = new Date();
            var aweekAgo = new Date(now - 1000 * 3600 * 24 * 7);

            var nowStr = application.formatDate(now, "yyyy-MM-dd");
            var aweekagoStr = application.formatDate(aweekAgo, "yyyy-MM-dd");

            var q = "select * from yahoo.finance.historicaldata where symbol = \"" + symbol + "\"" +
                    " and startDate = \"" + aweekagoStr + "\" and endDate = \"" + nowStr + "\"";

            query(q, parseHistoryQuotes, handleRows);
        }

        function queryMonthlyData(symbol, handleRows)
        {
            var now = new Date();
            var aMonthAgo = new Date(now - 1000 * 3600 * 24 * 30);

            var nowStr = application.formatDate(now, "yyyy-MM-dd");
            var aMonthAgoStr = application.formatDate(aMonthAgo, "yyyy-MM-dd");

            var q = "select * from yahoo.finance.historicaldata where symbol = \"" + symbol + "\"" +
                    " and startDate = \"" + aMonthAgoStr + "\" and endDate = \"" + nowStr + "\"";

            query(q, parseHistoryQuotes, handleRows);
        }

        function queryYearData(symbol, handleRows)
        {
            var now = new Date();
            var aYearAgo = new Date(now - 1000 * 3600 * 24 * 365);

            var nowStr = application.formatDate(now, "yyyy-MM-dd");
            var aMonthAgoStr = application.formatDate(aYearAgo, "yyyy-MM-dd");

            var q = "select * from yahoo.finance.historicaldata where symbol = \"" + symbol + "\"" +
                    " and startDate = \"" + aMonthAgoStr + "\" and endDate = \"" + nowStr + "\"";


            query(q, parseHistoryQuotes, function (rows)
            {
                var month = -1;
                var outRows = [];

                for (var i = 0; i < rows.length; ++i)
                {
                    var row = rows[i];
                    if (row.date.getMonth() !== month)
                    {
                        outRows.push(row);
                        month = row.date.getMonth();
                    }
                    else
                    {
                        var last = outRows[outRows.length - 1];
                        last.volume = Math.max(last.volume, row.volume);
                    }
                }

                handleRows(outRows);
            });
        }

        function queryNews(symbol, handleRows)
        {
            var q = "https://query.yahooapis.com/v1/public/yql?q=" +
                    "select%20*%20from%20html%20where%20url%3D'" +
                    "http%3A%2F%2Ffinance.yahoo.com%2Fq%3Fs%3D" + symbol +
                    "'%20and%20xpath%3D'%2F%2Fdiv%5B%40id%3D%22yfi_headlines" +
                    "%22%5D%2Fdiv%5B2%5D%2Ful%2Fli'&format=json&" +
                    "diagnostics=true&env=store%3A%2F%2Fdatatables.org%2" +
                    "Falltableswithkeys&callback=";

            send(q, function (data)
            {
                try
                {
                    var obj = JSON.parse(data);

                    if (typeof(obj) == "object")
                    {
                        if (obj.hasOwnProperty("query") &&
                            obj.query.hasOwnProperty("results") &&
                            obj.query.results.hasOwnProperty("li"))
                        {
                            var rows = [];
                            var news = obj.query.results.li;

                            for (var i = 0; i < news.length; ++i)
                            {
                                rows.push({
                                    description: news[i].a.content,
                                    title:       news[i].a.content,
                                    url:         news[i].a.href,
                                    date:        news[i].cite.content,
                                    time:        news[i].cite.span
                                })
                            }

                            rows.sort(function (a, b)
                            {
                                return a.date > b.date ? -1 :
                                       a.date < b.date ?  1 : 0;
                            });

                            if (handleRows)
                            {
                                handleRows(rows);
                            }
                        }
                    }
                }
                catch (err)
                {
                    console.log(err);
                }
            });
        }

        function queryRealtimeData(symbols, handleRows)
        {
            var q = "select * from yahoo.finance.quotes where symbol in (" + symbols.join() + ")";

            if (logging)
            {
                console.log(q);
            }

            query(q, parseRealtimeQuotes, handleRows);
        }

        // Subscribe/unsubscribe
        function subscribe(symbol, item, handler)
        {
            if (logging)
            {
                console.log("subscribe to", symbol, handler);
            }

            if (!subscriptions)
            {
                subscriptions = {};
            }

            if (!subscriptions[symbol])
            {
                subscriptions[symbol] = [];
            }

            subscriptions[symbol].push(
                {item: item, handler: handler});

            realtimeQueryTimer.restartWithTimeout(500);
        }

        function unsubscribe(item)
        {
            if (!subscriptions)
            {
                return;
            }

            for (var symbol in subscriptions)
            {
                for (var i = 0; i < subscriptions[symbol].length;)
                {
                    if (subscriptions[symbol][i].item === item)
                    {
                        if (logging)
                        {
                            console.log("removing subscription to", symbol);
                        }

                        subscriptions[symbol].splice(i, 1);
                    }
                    else
                    {
                        ++i;
                    }
                }
            }
        }

        // General Purpose functions
        function query(q, parseFunc, perRowFunc)
        {
            var url = "http://query.yahooapis.com/v1/public/yql?q=";
            var format = "&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback=";

            send(url + q + format, parseFunc, perRowFunc);
        }

        function send(q, parseFunc, handleRows)
        {
            if (logging)
            {
                console.log(q);
            }

            var doc = new XMLHttpRequest();
            var res;
            doc.onreadystatechange = function ()
            {
                if (doc.readyState === XMLHttpRequest.DONE)
                {
                    res = doc.responseText;
                    if (parseFunc)
                    {
                        parseFunc(res, handleRows);
                    }
                }
            };
            doc.open("GET", q, true);
            doc.send();
        }

        function checkField(object, field)
        {
            if (!object[field])
            {
                console.log("checkField: field \"" + field + "\" is unavailable. Invalid response format.");
                return undefined;
            }

            return object[field];

        }

        function parseHistoryQuotes(data, handleRows)
        {
            var obj = JSON.parse(data);

            try
            {
                if (typeof(obj) == "object")
                {
                    var query = checkField(obj, "query");
                    var results = checkField(query, "results");
                    var quotes = checkField(results, "quote");

                    var rows = [];

                    for (var i in quotes)
                    {
                        var dateStr = checkField(quotes[i], "Date");
                        var open    = checkField(quotes[i], "Open");
                        var low     = checkField(quotes[i], "Low");
                        var high    = checkField(quotes[i], "High");
                        var close   = checkField(quotes[i], "Close");
                        var volume  = checkField(quotes[i], "Volume");

                        var date = new Date(dateStr);

                        rows.push({
                            date: date,
                            open: open,
                            low: low,
                            high: high,
                            close: close,
                            volume: volume
                        });
                    }

                    if (handleRows)
                    {
                        handleRows(rows);
                    }
                }
            }
            catch(err)
            {
                console.log(err);
            }
        }

        function parseRealtimeQuotes(data, handleRows)
        {
            var obj = JSON.parse(data);

            try
            {
                if (typeof(obj) == "object")
                {
                    var query = checkField(obj, "query");
                    var results = checkField(query, "results");
                    var quotes = checkField(results, "quote");

                    var rows = [];

                    for (var i in quotes)
                    {
                        rows.push(quotes[i]);
                    }

                    if (handleRows)
                    {
                        handleRows(rows);
                    }
                }
            }
            catch (err)
            {
                console.log(err);
            }
        }

        Timer
        {
            id: realtimeQueryTimer

            interval: 5000
            repeat: true

            onTriggered:
            {
                var activeSymbols = [];

                for (var symbol in yahoo.subscriptions)
                {
                    var subscriptionsOnSymbol = yahoo.subscriptions[symbol];

                    if (subscriptionsOnSymbol.length > 0)
                    {
                        activeSymbols.push("\"" + symbol + "\"");
                    }
                }

                yahoo.queryRealtimeData(activeSymbols, handleRealtimeQuotes);
                interval = 5000;
            }

            function restartWithTimeout(timeout)
            {
                interval = timeout;
                restart();
            }

            function handleRealtimeQuotes(rows)
            {
                for (var i in rows)
                {
                    if (!rows[i])
                    {
                        continue;
                    }

                    var symbol = rows[i].symbol;
                    var subscriptionsOnSymbol = yahoo.subscriptions[symbol];

                    for (var j in subscriptionsOnSymbol)
                    {
                        try
                        {
                            subscriptionsOnSymbol[j].handler(rows[i]);
                        }
                        catch (err)
                        {
                            console.log(symbol + ":", err);
                        }
                    }
                }
            }
        }
    }
}

