import QtQuick 2.3

Item
{
    id: dynamicLayout

    property int columnSpacing: 0
    property int rowSpacing: 0
    property bool uniform: false
    property int maxColumns: 1

    height: childrenRect.height

    Component.onCompleted:
    {
        for (var i in children)
        {
            children[i].widthChanged.connect(
                dynamicLayout.doLayout);

            children[i].heightChanged.connect(
                dynamicLayout.doLayout);
        }

        doLayout();
    }

    onWidthChanged:
    {
        doLayout();
    }

    function doLayout()
    {
        var x = 0;
        var y = 0;
        var cellHeight = 0;

        if (uniform)
        {
            var line = [];
            var layoutLine = function(line, y)
            {
                var lineWidth = 0;
                for (var i in line)
                {
                    lineWidth += line[i].width;
                }

                var spacing = (width - lineWidth) / (line.length - 1);
                var x = 0;
                for (i in line)
                {
                    line[i].x = x;
                    line[i].y = y;
                    x += line[i].width + spacing;
                }
            };

            for (var i in children)
            {
                var child = children[i];
                if (x + child.width > width ||
                    line.length >= maxColumns)
                {
                    if (line.length == 0)
                    {
                        cellHeight = child.height;
                        layoutLine([child], y);
                    }
                    else
                    {
                        layoutLine(line, y);
                        line = [child];
                    }

                    x = 0;
                    y += cellHeight + rowSpacing;
                    cellHeight = child.height;
                }
                else
                {
                    cellHeight = Math.max(cellHeight, child.height);
                    line.push(child);
                }
                x += child.width + columnSpacing;
            }

            layoutLine(line, y);
        }
        else
        {
            for (i in children)
            {
                child = children[i];

                if (x + child.width > width)
                {
                    x = 0;
                    y += cellHeight + rowSpacing;
                    cellHeight = 0;
                }
                else
                {
                    cellHeight = Math.max(cellHeight, child.height);
                }

                child.x = x;
                child.y = y;

                x += child.width + columnSpacing;
            }
        }
    }
}

