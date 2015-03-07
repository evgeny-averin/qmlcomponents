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
        internal.verify(jsobject);
        storage.append(jsobject);
    }

    function insert(jsobject, index)
    {
        internal.verify(jsobject);
        storage.insert(jsobject, index);
    }

    function remove(index)
    {
        internal.verifyIndex("remove()", index);
        storage.remove(index, 1);
    }

    function get(index)
    {
        internal.verifyIndex("get()", index);
        storage.get(index);
    }

    function set(jsobject, index)
    {
        internal.verify(jsobject);
        internal.verifyIndex("set()", index);
        storage.set(index, jsobject);
    }

    function clear()
    {
        storage.clear();
    }

/**
  *     Internal structure - place all private data here.
  *
  */
    Item
    {
        id: internal

        function verify(jsobject)
        {
            if (roles.length != Object.keys(jsobject).length)
            {
                throw "PersistentListView.internal::verify(): Object properties" +
                        " length invalid (must be = " + roles.length + ")";
            }

            for (var i = 0; i < roles.length; ++i)
            {
                if (!jsobject.hasOwnProperty(roles[i]))
                {
                    throw "PersistentListView.internal::verify(): Object " +
                            "missing property " + roles[i];
                }
            }
        }

        function verifyIndex(scope, index)
        {
            if (index >= count)
            {
                throw "PersistentListView::" + scope + ": Invalid index ("
                        + index + ")"
            }
        }
    }

    SqlTableModel
    {
        id: storage
        onLoadingFinished:
        {
            persistentListView.loadingFinished();
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

            height: 40
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
                rightMargin: height / 2
            }

            height: 20
            width: height
            drag.target: persistentListViewItem
            drag.axis: Drag.YAxis

            Rectangle
            {
                anchors.fill: parent
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
