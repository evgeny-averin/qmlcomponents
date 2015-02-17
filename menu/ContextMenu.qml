import QtQuick 2.0

Item {
    id: root
    property alias items: itemList.model
    width:  childrenRect.width
    height: childrenRect.height
    visible: opacity > 0

    signal clicked(var index);

    Behavior on scale   { NumberAnimation { duration: 650; easing.type: Easing.InOutBack } }
    Behavior on opacity { NumberAnimation { duration: 300 } }

    function show()
    {
        state = "visible";
    }

    function hide()
    {
        state = "hidden";
    }

    function toggle()
    {
        if (visible) {
            hide();
        } else {
            show();
        }
    }

    Rectangle {
        anchors.fill: contextMenu
        color: "#e0707070"
        border.color: toolbar.border.color
    }

    Column {
        id: contextMenu

        Rectangle {
            width: headerItems.width + 25 * mainWindow.scale
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
                    text: qsTr("Выберите действие")
                }
            }
        }

        Repeater {
            id: itemList
            delegate: Item {
                width:  childrenRect.width
                height: button.height
                PushButton {
                    id: button
                    anchors.verticalCenter: parent.verticalCenter
                    x: 15 * application.scale
                    width: contextMenu.width - x
                    text: modelData
                    font.pixelSize: 45 * application.scale
                    color: "white"
                    horizontalAlignment: Text.AlignLeft
                    touchMargins: 0
                    onClicked: {
                        root.clicked(index);
                    }
                }
                Item {
                    visible: index < root.items.length - 1
                    y: parent.height + contextMenu.spacing
                    width: contextMenu.width
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
