import QtQuick 2.2
import QtTest 1.1
import "../../../storage"

Rectangle
{
    id: mainWindow
    color: "green"

    Storage
    {
        id: storage
    }

    TestCase
    {
        name: "TableCreation"

        property var testFixture1: [
        {
            role0: 0,
            role1: 1,
            role2: "str1",
            role3: "str2",
            role4: 4
        },
        {
            role0: 0,
            role1: 1,
            role2: "str3",
            role3: "str4",
            role4: 4
        },
        {
            role0: 56,
            role1: 67,
            role2: "str5",
            role3: "str6",
            role4: 78
        }
        ];

        property var testFixture2: [
        {
            role0: 10,
            role1: 11,
            role2: "str11",
            role3: "str12",
            role4: 14
        },
        {
            role0: 10,
            role1: 11,
            role2: "str13",
            role3: "str14",
            role4: 4
        },
        {
            role0: 156,
            role1: 167,
            role2: "str15",
            role3: "str16",
            role4: 178
        }
        ];

        function init_data()
        {
            compare(storage.dropTable("testTable"), true);
        }

        function test_tableFirstUpdate()
        {
            compare(storage.updateTable("testTable", testFixture1), true);

            var rows = storage.readTable("testTable");
            compare(rows.length, testFixture1.length);

            for (var i = 0; i < rows.length; ++i)
            {
                var row = rows[i];
                var fixtureRow = testFixture1[i];

                for (var key in row)
                {
                    verify(fixtureRow.hasOwnProperty(key), "Key " + key +
                        " is missing.");
                    verify(fixtureRow[key] === row[key], "Keys " + key +
                        " are not equal.");
                }
            }
        }

        function test_tableSecondUpdate()
        {
            compare(storage.updateTable("testTable", testFixture2), true);

            var rows = storage.readTable("testTable");
            compare(rows.length, testFixture2.length);

            for (var i = 0; i < rows.length; ++i)
            {
                var row = rows[i];
                var fixtureRow = testFixture2[i];

                for (var key in row)
                {
                    verify(fixtureRow.hasOwnProperty(key), "Key " + key +
                        " is missing.");
                    verify(fixtureRow[key] === row[key], "Values at " + key +
                        " are not equal.");
                }
            }
        }

        function test_dropTable()
        {
            verify(storage.updateTable("testTable", testFixture1),
                   "Failed to create table");
            verify(storage.dropTable("testTable"),
                   "Failed to drop table.");

            var rows = storage.readTable("testTable");
            verify(rows.length === 0,
                   "Table still exists.");
        }

        function test_clearTable()
        {
            verify(storage.updateTable("testTable", testFixture1),
                   "Failed to create table");
            verify(storage.clearTable("testTable"),
                   "Failed to clear table");

            var rows = storage.readTable("testTable");
            verify(rows.length === 0, "Table is not empty as it is expected.");
        }
    }
}
