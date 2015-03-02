import QtQuick 2.0

import "../common/utils.js" as Utils

Item {
    id: root

    property alias image: image.source
    property alias text:  txtTitle.text
    property alias font:  txtTitle.font
    property alias color: txtTitle.color
    property int   horizontalAlignment: Text.AlignVCenter
    property int   touchMargins: root.width * 0.1
    property Component  background: null

    signal pressed();
    signal released();
    signal clicked();

    width:  txtTitle.width  + 10 * mainWindow.scale
    height: txtTitle.height * 1.8

    antialiasing: true
    color: mouseArea.pressed ? "#222" : "transparent"

    Behavior on opacity { NumberAnimation{} }

    Component.onCompleted: {
        switch (root.horizontalAlignment) {
            case Text.AlignVCenter: {
                txtTitle.anchors.centerIn = root;
                break;
            }
            case Text.AlignLeft: {
                txtTitle.anchors.left = root.left;
                txtTitle.anchors.verticalCenter = root.verticalCenter;
                break;
            }
            case Text.AlignRight: {
                txtTitle.anchors.right = root.right;
                txtTitle.anchors.verticalCenter = root.verticalCenter;
                break;
            }
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.background
    }

    Image {
        id: image
        anchors.fill: parent
        scale: root.background ? 0.7 : 1
    }

    MouseArea {
        id: mouseArea

        anchors {
            fill: parent
            margins: -touchMargins
        }

        onPressed: {
            root.pressed();
        }

        onReleased: {
            root.released();
        }

        onClicked: {
            root.clicked();
        }
    }

    Text {
        id: txtTitle
    }
}
