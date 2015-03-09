import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import QtSensors 5.0
import "../storage"

ListView
{
    id: persistentListView

/**
  *     API properties
  *
  */
    property var roles: []
    property alias database: storage.database
    property alias table: storage.table

/**
  *     API signals
  *
  */
    signal loadingFinished();

/**
  *     API functions
  *
  */
    function append(jsobject)
    {
        persistence.append(jsobject);
    }

    function insert(jsobject, index)
    {
        persistence.insert(jsobject, index);
    }

    function remove(index)
    {
        persistence.remove(index);
    }

    function get(index)
    {
        return persistence.get(index);
    }

    function set(jsobject, index)
    {
        persistence.set(jsobject, index);
    }

    function clear()
    {
        persistence.clear();
    }

/**
  *     Internal structure - place all private data here.
  *
  */

    Persistence
    {
        id: persistence
        storage: SqlTableModel
        {
            id: storage
            onLoadingFinished:
            {
                persistentListView.loadingFinished();
            }
        }
    }

    model: storage.internalModel

/**
  *     Delegate item - a container for user representation.
  *     It supports vertical drag-and-drop and deletion of items
  *     with right-to-left swipe.
  *
  */
    delegate: Item
    {
        id: delegateRoot

        property int visualIndex: index

        width: persistentListView.width
        height: persistentListViewItem.height
        clip: true

        PersistentListViewItem
        {
            id: persistentListViewItem

            height: 60 * mainWindow.scale
            width: persistentListView.width

            anchors
            {
                verticalCenter: parent.verticalCenter
            }

            onDeleted:
            {
                storage.remove(index, 1);
            }

            Text
            {
                anchors.centerIn: parent
                text: role1
            }

            Drag.active: dragArea.drag.active
            Drag.source: delegateRoot
            Drag.hotSpot.x: 36
            Drag.hotSpot.y: 36

            states: [
                State
                {
                    name: "dragging"
                    when: persistentListViewItem.Drag.active
                    ParentChange
                    {
                        target: persistentListViewItem
                        parent: persistentListView
                    }

                    AnchorChanges
                    {
                        target: persistentListViewItem;
                        anchors.horizontalCenter: undefined;
                        anchors.verticalCenter: undefined
                    }
                }
            ]
        }

/**
  *     These items are used for drag-and-drop implementation.
  *     MouseArea implements drag and DropArea implements drop.
  *
  */
        MouseArea
        {
            id: dragArea
            anchors
            {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 0
            }

            height: parent.height
            width: height
            drag.target: persistentListViewItem
            drag.axis: Drag.YAxis

            Rectangle
            {
                anchors.centerIn: parent
                width: 20 * mainWindow.scale
                height: width
                color: "gray"
                opacity: 1
                radius: height / 2
            }
        }

        DropArea
        {
            anchors { fill: parent; margins: 15 }
            onEntered:
            {
                storage.move(drag.source.visualIndex, delegateRoot.visualIndex, 1);
            }
        }
    }


/**
  *     States
  *
  */
}
