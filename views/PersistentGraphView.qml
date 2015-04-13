import QtQuick 2.4
import QtGraphicalEffects 1.0
import Graph 1.0

import "../common/utils.js" as Utils
import "../common"
import "../storage"

Item
{
    id: persistentGraphView
/**
 *     API properties
 *
 */
    Range
    {
        id: range
    }

    Range
    {
        id: viewport

        onCenterXChanged:
        {
            workspace.updateGrid();
        }

        onLeftChanged:
        {
            workspace.updateViewport();
        }

        onRightChanged:
        {
            workspace.updateViewport();
        }

        onWidthChanged:
        {
            workspace.updateViewport();
        }
    }

    readonly property alias range: range
    readonly property alias viewport: viewport
    property string database
    property string table
    property string name
    property Component background
    property color foregroundColor: "white"
    clip: true

/**
 *     API signals
 *
 */
    signal loadingFinished()

/**
 *     API functions
 *
 */
    function append(x, jsobject)
    {
        var copy = jsobject;
        copy["x"] = x;
        persistence.append(copy);
    }

    function insert(jsobject, index)
    {
        persistence.insert(jsobject, index);
    }

    function remove(index)
    {
        persistence.remove(index);
    }

    function get(index)
    {
        return persistence.get(index);
    }

    function set(jsobject, index)
    {
        persistence.set(jsobject, index);
    }

    function clear()
    {
        persistence.clear();
    }

/**
 *     Internal structure
 *
 */
    antialiasing: true
    smooth: true

    Component.onCompleted:
    {
        var roles = [];

        for (var i = 0; i < children.length; ++i)
        {
            if (children[i].isPersistentGraph)
            {
                var graph = children[i];
                if (graph.role === "x")
                {
                    throw "PersistentGraphView::onCompleted(): Role x is " +
                            "reserved. Please, specify another role.";
                }

                graph.z = -1;
                graph.anchors.fill = persistentGraphView;
                graph.anchors.bottomMargin = Qt.binding(
                    function () { return workspace.bottomMargin; });
                graph.anchors.topMargin = Qt.binding(
                    function () { return workspace.topMargin; });

                roles.push(graph.role);
                workspace.graphs.push(graph);
            }
        }
        roles.push("x");
        persistence.roles = roles;
        internalStorage.database = persistentGraphView.database;
        internalStorage.table = persistentGraphView.table;

        legend.model = workspace.graphs;
        workspace.fitToScreen();
    }

    onWidthChanged:
    {
        workspace.foreachGraph(function (graph)
        {
            graph.screenWidth = width;
        });

        workspace.updateGrid();
        workspace.fitToScreen();
    }

    onHeightChanged:
    {
        workspace.foreachGraph(function (graph)
        {
            graph.screenHeight = height;
        });

        workspace.updateGrid();
    }

    Persistence
    {
        id: persistence

        storage: SqlTableModel
        {
            id: internalStorage
            onLoadingFinished:
            {
                workspace.fitToScreen();
                persistentGraphView.loadingFinished();
            }
        }
    }

/**
 *     Internal item for data encapsulation
 *
 */
    Loader
    {
        sourceComponent: persistentGraphView.background
        anchors.fill: parent
        z: -2
    }

    Item
    {
        id: graphClipper
        anchors.fill: parent
    }

    Item
    {
        id: workspace
        property var graphs: []
        property int bottomMargin: 100 * mainWindow.scale
        property int topMargin:    100 * mainWindow.scale
        property int leftMargin:    50 * mainWindow.scale
        property int rightMargin:    0 * mainWindow.scale

        readonly property int widthMinusMargins:
            persistentGraphView.width - (leftMargin + rightMargin)

        anchors.fill: parent
        anchors.leftMargin: leftMargin
        clip: true

        onLeftMarginChanged:
        {
            fitToScreen();
        }

/**
 *     Some functions for convenient iteration
 *
 */

        function foreachGraph(proc)
        {
            for (var i = 0; i < graphs.length; ++i)
            {
                proc(graphs[i]);
            }
        }

        function foreachRowWithIndex(proc)
        {
            for (var i = 0; i < internalStorage.count; ++i)
            {
                proc(internalStorage.get(i), i);
            }
        }

        function foreachRow(proc)
        {
            for (var i = 0; i < internalStorage.count; ++i)
            {
                proc(internalStorage.get(i));
            }
        }

/**
 *     Graph-specific functions
 *
 */
        function fitToScreen()
        {
            var left = 0;
            var right = 0;
            var bottom = 0;
            var top = 0;

            foreachGraph(function (graph)
            {
                graph.parent = workspace
                graph.anchors.fill = workspace
                graph.anchors.leftMargin = -leftMargin
            });

            if (internalStorage.count > 0)
            {
                var jsobject = internalStorage.get(0);
                left = jsobject.x;
                right = jsobject.x;
                bottom = 0;
                top = 0;
            }

            for (var i = 0; i < internalStorage.count; ++i)
            {
                jsobject = internalStorage.get(i);
                left   = Math.min(left,   jsobject.x);
                right  = Math.max(right,  jsobject.x);

                for (var j = 0; j < graphs.length; ++j)
                {
                    bottom = Math.min(bottom, jsobject[graphs[j].role]);
                    top    = Math.max(top,    jsobject[graphs[j].role]);
                }
            }

            range.init((left + right) / 2,
                       (top + bottom) / 2,
                       (right - left),
                       (top - bottom));

            var s = horizontalGrid.step();

            bottom = bottom - bottom % s;
            top = top - top % s + s;

            left -= workspace.leftMargin / persistentGraphView.width * (right - left);

            viewport.init((left + right) / 2,
                          (top + bottom) / 2,
                          (right - left),
                          (top - bottom));

            updateBuffer();
            updateGrid();
        }

/**
 *      Coordinate conversion
 *
 */
        function to_screen(x, y)
        {
            var y0 = workspace.bottomMargin;
            var w = persistentGraphView.width;
            var h = persistentGraphView.height - footer.height - header.height;

            return Qt.point(w * (x - viewport.left) / viewport.width,
                            y0 + h * (1. - (y - viewport.bottom) / viewport.height));
        }

        function fromScreen(x, y)
        {
            x -= workspace.leftMargin;
            y -= workspace.topMargin

            return Qt.point(viewport.left   + viewport.width  * (x / persistentGraphView.width),
                            viewport.bottom + viewport.height * (1. - y / persistentGraphView.height))
        }

        function dxFromScreen(dx)
        {
            return dx * viewport.width / persistentGraphView.width;
        }

/**
 *      Update functions
 *
 */
        function updateGrid()
        {
            horizontalGrid.update();
            verticalGrid.update();
        }

        function updateBuffer()
        {
            workspace.foreachGraph(function (graph)
            {
                var vertices = [];

                graph.clear();

                workspace.foreachRow(function (row)
                {
                    var u = viewport.normalizeX(row.x);
                    var v = viewport.normalizeY(row[graph.role]);

                    graph.push_back(row.x - range.left, v);
                });
            });
        }

        function updateViewport()
        {
            workspace.foreachGraph(function (graph)
            {
                graph.setLeft(viewport.left - range.left);
                graph.setRight(viewport.right - range.left);
            });
        }
    }

/**
 *      Navigation item
 *
 */
    MultiPointTouchArea
    {
        id: navigation

        property real centerX
        property real zoomDistance0
        property int numPressed: 0

        property int state: Graph.Idle
        readonly property int pixelThreshold: 30 * mainWindow.scale

        anchors.fill: parent
        touchPoints: [
            TouchPoint { id: point1 },
            TouchPoint { id: point2 }
        ]

        function distance(p1, p2)
        {
            var diff = Qt.point(point2.x - point1.x, point2.y - point1.y);
            return  Math.sqrt(diff.x * diff.x + diff.y * diff.y);
        }

        function gravityCenter()
        {
            var sum = 0;
            var count = 0;
            if (point1.pressed)
            {
                sum += point1.x;
                ++count;
            }
            if (point2.pressed)
            {
                sum += point2.x;
                ++count;
            }
            if (count == 0)
            {
                return 0;
            }
            return sum / count;
        }

        onPressed:
        {
            centerX = gravityCenter();
            ++numPressed;

            if (state === Graph.Idle)
            {
                if (numPressed == 1)
                {
                    state = Graph.ReadyToPan;
                    viewport.stopMoving();
                }
            }
            else if (state === Graph.Pan ||
                     state === Graph.ReadyToPan)
            {
                if (numPressed == 2)
                {
                    state = Graph.Zoom;
                    var t0 = workspace.fromScreen(point1.x, 0).x;
                    var t1 = workspace.fromScreen(point2.x, 0).x;

                    zoomDistance0 = distance(point1, point2);
                }
            }
        }

        onReleased:
        {
            if (state === Graph.Pan)
            {
                var offset = (viewport.targetX - viewport.centerX) * 10.;
                offset = Utils.clamp(offset, -viewport.width * 2, viewport.width * 2);

                if (Math.abs(offset) > viewport.width * 0.1)
                {
                    viewport.moveInertial(offset);
                }
            }

            --numPressed;

            if (numPressed == 0)
            {
                state = Graph.Idle;
            }
            else if (numPressed == 1 &&
                     state === Graph.Zoom)
            {
                state = Graph.Pan;
                centerX = gravityCenter();
            }
        }

        onTouchUpdated:
        {
            if (state === Graph.ReadyToPan)
            {
                var dx = centerX - gravityCenter();
                if (Math.abs(dx) > pixelThreshold)
                {
                    state = Graph.Pan;
                }
            }

            if (state === Graph.Pan)
            {
                dx = centerX - gravityCenter();
                viewport.move(workspace.dxFromScreen(dx));

                centerX = gravityCenter();
            }
            else if (state === Graph.Zoom)
            {
                var dst = distance(point1, point2);
                var zoom = zoomDistance0 / dst;
                var centerXMsec = workspace.fromScreen(centerX, 0).x;

                var d0 = (centerXMsec -  viewport.left) * zoom;
                var d1 = (viewport.right - centerXMsec) * zoom;

                var x = (point1.x + point2.x) * .5;
                dx = centerX - x;
                centerXMsec += workspace.dxFromScreen(dx);

                var l = centerXMsec - d0;
                var r = centerXMsec + d1;

                viewport.moveTo((l + r) * .5);
                viewport.width *= zoom;

                zoomDistance0 = dst;
                centerX = x;
            }
        }
    }

/**
 *      Header and footer
 *
 */
    Item
    {
        id: header

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: workspace.topMargin

        Column
        {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                rightMargin: workspace.rightMargin
            }

            Rectangle
            {
                width: parent.width
                height: 1
                color: Qt.lighter(persistentGraphView.foregroundColor, 6)
            }

            Rectangle
            {
                width: parent.width
                height: 1
                color: persistentGraphView.foregroundColor
            }

            Rectangle
            {
                width: parent.width
                height: 1
                color: Qt.lighter(persistentGraphView.foregroundColor, 8)
            }
        }



        Text
        {
            anchors.centerIn: parent
            text: persistentGraphView.name
            color: persistentGraphView.foregroundColor
            font.pixelSize: header.height / 3
        }
    }

    Item
    {
        id: footer

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: workspace.bottomMargin

/**
 *      Graph legend
 *
 */
        ListView
        {
            id: legend

            anchors.centerIn: parent
            width: childrenRect.width
            orientation: ListView.Horizontal
            spacing: 30 * mainWindow.scale

            delegate: Row
            {
                spacing: 10 * mainWindow.scale
                Rectangle
                {
                    id: rect
                    width: footer.height / 4
                    height: width
                    color: Qt.rgba(
                               modelData.color.r,
                               modelData.color.g,
                               modelData.color.b,
                               0.4);
                    border.color: modelData.color
                    opacity: 0.8
                }

                Text
                {
                    anchors.verticalCenter: rect.verticalCenter
                    text: modelData.name
                    color: persistentGraphView.foregroundColor
                    font.pixelSize: footer.height / 4
                }
            }
        }
    }

