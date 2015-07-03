import QtQuick 2.3
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.2
import QtQuick.Layouts 1.1

import "../common"
import "qrc:/../../qmlcomponents/common"

Item
{
    id: suggestionsBox

    property var suggestions: []
    property var suggestionsTmp: []
    property alias count: suggestionModel.count
    property bool animationEnabled: false
    property alias clearing: clearTimer.running
    property color textColor: "#676767"

    signal selected(var index)
    signal deselected(var index)
    signal cleared()

    width: 100
    height: 62
    clip: true

    function clear()
    {
        animationEnabled = true;
        listView.contentY = -listView.topMargin;
        clearTimer.start();
        cleared();
    }

    function suggestion(index)
    {
        if (index < suggestionModel.count)
        {
            return suggestionModel.get(index);
        }
        return {};
    }

    Timer
    {
        id: populateTimer
        repeat: true
        interval: 50

        onTriggered:
        {
            if (suggestionsTmp.length == 0)
            {
                stop();
            }
            else
            {
                suggestionModel.append(suggestionsTmp[0]);
                suggestionsTmp.splice(0, 1);
            }
        }
    }

    Timer
    {
        id: clearTimer
        repeat: true
        interval: 50

        onTriggered:
        {
            if (suggestionModel.count == 0)
            {
                stop();
            }
            else
            {
                suggestionModel.remove(suggestionModel.count - 1);
            }
        }
    }

    onSuggestionsChanged:
    {
        suggestionsTmp = [].concat(suggestions);

        if (suggestionsTmp.length > 0)
        {
            if (suggestionModel.count == 0)
            {
                suggestionModel.clear();
                animationEnabled = true;
                populateTimer.start();
            }
            else
            {
                animationEnabled = false;
                suggestionModel.clear();
                for (var i in suggestionsTmp)
                {
                    suggestionModel.append(suggestionsTmp[i]);
                }
            }
        }
    }

    ListModel
    {
        id: suggestionModel
    }

    Rectangle
    {
        anchors.fill: parent
        opacity: suggestionModel.count > 0 ? 0.56 : 0
        color: "black"
        Behavior on opacity { NumberAnimation {duration: 300} }
    }

    Component
    {
        id: suggestionComponent
        Item
        {
            id: delegateRoot

            width: suggestionsBox.width
            height: 80 * mainWindow.scale
            z: index

            Rectangle
            {
                id: rect

                border.color: "gray"
                width:  parent.width - 20 * mainWindow.scale
                height: parent.height
                anchors.centerIn: parent
                clip: true

                RowLayout
                {
                    id: layout

                    spacing: 0
                    anchors.fill: parent
                    anchors.margins: 10 * mainWindow.scale

                    Column // Symbol name
                    {
                        Layout.preferredWidth: (layout.width - checkBox.width * 2) / 2
                        Layout.maximumWidth:   (layout.width - checkBox.width * 2) / 2
                        Text { text: symbolName; font.pixelSize: 28 * mainWindow.scale; font.bold: true; color: textColor; width: parent.width; elide: Text.ElideRight }
                        Text { text: symbolDescription; font.pixelSize: 18 * mainWindow.scale; color: Qt.lighter(textColor); width: parent.width; elide: Text.ElideRight }
                    }

                    Column // Stock name
                    {
                        Layout.preferredWidth: (layout.width - checkBox.width * 2) / 2
                        Layout.maximumWidth:   (layout.width - checkBox.width * 2) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: stockName;  font.pixelSize: 25 * mainWindow.scale; color: textColor; width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight }
                        Text { text: symbolType; font.pixelSize: 18 * mainWindow.scale; color: Qt.lighter(textColor); width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight }
                    }

                    CheckBox
                    {
                        id: checkBox
                        checked: dashBoard.hasSymbol(suggestionModel.get(index))
                    }
                }

                Rectangle
                {
                    height: parent.height
                    width:  5 * mainWindow.scale
                    anchors.right: parent.right
                    color: "#a03434"
                    visible: checkBox.checked
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked:
                    {
                        checkBox.checked = !checkBox.checked

                        if (checkBox.checked)
                        {
                            suggestionBox.selected(index);
                        }
                        else
                        {
                            suggestionBox.deselected(index);
                        }

                        tapAnimation.tap();
                    }
                }

                TapAnimation {id: tapAnimation; duration: 600; color: "gray"; tapEffectWidth: parent.width / 2}
            }

            PushButton
            {
                visible: index == listView.count - 1
                anchors.right: parent.right
                anchors.top:   parent.bottom
                text: "CLEAR"
                color: "white"
                font.pixelSize: 23 * mainWindow.scale
                onClicked:
                {
                    suggestionBox.clear();
                }
            }

            ListView.onRemove: SequentialAnimation
            {
                PropertyAction { target: delegateRoot; property: "ListView.delayRemove"; value: suggestionBox.animationEnabled }
                ParallelAnimation
                {
                    NumberAnimation { target: delegateRoot; properties: "x"; to: -suggestionBox.width / 2; duration: 400; easing.type: Easing.InBack}
                    NumberAnimation { target: delegateRoot; properties: "opacity"; to: 0; duration: 400; easing.type: Easing.InQuad }
                }
                PropertyAction { target: delegateRoot; property: "ListView.delayRemove"; value: false }
            }
        }
    }

    ListView
    {
        id: listView

        anchors.fill: parent
        bottomMargin: 2 * height / 3
        topMargin: spacing

        Behavior on contentY { NumberAnimation {duration: 500; easing.type: Easing.InOutQuad} }

        spacing: 10 * mainWindow.scale
        model: suggestionModel
        delegate: suggestionComponent

        add: Transition
        {
            enabled: suggestionBox.animationEnabled
            ParallelAnimation
            {
                NumberAnimation { properties: "y"; from: 0; duration: 600; easing.type: Easing.OutBack }
                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 500 }
            }
        }
    }
}

