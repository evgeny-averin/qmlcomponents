import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1


Item {
    id: root
    property alias items: itemList.model
    property string title
    property int currentIndex: -1
    property var editors: []
    visible: opacity > 0

    height: inputFields.height

    signal accepted();
    signal rejected();

    function show()
    {
        editors.forEach(function (editor) {
            editor.reset();
        });

        currentIndex = 0;
        Qt.inputMethod.show();
        state = "visible"
    }

    function hide()
    {
        currentIndex = -1;
        Qt.inputMethod.hide();
        state = "hidden"
    }

    onCurrentIndexChanged: {
        if (currentIndex >= 0 && currentIndex < editors.length) {
            editors[currentIndex].forceActiveFocus();
        }
    }

    onAccepted: {
        hide();
    }
    onRejected: {
        hide();
    }

    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        anchors.fill: inputFields
        color: "#e0707070"
        border.color: toolbar.border.color
    }

    Column {
        id: inputFields
        spacing: 10 * mainWindow.scale
        anchors.fill: parent

        Rectangle {
            width: root.width
            height: 50 * mainWindow.scale
            color: "#e0606060"
            border.color: toolbar.border.color

            Row {
                id: headerItems
                anchors.centerIn: parent
                spacing: 5 * mainWindow.scale
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 35 * mainWindow.scale
                    width: height
                    source: "qrc:/images/arrow_down.png"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 50 * application.scale
                    color: "white"
                    text: root.title
                }
            }
        }

        Repeater {
            id: itemList
            delegate: Column {
                width:  childrenRect.width
                height: childrenRect.height
                Text {
                    x: 15 * mainWindow.scale
                    font.pixelSize: 25 * mainWindow.scale
                    text: modelData.title
                    color: "white"
                }
                Item {
                    height: 10 * mainWindow.scale
                    width: 1
                }

                TextInput {
                    focus: true
                    x: 15 * mainWindow.scale
                    font.pixelSize: 23 * mainWindow.scale
                    width: root.width - 35 * mainWindow.scale
                    height: font.pixelSize * 1.5
                    color: "lightgrey"

                    Component.onCompleted: {
                        root.editors[index] = this;
                    }

                    onAccepted: {
                        if (index == root.editors.length - 1) {
                            root.accepted();
                        } else {
                            ++root.currentIndex;
                        }
                    }

                    function reset()
                    {
                        if (cmbVariants.count > 0) {
                            text = cmbVariants.currentText
                        } else {
                            text = "";
                        }
                    }

                    ComboBox {
                        id: cmbVariants

                        anchors.fill: parent
                        visible: modelData.variants !== undefined
                        model: modelData.variants

                        onCurrentTextChanged: {
                            parent.text = currentText;
                        }
                        style: ComboBoxStyle {
                            background: Rectangle {
                                color: "#808080"
                                border.color: "#a0a0a0"

                                Image {
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                        right: parent.right
                                        rightMargin: height / 4
                                    }

                                    height: parent.height * 0.65
                                    width: height
                                    source: "qrc:/images/arrow_down.png"
                                }
                            }
                            label: Text {
                                color: "lightgrey"
                                font.pixelSize: 23 * mainWindow.scale
                                text: control.currentText
                            }
                        }
                    }
                }
                Item {
                    height: 10 * mainWindow.scale
                    width: 1
                }
                Item {
                    visible: index < root.items.length - 1
                    width: inputFields.width
                    height: 2
                    Rectangle {
                        y: 1
                        width: parent.width
                        height: mainWindow.scale
                        color: "#30ffffff"
                    }
                    Rectangle {
                        width: parent.width
                        height: mainWindow.scale
                        color: "#343434"
                    }
                }
            }
        }
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20 * mainWindow.scale
        }

        spacing: root.width * 0.05

        PushButton {
            width: root.width * 0.4
            height: 50 * mainWindow.scale
            text: qsTr("OK")
            font.pixelSize: 25 * mainWindow.scale
            background: Rectangle {
                color: "white"
                border.color: "#343434"
                opacity: 0.8
            }
            onClicked: {
                root.accepted();
            }
        }

        PushButton {
            width: root.width * 0.4
            height: 50 * mainWindow.scale
            text: qsTr("Отмена")
            font.pixelSize: 25 * mainWindow.scale
            background: Rectangle {
                color: "white"
                border.color: "#343434"
                opacity: 0.8
            }
            onClicked: {
                root.rejected();
            }
        }
    }

    states: [
        State {
            name: "visible"
            PropertyChanges {
                target: root
                scale: 1
                opacity: 1
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: root
                scale: 0.5
                opacity: 0
            }
        }
    ]

    transitions: [
        Transition {
            to: "visible"
            NumberAnimation { properties: "scale";   duration: 450; easing.type: Easing.OutBack }
            NumberAnimation { properties: "opacity"; duration: 300 }
        },
        Transition {
            to: "hidden"
            NumberAnimation { properties: "scale";   duration: 450; easing.type: Easing.InBack }
            NumberAnimation { properties: "opacity"; duration: 400 }
        }
    ]
}
