import QtQuick 2.0

Rectangle
{
    id: tapAnimation

    property int tapEffectWidth: parent.width
    property int duration: 400

    width:  tapEffectWidth
    height: tapEffectWidth

    signal tap()

    radius: width / 2
    color: "white"
    opacity: 0
    anchors.centerIn: parent

    onTap: ParallelAnimation
    {
        NumberAnimation
        {
            target: tapAnimation
            properties: "scale"; from: 0.2; to: 2
            duration: tapAnimation.duration
            easing.type: Easing.OutQuad
        }

        NumberAnimation
        {
            target: tapAnimation
            property: "opacity"; from: 0.2; to: 0
            duration: tapAnimation.duration
            easing.type: Easing.OutQuad
        }
    }
}

