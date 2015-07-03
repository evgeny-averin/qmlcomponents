import QtQuick 2.3
import QtGraphicalEffects 1.0

import "../../qmlcomponents/common"
import "qrc:/../../qmlcomponents/common"

Item
{
    id: tabViewTouch

    property var tabs: []
    property alias currentIndex: tabList.currentIndex
    property alias color: tabBar.color
    property alias backgroundColor: background.color
    property int tabWidth:  width / tabs.length
    property int tabHeight: 40 * mainWindow.scale

    property alias textColor: textSettings.color
    property alias font:      textSettings.font

    Rectangle
    {
        id: background

        anchors.fill: tabBar
        color: "red"
    }

    Text
    {
        id: textSettings
        color: "#565656"
    }

    ListView
    {
        id: tabBar

        property color color: "#ff8989"

        height: tabHeight
        width:  tabViewTouch.width

        orientation: ListView.Horizontal
        model: tabViewTouch.tabs

        highlightMoveDuration: 400
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: (width - tabViewTouch.tabWidth) / 2
        preferredHighlightEnd:   (width - tabViewTouch.tabWidth) / 2

        highlight: Item { Rectangle
        {
            height: 5 * mainWindow.scale
            width:  parent.width
            anchors.bottom: parent.bottom
            color:  tabBar.color
        }}

        delegate: Item
        {
            height: tabBar.height
            width:  tabWidth
            clip:   true

            TapAnimation
            {
                id: tapAnimation
                anchors.centerIn: parent
                tapEffectWidth:   parent.width * 0.67
            }

            Text
            {
                anchors.centerIn: parent
                text:  modelData.title
                font:  textSettings.font
                color: index === tabBar.currentIndex ? tabBar.color : textSettings.color

                Behavior on color {ColorAnimation {duration: 300}}
            }

            MouseArea
            {
                id: mouseArea
                anchors.fill: parent
                onClicked:
                {
                    tapAnimation.tap()
                    tabList.currentIndex = index;
                }
            }
        }
        Shadow {}
    } // ListView {id: tabBar}


    ListView
    {
        id: tabList

        model: tabViewTouch.tabs
        z: -1

        anchors.fill: parent
        anchors.topMargin: tabHeight

        displayMarginBeginning: 1000000
        displayMarginEnd: 1000000
        orientation: ListView.Horizontal

        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 400

        flickDeceleration: 20000
        maximumFlickVelocity: 5000

        delegate: Loader
        {
            width:  tabList.width
            height: tabList.height
            sourceComponent: modelData.component

            onLoaded:
            {
                item.setData(index, tabList, modelData);
            }
        }

        onCurrentIndexChanged:
        {
            tabBar.currentIndex = currentIndex
        }
    } // ListView {id: tabList}
}

