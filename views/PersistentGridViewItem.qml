import QtQuick 2.2
import QtQuick.Controls 1.1

Rectangle
{
    id: persistentListViewItem

    border.color: "gray"

    property alias interactive: mouseArea.enabled

/**
  *     Signals for external usage
  *
  */
    signal deleted();
    signal clicked();
    signal pressAndHold();
    signal dragStarted();
    signal dragFinished();

/**
  *     MouseArea used for processing
  *     drag and press events
  *
  */
    MouseArea
    {
        id: mouseArea

        anchors.fill: parent
        onClicked:
        {
            persistentListViewItem.clicked();
        }

        onPressAndHold:
        {
            persistentListViewItem.pressAndHold();
        }

        property int xSaved
        drag
        {
            target: persistentListViewItem
            axis: Drag.XAxis
            maximumX: 0
            threshold: 30 * mainWindow.scale

            onActiveChanged:
            {
                if(drag.active)
                {
                    persistentListViewItem.dragStarted();
                    xSaved = persistentListViewItem.x;
                }
                else if(xSaved - persistentListViewItem.x < 100 * mainWindow.scale)
                {
                    persistentListViewItem.x = xSaved;
                    persistentListViewItem.dragFinished();
                }
                else
                {
                    persistentListViewItem.dragFinished();
                    persistentListViewItem.state = "aboutTobeDestroyed";
                }
            }
        }
    }

/**
  *     States for animation when
  *     created, destroyed and etc.
  *
  */
    states: [
        State
        {
            name: "aboutTobeDestroyed"
        },

        State
        {
            name: "createWithAnimation"
        }
    ]

    transitions: [
        Transition
        {
            to: "aboutTobeDestroyed"
            SequentialAnimation
            {
                NumberAnimation { target: persistentListViewItem; properties: "x";
                    to: -persistentListViewItem.width; duration: 300 }
                NumberAnimation { target: persistentListViewItem; properties: "height";
                    to: 0; duration: 300; easing.type: Easing.OutQuint }
            }

            onRunningChanged:
            {
                if(!running)
                {
                    persistentListViewItem.deleted();
                }
            }
        },

        Transition
        {
            to: "createWithAnimation"

            ParallelAnimation
            {
                NumberAnimation { target: persistentListViewItem; property: "height";
                    from: 0; to: 70 * mainWindow.scale; duration: 300 }
                NumberAnimation { target: persistentListViewItem; property: "opacity";
                    to: 1.;  duration: 300 }
                NumberAnimation { target: persistentListViewItem; property: "x";
                    to: 0;   duration: 300 }
            }
        }
    ]
}
