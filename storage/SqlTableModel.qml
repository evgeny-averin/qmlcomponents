import QtQuick 2.3

Item
{
    id: sqlTableModel

    property alias database: storage.database
    property alias count: model.count
    property alias internalModel: model
    property string table

    signal loadingFinished();

/**
 *  API functions
 *
 */

    function append(jsobject)
    {
        model.append(jsobject);
        saveTimer.start();
    }

    function clear()
    {
        model.clear();
        saveTimer.start();
    }

    function get(index)
    {
        return model.get(index);
    }

    function insert(jsobject, index)
    {
        model.insert(jsobject, index);
        saveTimer.start();
    }

    function move(from, to, count)
    {
        model.move(from, to, count);
        saveTimer.start();
    }

    function remove(index, count)
    {
        model.remove(index, count);
        saveTimer.start();
    }

    function set(index, jsobject)
    {
        model.set(index, jsobject);
        saveTimer.start();
    }

    function save()
    {
        internal.save();
        saveTimer.stop();
    }

/**
 *  Qml items structure
 *
 */

    Storage
    {
        id: storage
    }

    Timer
    {
        id: saveTimer

        interval: 10
        repeat: false
        onTriggered:
        {
            internal.save();
        }
    }

    onDatabaseChanged:
    {
        internal.reload();
    }

    onTableChanged:
    {
        internal.reload();
    }

    ListModel
    {
        id: model

        dynamicRoles: true
        onDataChanged:
        {
            internal.save();
        }
    }

/**
 *  Internal item for data encapsulation.
 *
 */
    Item
    {
        id: internal

        function save()
        {
            if (sqlTableModel.database.length == 0 ||
                    sqlTableModel.table.length == 0)
            {
                return false;
            }

            var rows = [];
            for (var i = 0; i < model.count; ++i)
            {
                rows.push(model.get(i));
            }

            storage.updateTable(sqlTableModel.table, rows);
        }

        function reload()
        {
            if (sqlTableModel.database.length == 0 ||
                    sqlTableModel.table.length == 0)
            {
                return false;
            }

            var rows = storage.readTable(sqlTableModel.table);
            model.clear();

            for (var i = 0; i < rows.length; ++i)
            {
                var row = rows[i];
                model.append(row);
            }

            return true;
        }
    }

    Component.onCompleted:
    {
        internal.reload();
        sqlTableModel.loadingFinished();
    }
}