/**
 *      Grid
 *
 */
    Item
    {
        id: grid
        anchors.fill: parent

        Repeater
        {
            id: horizontalGrid

            readonly property int tickSize: 5 * mainWindow.scale

            delegate: Rectangle
            {
                height: 1
                width: persistentGraphView.width - workspace.leftMargin
                x: workspace.leftMargin
                y: model_y
                color: persistentGraphView.foregroundColor

                Rectangle
                {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    width: parent.width
                    height: parent.height
                    color: Qt.lighter(parent.color, 5)
                    opacity: 0.4
                }

                Rectangle
                {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    width: parent.width
                    height: parent.height
                    color: Qt.lighter(parent.color, 8)
                    opacity: 0.4
                }

                Text
                {
                    anchors.right: parent.left
                    anchors.rightMargin: 5 * mainWindow.scale
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 15 * mainWindow.scale
                    color: persistentGraphView.foregroundColor
                    text: model_text

                }
            }

            model: ListModel
            {
                id: horizontalGridModel
            }

            function step()
            {
                var steps = [
                    1,
                    2,
                    5,
                    10,
                    15,
                    25,
                    50,
                    100,
                    150,
                    200,
                    500,
                    750,
                    1000,
                    1500,
                    2000
                ];

                var h = viewport.top - viewport.bottom;
                for(var i in steps)
                {
                    if(steps[i] * 4 > h)
                    {
                        break;
                    }
                }

                return steps[i];
            }

            function update()
            {
                var s = step();
                var h = viewport.top - viewport.bottom;
                var y = viewport.bottom - viewport.bottom % s;
                var text_size = Math.floor(15 * mainWindow.scale)
                var points = [];

                while(y < h)
                {
                    var p = workspace.to_screen(0, y);
                    var point = {model_y: p.y, model_text: "" + y};

                    if (y <= persistentGraphView.height - workspace.bottomMargin)
                    {
                        points.push(point);
                    }
                    y += s;
                }

                for (var i = 0; i < Math.min(horizontalGridModel.count, points.length); ++i)
                {
                    horizontalGridModel.set(i, points[i]);
                }

                if (horizontalGridModel.count <= points.length)
                {
                    for (i = horizontalGridModel.count; i < points.length; ++i)
                    {
                        horizontalGridModel.append(points[i]);
                    }
                }
                else
                {
                    while (horizontalGridModel.count > points.length)
                    {
                        horizontalGridModel.remove(horizontalGridModel.count - 1);
                    }
                }
            }
        }

        Repeater
        {
            id: verticalGrid

            readonly property int tickHeight: 10 * mainWindow.scale

            delegate: Item
            {
                height: persistentGraphView.height
                width: 1
                x: model_x

                readonly property real c1: Math.pow(
                    x / workspace.widthMinusMargins, 0.35)

                readonly property real c2: Math.pow(
                    (persistentGraphView.width - workspace.rightMargin - x) / workspace.widthMinusMargins, 0.35)

                opacity: c1 * c2

                Rectangle
                {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: workspace.bottomMargin - height
                    width: 1
                    height: verticalGrid.tickHeight
                }


                Text
                {
                    id: verticalGridText

                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: workspace.bottomMargin - height - verticalGrid.tickHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 15 * mainWindow.scale
                    color: persistentGraphView.foregroundColor
                    text: model_text

                }
            }

            model: ListModel
            {
                id: verticalGridModel
            }

            function daysInMonth(month, year)
            {
                var d= new Date(year, month + 1, 0);
                return d.getDate();
            }

            function toStartOfTheDay(date)
            {
                var result = new Date(date);
                result.setHours(0);
                result.setMinutes(0);
                result.setSeconds(0);
                return result;
            }

            function isStartOfTheDay(date)
            {
                return date.getHours()   === 0 &&
                       date.getMinutes() === 0 &&
                       date.getSeconds() === 0;
            }

            function buildHourScale()
            {
                if (viewport.width == 0)
                {
                    return [];
                }

                var ticks = [];

                var s = step();
                var oneHour = 1000 * 60 * 60;
                var oneMinute = 1000 * 60;

                var leftLocal = viewport.left + (new Date()).getTimezoneOffset() * oneMinute;
                var date = new Date(viewport.left - leftLocal % s.value);
                var x = date.getTime();

                while (x < viewport.right)
                {
                    var format = isStartOfTheDay(date) ? "dd MMM" : s.format;

                    ticks.push({time: x, format: format});

                    x += s.value;
                    date.setTime(x);
                }

                return ticks;
            }

            function buildDayScale()
            {
                var date = new Date(viewport.left);
                date.setHours(0);
                date.setMinutes(0);
                date.setSeconds(0);
                date.setDate(1);

                var x = date.getTime();
                var ticks = [];
                var oneDay = 1000 * 60 * 60 * 24;
                var s = step();
                var xPrev = 0;

                var steps = [1, 2, 6, 12];
                var s1 = Math.max(1., Math.ceil(s.value / oneDay));

                for (var i = 0; i < steps.length; ++i)
                {
                    s.value = steps[i];
                    if (s1 <= steps[i])
                    {
                        break;
                    }
                }

                var prevDate = new Date(date);

                while (x < viewport.right)
                {
                    var dx = x - prevDate.getTime();

                    if (ticks.length > 0 &&
                        dx < s.value * oneDay)
                    {
                        ticks[ticks.length - 1].time = x;
                    }
                    else if (x > viewport.left)
                    {
                        ticks.push({time: x, format: "dd MMM"});
                    }

                    x += s.value * oneDay;
                    prevDate.setTime(date.getTime());
                    date.setTime(x);

                    if (date.getMonth() != prevDate.getMonth())
                    {
                        date.setDate(1);
                        x = date.getTime();
                    }
                }

                return ticks;
            }

            function buildMonthScale()
            {
                var date = new Date(viewport.left);
                date.setHours(0);
                date.setMinutes(0);
                date.setSeconds(0);
                date.setDate(1);
                date.setMonth(1);

                var x = date.getTime();
                var ticks = [];
                var oneDay = 1000 * 60 * 60 * 24;
                var oneMonth = oneDay * 30;
                var s = step();

                var steps = [1, 2, 6];
                var s1 = Math.max(1., Math.ceil(s.value / oneMonth));

                for (var i = 0; i < steps.length; ++i)
                {
                    s.value = steps[i];
                    if (s1 <= steps[i])
                    {
                        break;
                    }
                }

                while (x < viewport.right)
                {
                    ticks.push({time: x, format: "MMM yyyy"});

                    for (i = 0; i < s.value; ++i)
                    {
                        x += oneDay * daysInMonth(date.getMonth(), date.getFullYear());
                        date.setTime(x);
                    }
                }

                return ticks;
            }

            function buildYearScale()
            {
                console.log("year")

            }

            function update()
            {
                var ticks = [];
                var ticksInModel = [];
                var day = 1000 * 60 * 60 * 24;

                if (viewport.width < 2 * day)
                {
                    ticks = buildHourScale();
                }
                else if (viewport.width < 30 * day)
                {
                    ticks = buildDayScale();
                }
                else if (viewport.width < 365 * day)
                {
                    ticks = buildMonthScale();
                }
                else
                {
                    ticks = buildYearScale();
                }

                for (var i = 0; i < ticks.length; ++i)
                {
                    var p = workspace.to_screen(ticks[i].time, 0);
                    var date = new Date(ticks[i].time);

                    ticksInModel.push({
                        model_x: p.x,
                        model_text: application.formatDate(date, ticks[i].format)});
                }

                for (i = 0; i < Math.min(verticalGridModel.count, ticksInModel.length); ++i)
                {
                    verticalGridModel.set(i, ticksInModel[i]);
                }

                if (verticalGridModel.count <= ticksInModel.length)
                {
                    for (i = verticalGridModel.count; i < ticksInModel.length; ++i)
                    {
                        verticalGridModel.append(ticksInModel[i]);
                    }
                }
                else
                {
                    while (verticalGridModel.count > ticksInModel.length)
                    {
                        verticalGridModel.remove(verticalGridModel.count - 1);
                    }
                }
            }

            function step()
            {
                var timeSteps = [
                    "hh:mm:ss", 1000,
                    "hh:mm:ss", 1000 * 5,
                    "hh::mm:ss", 1000 * 10,
                    "hh::mm:ss", 1000 * 30,
                    "hh:mm", 1000 * 60,
                    "hh:mm", 1000 * 60 * 5,
                    "hh:mm", 1000 * 60 * 10,
                    "hh:mm", 1000 * 60 * 30,
                    "hh:mm", 1000 * 60 * 60,
                    "hh:mm", 1000 * 60 * 60 * 3,
                    "hh:mm", 1000 * 60 * 60 * 6,
                    "hh:mm", 1000 * 60 * 60 * 12,
                    "dd MMM yyyy", 1000 * 60 * 60 * 24,
                    "dd MMM yyyy", 1000 * 60 * 60 * 24 * 5,
                    "dd MMM yyyy", 1000 * 60 * 60 * 24 * 10,
                    "dd MMM yyyy", 1000 * 60 * 60 * 24 * 30,
                    "dd MMM yyyy", 1000 * 60 * 60 * 24 * 60,
                    "dd MMM yyyy", 1000 * 60 * 60 * 24 * 120,
                    "dd MMM yyyy", 1000 * 60 * 60 * 24 * 365
                ];

                var step = 1000;
                var format = "ss";
                var rangeX = (viewport.right - viewport.left);

                for (var i = 1; i < timeSteps.length; i += 2)
                {
                    step = timeSteps[i];
                    format = timeSteps[i - 1];
                    if (step > rangeX / 8)
                    {
                        break;
                    }
                }

                return {value: step, format: format};
            }
        }
    }
}
