import QtQuick 2.0
import QtGraphicalEffects 1.0

import "../utils.js" as Utils

Canvas {
    id: root
    property var streams: {"dummy": {}}
    property var range: {"left": 0, "right": 0, "bottom": 0, "top": 0}
    antialiasing: true
    smooth: true
    anchors.fill: parent

    function clear(stream, color)
    {
        streams[stream] = {color: color, points: []};
    }

    function append(stream, x, y)
    {
        streams[stream].points.push(Qt.point(x, y));
        updateRange();
        root.requestPaint();
    }

    function each_stream(func)
    {
        for (var it in streams) {
            if (streams.hasOwnProperty(it)) {
                var stream = streams[it];
                if (stream.points) {
                    func(stream);
                }
            }
        }
    }

    function updateRange()
    {
        range.left   =  1e20;
        range.right  = -1e20;
        range.bottom =  1e20;
        range.top    = -1e20;

        each_stream(function (stream) {
            for(var i = 0; i < stream.points.length; ++i) {
                var p = stream.points[i];
                range.left   = Math.min(range.left,   p.x);
                range.right  = Math.max(range.right,  p.x);
                range.bottom = Math.min(range.bottom, p.y);
                range.top    = Math.max(range.top,    p.y);
            }
        });

        var width  = range.right - range.left;
        var height = range.top   - range.bottom;

        if(width === 0) {
            width = 1;
        }

        if(height === 0) {
            height = 1;
        }

        var center_x = (range.left   + range.right) * 0.5;
        var center_y = (range.bottom + range.top) * 0.5;

        range.bottom = center_y - 3 * height / 4;
        range.top    = center_y + 3 * height / 4;
    }

    function to_screen(x, y)
    {
        return Qt.point(width  * (x - range.left)   / (range.right - range.left),
                        height * (1. - (y - range.bottom) / (range.top   - range.bottom)));
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
        for(var i in steps) {
            if(steps[i] * 4 > h) {
                break;
            }
        }

        var y = 0;
        var text_size = Math.floor(15 * mainWindow.scale)
        ctx.clearRect(0, 0, width, height);
        ctx.lineWidth = 0.2 * mainWindow.scale;
        ctx.strokeStyle = "#80ffffff";
        ctx.font = text_size +  "px sans-serif"
        ctx.fillStyle = "white"

        while(y < h) {
            var p = to_screen(0, y);
            ctx.beginPath();
            ctx.moveTo(0, p.y);
            ctx.lineTo(width, p.y);
            ctx.stroke();
            ctx.fillText(y, 2 + mainWindow.scale, p.y + text_size);
            y += steps[i];
        }

        var x = range.left;
        var date = new Date(x);
        date.setHours(0);
        date.setMinutes(0);
        date.setSeconds(0);

        var p_prev = to_screen(0, 0);
        var p_prev_text = to_screen(0, 0);
        while(x < range.right) {
            date = new Date(date.getTime() + 1000 * 60 * 60 * 24);
            x = date.getTime();
            p = to_screen(x, 0);

            if(p.x - p_prev.x > 50 * mainWindow.scale) {
                ctx.beginPath();
                ctx.moveTo(p.x, 0);
                ctx.lineTo(p.x, height);
                ctx.stroke();
                p_prev = p;
            }

            if(p.x - p_prev_text.x > 100 * mainWindow.scale) {
                ctx.fillText(application.formatDate(date, "dd MMM yyyy"), p.x, height - 5 * mainWindow.scale);
                p_prev_text = p;
            }
        }
    }

    onPaint: {
        var ctx = getContext("2d");

        ctx.save();
        drawGrid(ctx);
        each_stream(function (stream) {
            if(stream.points.length > 0) {
                ctx.lineWidth = 3 * mainWindow.scale;
                ctx.strokeStyle = stream.color;
                ctx.fillStyle = stream.color;
                ctx.globalAlpha = 0.9;
                ctx.beginPath();

                var p0 = to_screen(stream.points[0].x, stream.points[0].y);
                for (var i = 0; i < stream.points.length; ++i) {
                    var p = to_screen(stream.points[i].x, stream.points[i].y);
                    if (i == 0) {
                        ctx.moveTo(p.x, p.y)
                    } else {
                        ctx.lineTo(p.x, p.y)
                    }
                }
                ctx.stroke();

                ctx.globalAlpha = 0.15;
                ctx.lineTo(p.x,  height);
                ctx.lineTo(p0.x, height);
                ctx.fill();
            }

            var size = 8 * mainWindow.scale;
            ctx.beginPath();
            for (i = 0; i < stream.points.length; ++i) {
                p = to_screen(stream.points[i].x, stream.points[i].y);
                ctx.ellipse(p.x - size / 2, p.y - size / 2, size, size)
            }
            ctx.globalAlpha = 0.9;
            ctx.fill();
        });
        ctx.restore();
    }
}
