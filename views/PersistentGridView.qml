import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import QtSensors 5.0
import "../storage"

GridView
{
    id: persistentGridView

/**
  *     API properties
  *
  */
    property var roles: []
    property alias database: storage.database
    property alias table: storage.table
    property int columnCount: 1
    cellWidth: width / columnCount
    cellHeight: cellWidth

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
                persistentGridView.loadingFinished();
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

        width: persistentGridView.cellWidth
        height: persistentGridView.cellHeight
        clip: true

        PersistentGridViewItem
        {
            id: persistentGridViewItem

            height: delegateRoot.width
            width: delegateRoot.height

            anchors
            {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
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
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            states: [
                State
                {
                    name: "dragging"
                    when: persistentGridViewItem.Drag.active
                    ParentChange
                    {
                        target: persistentGridViewItem
                        parent: persistentGridView
                    }

                    AnchorChanges
                    {
                        target: persistentGridViewItem;
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
                top: parent.top
                rightMargin: 0
            }

            height: 60 * mainWindow.scale
            width: height
            drag.target: persistentGridViewItem
            drag.axis: Drag.XAndYAxis

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
                storage.swap(drag.source.visualIndex, delegateRoot.visualIndex);
            }
        }
    }


/**
  *     States
  *
  */
}
