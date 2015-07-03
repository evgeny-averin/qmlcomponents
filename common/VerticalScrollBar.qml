import QtQuick 2.0

Rectangle
{
    id: verticalScrollbar

    property int margin: 5 * mainWindow.scale
    property int baseHeight: parent.height - 2 * margin

    anchors.right: parent.right
    anchors.rightMargin: 2 * mainWindow.scale

    y:      baseHeight * parent.visibleArea.yPosition + margin
    height: baseHeight * parent.visibleArea.heightRatio
    width:  8 * mainWindow.scale

    radius: width / 2
    color:  "#232323"
    opacity: 0

    states:
    [
        State
        {
            name: "movingState"

            when: verticalScrollbar.parent.moving
            PropertyChanges
            {
                target:  verticalScrollbar
                opacity: 0.3
            }
        }
    ]

    transitions:
    [
        Transition
        {
            to: "movingState"
            NumberAnimation {properties: "opacity"; duration: 300}
        },
        Transition
        {
            from: "movingState"
            SequentialAnimation
            {
                NumberAnimation {duration: 1500}
                NumberAnimation {properties: "opacity"; duration: 1500}
            }
        }
    ]
}

