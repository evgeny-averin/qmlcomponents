import QtQuick 2.0
import QtGraphicalEffects 1.0

import "../common/utils.js" as Utils
import "../storage"

Canvas
{
    id: persistentGraphView

/**
  *     API properties
  *
  */
    property var range: {"left": 0, "right": 0, "bottom": 0, "top": 0}
    property string database
    property string table

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

                roles.push(graph.role);
                internal.graphs.push(graph);
            }
        }
        roles.push("x");
        persistence.roles = roles;
        internalStorage.database = persistentGraphView.database;
        internalStorage.table = persistentGraphView.table;
    }

    Persistence
    {
        id: persistence

        storage: SqlTableModel
        {
            id: internalStorage
            onLoadingFinished:
            {
                internal.updateRange();
                persistentGraphView.loadingFinished();
            }
        }
    }

    onPaint:
    {
        var ctx = getContext("2d");

        ctx.save();
        internal.drawGrid(ctx);

        if (internalStorage.count == 0)
        {
            ctx.restore();
            return;
        }

        internal.foreachGraph(function (graph)
        {
            ctx.lineWidth = 3 * mainWindow.scale;
            ctx.strokeStyle = graph.color;
            ctx.fillStyle = graph.color;
            ctx.globalAlpha = 0.9;

/**
  *     Draw graph with stroke and fill
  *     the area under graph
  *
  */
            ctx.beginPath();

            var row = internalStorage.get(0);
            var p0 = internal.to_screen(row.x, row[graph.role]);
            var p;
            internal.foreachRowWithIndex(function (row, index)
            {
                p = internal.to_screen(row.x, row[graph.role]);
                if (index === 0)
                {
                    ctx.moveTo(p.x, p.y)
                }
                else
                {
                    ctx.lineTo(p.x, p.y)
                }
            });
            ctx.stroke();

            ctx.globalAlpha = 0.15;
            ctx.lineTo(p.x,  height);
            ctx.lineTo(p0.x, height);
            ctx.fill();

/**
  *     Draw point for the graph
  *
  */
            var size = 8 * mainWindow.scale;
            ctx.beginPath();
            internal.foreachRow(function (row)
            {
                p = internal.to_screen(row.x, row[graph.role]);
                ctx.ellipse(p.x - size / 2, p.y - size / 2, size, size)
            });
            ctx.globalAlpha = 0.9;
            ctx.fill();
        });

        ctx.restore();
    }

/**
  *     Internal item - for data encapsulation
  *
  */
    Item
    {
        id: internal
        property var graphs: []
        anchors.fill: parent

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
        function updateRange()
        {
            if (internalStorage.count > 0)
            {
                var jsobject = internalStorage.get(0);
                range = {
                    left: jsobject.x,
                    right: jsobject.x,
                    bottom: 0,
                    top: 0
                };
            }

            for (var i = 0; i < internalStorage.count; ++i)
            {
                jsobject = internalStorage.get(i);
                range.left   = Math.min(range.left,   jsobject.x);
                range.right  = Math.max(range.right,  jsobject.x);

                for (var j = 0; j < graphs.length; ++j)
                {
                    range.bottom = Math.min(range.bottom, jsobject[graphs[j].role]);
                    range.top    = Math.max(range.top,    jsobject[graphs[j].role]);
                }
            }

            var centerY = (range.top + range.bottom) * 0.5;
            var rangeY = range.top - range.bottom;
            range.top = centerY + rangeY * 0.6
            range.bottom = centerY - rangeY * 0.6
        }

        function to_screen(x, y)
        {
            return Qt.point(width * (x - range.left) /
                                (range.right - range.left),
                            height * (1. - (y - range.bottom) /
                                (range.top   - range.bottom)));
        }

        function drawGrid(ctx)
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

            var h = range.top - range.bottom;
            for(var i in steps)
            {
                if(steps[i] * 4 > h)
                {
                    break;
                }
            }

/**
  *     Draw horizontal grid
  *
  */
            var y = 0;
            var text_size = Math.floor(15 * mainWindow.scale)
            ctx.clearRect(0, 0, width, height);
            ctx.lineWidth = 0.2 * mainWindow.scale;
            ctx.strokeStyle = "#80ffffff";
            ctx.font = text_size +  "px sans-serif"
            ctx.fillStyle = "white"

            while(y < h)
            {
                var p = to_screen(0, y);
                ctx.beginPath();
                ctx.moveTo(0, p.y);
                ctx.lineTo(width, p.y);
                ctx.stroke();
                ctx.fillText(y, 2 + mainWindow.scale, p.y + text_size);
                y += steps[i];
            }

/**
  *     Draw vertical grid
  *
  */
            var x = range.left;
            var date = new Date(x);
            date.setHours(0);
            date.setMinutes(0);
            date.setSeconds(0);

            var p_prev = to_screen(0, 0);
            var p_prev_text = to_screen(0, 0);
            while(x < range.right)
            {
                date = new Date(date.getTime() + 1000 * 60);
                x = date.getTime();
                p = to_screen(x, 0);

                if(p.x - p_prev.x > 50 * mainWindow.scale)
                {
                    ctx.beginPath();
                    ctx.moveTo(p.x, 0);
                    ctx.lineTo(p.x, height);
                    ctx.stroke();
                    p_prev = p;
                }

                if(p.x - p_prev_text.x > 100 * mainWindow.scale)
                {
                    ctx.fillText(application.formatDate(date, "dd MMM yyyy"),
                                 p.x, height - 5 * mainWindow.scale);
                    p_prev_text = p;
                }
            }
        }
    }
}
