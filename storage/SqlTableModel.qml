import QtQuick 2.3

Item
{
    id: sqlTableModel

    property alias database: storage.database
    property alias count: model.count
    property alias internalModel: model
    property string table

    signal loadingFinished();
    signal loadingFailed();
    signal dataChanged();

    // API functions
    function append(jsobject)
    {
        model.append(jsobject);
        saveTimer.restart();
    }

    function clear()
    {
        model.clear();
        saveTimer.restart();
    }

    function get(index)
    {
        return model.get(index);
    }

    function insert(jsobject, index)
    {
        model.insert(index, jsobject);
        saveTimer.restart();
    }

    function move(from, to, count)
    {
        model.move(from, to, count);
        saveTimer.restart();
    }

    function swap(index1, index2)
    {
        if (index1 === index2)
        {
            return;
        }

        model.move(index1, index2, 1);

        if (Math.abs(index1 - index2) != 1)
        {
            if (index2 < index1)
            {
                model.move(index2 + 1, index1, 1);
            }
            else
            {
                model.move(index2 - 1, index1, 1);
            }
        }

        saveTimer.restart();
    }

    function remove(index, count)
    {
        model.remove(index, count);
        saveTimer.restart();
    }

    function set(index, jsobject)
    {
        model.set(index, jsobject);
        saveTimer.restart();
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

        interval: 1000
        repeat: false
        onTriggered:
        {
            internal.save();
            sqlTableModel.loadingFinished();
        }
    }

    ListModel
    {
        id: model

        dynamicRoles: true
    }

    onTableChanged:
    {
        internal.reload();
    }

/**
 *  Internal item for data encapsulation.
 *
 */
    Item
    {
        id: internal

        property var sourceRows: {length: 0}
        property var destinationRows: []
        property int lastProcessed: 0

        Timer
        {
            id: reloadTimer

            interval: 1
            repeat: true
            onTriggered:
            {
                var from = 0;
                var to = internal.sourceRows.length - 1;

                for (var i = from; i <= to; ++i)
                {
                    var obj = {};
                    for (var key in internal.sourceRows.item(i))
                    {
                        obj[key] = internal.sourceRows.item(i)[key];
                    }
                    internal.destinationRows.push(obj);
                }

                internal.lastProcessed = to + 1;
                if (to === internal.sourceRows.length - 1)
                {
                    stop();

                    backgroundLoader.sendMessage({
                        model: model,
                        rows: internal.destinationRows});
                }
            }
        }

        WorkerScript
        {
            id: backgroundLoader
            source: "backgroundLoader.js"

            onMessage:
            {
                sqlTableModel.loadingFinished();
            }
        }

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

            sourceRows = storage.readTable(sqlTableModel.table);

            if (sourceRows === false)
            {
                sqlTableModel.loadingFailed();
                return false;
            }

            destinationRows = [];
            lastProcessed = 0;

            if (sourceRows.length > 0)
            {
                reloadTimer.start();
            }
            else
            {
                sqlTableModel.loadingFinished();
            }

            return true;
        }
    }

    Component.onCompleted:
    {
        internal.reload();
    }
}
