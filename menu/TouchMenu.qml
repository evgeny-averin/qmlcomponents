import QtQuick 2.3

TouchMenuItem
{
    id: touchMenu

    property bool expanded: false
    property int  spacing: 15 * mainWindow.scale
    property bool autoHide: false

    property var items: []

    function flipToFront()
    {
        flipped = false;
        expanded = false;
    }

    function flipToBack()
    {
        flipped = true;
        expanded = true;
    }

    Component.onCompleted:
    {
        for (var i in children)
        {
            var child = children[i];
            if (child.isTouchMenuItem)
            {
                child.width =  Qt.binding(function () {return touchMenu.width * 0.85});
                child.height = Qt.binding(function () {return touchMenu.height * 0.85});
                child.x = x;
                child.anchors.verticalCenter = touchMenu.verticalCenter;
                child.z = -1;
                child.scale = 0;
                child.opacity = 0;
                child.margins = Qt.binding(function () {return touchMenu.margins});
                child.clicked.connect(function ()
                {
                    if (touchMenu.autoHide)
                    {
                        touchMenu.expanded = false;
                    }
                })
                items.push(child);
            }
        }
    }

    onWidthChanged:
    {
        placeItems();
    }

    onSpacingChanged:
    {
        placeItems();
    }

    onExpandedChanged:
    {
        expandTimer.run();
    }

    Timer
    {
        id: expandTimer
        property int i: 0;
        repeat: true
        interval: 120
        triggeredOnStart: true

        function run()
        {
            if (expanded)
            {
                i = 0;
            }
            else
            {
                i = items.length - 1;
            }

            running = true;
        }

        onTriggered:
        {
            if (i < touchMenu.items.length)
            {
                touchMenu.items[i].scale = expanded ? 1. : 0;
                touchMenu.items[i].opacity = expanded ? 1. : 0;
            }

            if (expanded)
            {
                ++i;
                if (i >= touchMenu.items.length)
                {
                    stop();
                }
            }
            else
            {
                --i;
                if (i < 0)
                {
                    stop();
                }
            }
        }
    }

    onClicked:
    {
        if (touchMenu.items.length > 0)
        {
            touchMenu.expanded = !touchMenu.expanded
        }
    }

    function placeItems()
    {
        if (!items)
        {
            return;
        }

        for (var i = 0; i < items.length; ++i)
        {
            items[i].x = -(i + 1) * (width + spacing);
        }
    }
}

