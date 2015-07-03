import QtQuick 2.0

import "../../qmlcomponents/common"
import "../common/utils.js" as Utils
import "qrc:/../../qmlcomponents/common"

Item {
    id: pushButton

    property alias image: image
    property alias text:  txtTitle.text
    property alias font:  txtTitle.font
    property alias color: txtTitle.color
    property int   horizontalAlignment: Text.AlignVCenter
    property int   touchMargins: pushButton.width * 0.1
    property Component  background: null

    signal pressed();
    signal released();
    signal clicked();

    width:   txtTitle.width  + 10 * mainWindow.scale
    height:  txtTitle.height * 1.8
    enabled: opacity > 0

    antialiasing: true
    color: mouseArea.pressed ? "#222" : "transparent"

    Behavior on opacity { NumberAnimation {duration: 150; easing.type: Easing.InOutQuad} }

    Component.onCompleted: {
        switch (pushButton.horizontalAlignment) {
            case Text.AlignVCenter: {
                txtTitle.anchors.centerIn = pushButton;
                break;
            }
            case Text.AlignLeft: {
                txtTitle.anchors.left = pushButton.left;
                txtTitle.anchors.verticalCenter = pushButton.verticalCenter;
                break;
            }
            case Text.AlignRight: {
                txtTitle.anchors.right = pushButton.right;
                txtTitle.anchors.verticalCenter = pushButton.verticalCenter;
                break;
            }
        }
    }

    TapAnimation
    {
        id: tapAnimation
        anchors.centerIn: parent
        tapEffectWidth:   parent.width
    }

    onClicked: tapAnimation.tap()

    Loader {
        anchors.fill: parent
        sourceComponent: pushButton.background
    }

    Image {
        id: image
        anchors.fill: parent
        scale: pushButton.background ? 0.7 : 1
    }

    MouseArea {
        id: mouseArea

        anchors {
            fill: parent
            margins: -touchMargins
        }

        onPressed: {
            pushButton.pressed();
        }

        onReleased: {
            pushButton.released();
        }

        onClicked: {
            pushButton.clicked();
        }
    }

    Text {
        id: txtTitle
    }
}
