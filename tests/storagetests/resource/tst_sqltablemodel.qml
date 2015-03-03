import QtQuick 2.2
import QtTest 1.1
import "../../../storage"

Item
{
    SqlTableModel
    {
        id: model
        database: "testDatabase"
        table: "testTable2"
    }

    Storage
    {
        id: storage
        database: model.database
    }

    TestCase
    {
        name: "SqlTableModelTest"

        property var fixture: [
            {role0: 10, role1: 20},
            {role0: 11, role1: 21},
            {role0: 12, role1: 22},
            {role0: 13, role1: 23},
            {role0: 14, role1: 24},
            {role0: 15, role1: 25},
            {role0: 16, role1: 26},
            {role0: 17, role1: 27}
        ]

        function test_append()
        {
            for(var i in fixture)
            {
                model.append(fixture[i]);
            }

            var rows = storage.readTable(model.table);
            compare(rows.length, model.count);

            for (i in rows)
            {
                var row = rows[i];
                var modelRow = model.get(i);

                compare(row.role0, modelRow.role0);
                compare(row.role1, modelRow.role1);
            }
        }
    }
}
