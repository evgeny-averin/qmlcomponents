import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import "../utils.js" as Utils


Item {
    id: root

    property alias text:  text.text
    property alias color: text.color
    property alias font:  text.font
    property int maximumWidth

    width:  Math.min(text.width, maximumWidth)
    height: text.height

    Text {
        id: text
    }

    Rectangle {
        width: parent.height
        height: parent.width

        x: (height - width) / 2
        y: (width - height) / 2

        visible: text.width > root.maximumWidth

        gradient: Gradient {
            GradientStop { color: "transparent"; position: 0.7 }
            GradientStop { color: "black"; position: 1 }
        }

        rotation: -90
    }
}
