import QtQuick 2.0

QtObject {
    id: range

    readonly property double left:   centerX - width / 2
    readonly property double right:  centerX + width / 2
    readonly property double bottom: centerY - height / 2
    readonly property double top:    centerY + height / 2

    property double width: 0
    property double height: 0

    property double centerX: targetX
    property double centerY: 0

    property double targetX: 0

    property int duration: 100

    Behavior on centerX
    {
        id: animation
        NumberAnimation
        {
            duration: range.duration
            easing.type: Easing.OutQuad
        }
    }

    function init(x, y, w, h)
    {
        animation.enabled = false;
        targetX = x;
        centerY = y;
        width = w;
        height = h;
        animation.enabled = true;
    }

    function normalizeX(x)
    {
        return (x - left) / width;
    }

    function normalizeY(y)
    {
        return (y - bottom) / height;
    }

    function normalize(x, y)
    {
        return Qt.point((x - left) / width,
                        (y - bottom) / height);
    }

    function move(dx)
    {
        range.duration = 100;
        targetX += dx;
    }

    function moveTo(x)
    {
        animation.enabled = false;
        targetX = x;
        animation.enabled = true;
    }

    function moveInertial(dx)
    {
        range.duration = 800;
        targetX += dx;
    }

    function stopMoving()
    {
        animation.enabled = false;
        targetX = centerX;
        animation.enabled = true;
    }

    function to_s()
    {
        return "left: " + range.left + " right: " + range.right +
               " top: " +  range.top + " bottom: " + range.bottom;
    }

    function isValid()
    {
        return (width > 0) && (height > 0) &&
                !isNaN(width) && !isNaN(height) &&
                isFinite(width) && isFinite(height)
    }
}

