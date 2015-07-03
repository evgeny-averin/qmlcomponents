import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import QtSensors 5.0
import "../storage"
import "../common"

ListView
{
    id: persistentListView

/**
  *     API properties
  *
  */
    property alias roles: persistence.roles
    property alias database: storage.database
    property alias table: storage.table
    property alias verticalScrollbar: verticalScrollbar
    property Component itemDelegate
    property bool itemsDraggable: false

    maximumFlickVelocity: 5000
    flickDeceleration: 4000

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

    function appendSorted(jsobject)
    {
        if (section.property.length == 0)
        {
            persistence.append(jsobject);
        }
        else
        {
            var found = false;

            for (var i = 0; i < count; ++i)
            {
                var ch0 = jsobject[section.property][0];
                var ch1 =   get(i)[section.property][0];

                if (ch0 < ch1)
                {
                    break;
                }

                if (!found)
                {
                    if (ch0 === ch1) { found = true; }
                }
                else if (ch0 !== ch1)
                {
                    break;
                }
            }

            console.log("insert", i);
            persistence.insert(jsobject, i);
        }
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

        width:  persistentListViewItem.width
        height: persistentListViewItem.height

        PersistentListViewItem
        {
            id: persistentListViewItem

            property int modelIndex: index

            height: loader.item.height
            width:  loader.item.width
            interactive: persistentListView.interactive

            anchors
            {
                verticalCenter: parent.verticalCenter
            }

            onDeleted:
            {
                storage.remove(index, 1);
            }

            Loader
            {
                id: loader
                sourceComponent: itemDelegate
                onLoaded:
                {
                    item.setData(index, delegateRoot,
                        persistentListView.model.get(index));
                }
            }

            onModelIndexChanged:
            {
                if (loader.item)
                {
                    loader.item.setData(index, delegateRoot,
                        persistentListView.model.get(index));
                }
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
            enabled: itemsDraggable

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
                visible: itemsDraggable
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
            enabled: itemsDraggable
            onEntered:
            {
                storage.move(drag.source.visualIndex, delegateRoot.visualIndex, 1);
            }
        }
    }

    VerticalScrollBar
    {
        id: verticalScrollbar
    }

/**
  *     States
  *
  */
}
