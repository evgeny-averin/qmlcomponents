import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import "../common/utils.js" as Utils

Item {
    id: root

    property string placeholderText
    property string text
    property int    fontPixelSize: 25 * mainWindow.scale

    signal accepted();
    signal textAboutTobeChanged();

    function releaseFocus()
    {
        textField.text = "";
        textField.focus = false;
    }

    function clear()
    {
        textField.text = "";
    }

    function accept()
    {
        textField.accepted();
    }

    onTextChanged: {
        textField.text = text;
    }

    TextField {
        id: textField

        anchors.fill: parent

        style: touchStyle

        onAccepted: {
            root.accepted();
        }

        onTextChanged: {
            root.textAboutTobeChanged();
            root.text = text;
        }

        Component {
            id: touchStyle

            TextFieldStyle {
                textColor: "white"
                font.pixelSize: root.fontPixelSize

                background: Item {
                    implicitHeight: 50
                    implicitWidth: 320
                    BorderImage {
                        source: "../images/textinput.png"
                        border.left: 8
                        border.right: 8
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }
                }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 15 * mainWindow.scale
            }

            font.pixelSize: root.fontPixelSize
            text: root.placeholderText
            color: "#bbbbbb"
            visible: !parent.focus
        }
    }

    MouseArea
    {
        anchors
        {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: height

        onClicked:
        {
            textField.text = "";
        }

        Text
        {
            anchors.centerIn: parent
            text: "X"
        }
    }
}
