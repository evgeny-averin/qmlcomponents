import QtQuick 2.0
import QtGraphicalEffects 1.0

Item
{
    id: touchMenuItem

    property bool twoSided: false
    property alias flipped: flipable.flipped
    readonly property bool isTouchMenuItem: true
    property int margins: 0

    property alias frontColor: frontItem.color
    property alias color:      frontItem.color
    property alias backColor:  backItem.color

    property alias frontText:  frontText.text
    property alias text:       frontText.text
    property alias frontImage: frontImage
    property alias image:      frontImage
    property alias backText:   backText.text
    property alias backImage:  backImage

    width: 90 * mainWindow.scale
    height: width
    opacity: 1

    // API signals
    signal clicked()

    // API functions
    function flipToFront()
    {
        flipable.flipped = false;
    }

    function flipToBack()
    {
        flipable.flipped = true;
    }

    Behavior on scale
    {
        NumberAnimation
        {
            duration: 300;
            easing.type: parent.expanded ? Easing.OutBack : Easing.InBack
        }
    }
    Behavior on opacity
    {
        NumberAnimation { duration: parent.expanded ? 100 : 300 }
    }

    DropShadow
    {
        anchors.fill: parent
        anchors.margins: width * 0.1
        source:       flipable
        radius:       Math.min(20.0 * mainWindow.scale, 0.1 * flipable.width)
        samples:      24
        color:        "#40000000"
        smooth:       true
        horizontalOffset: width * 0.005
        verticalOffset:   width * 0.02
    }

    Item
    {
        id: flipable

        property bool flipped: false
        anchors.fill: parent
        anchors.margins: margins
        visible: false

        Rectangle
        {
            id: frontItem

            width:   flipable.width  * 0.8
            height:  flipable.height * 0.8
            anchors.centerIn: parent
            radius:  width / 2
            color:   "lightgray"

            Text
            {
                id: frontText

                anchors.centerIn:    parent
                font.pixelSize:      frontItem.height / 4
                verticalAlignment:   Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
            }

            Image
            {
                id: frontImage
                anchors.fill: parent
                scale: 0.67
            }

        }

        Rectangle
        {
            id: backItem

            width:   flipable.width  * 0.8
            height:  flipable.height * 0.8
            anchors.centerIn: parent
            radius: width / 2
            scale: 0

            Text
            {
                id: backText

                anchors.centerIn: parent
                font.pixelSize: backItem.height / 4
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "white"
            }

            Image
            {
                id: backImage
                anchors.fill: parent
                scale: 0.67
            }
        }

        states:
        [
            State
            {
                name: "frontState"
                PropertyChanges { target: frontItem; opacity: 1; scale: 1 }
                PropertyChanges { target: backItem;  opacity: 0; scale: 0 }
                when: !flipable.flipped
            },

            State
            {
                name: "backState"
                PropertyChanges { target: frontItem; opacity: 0; scale: 0 }
                PropertyChanges { target: backItem;  opacity: 1; scale: 1 }
                when: flipable.flipped
            }
        ]

        transitions: Transition
        {
            NumberAnimation { property: "opacity"; duration: 200 }
            NumberAnimation { property: "scale";   duration: 200 }
        }
    }

    MouseArea
    {
        anchors.fill: parent
        onClicked:
        {
            if (twoSided)
            {
                flipable.flipped = !flipable.flipped;
            }

            touchMenuItem.clicked()
        }
    }
}

