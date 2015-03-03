import QtQuick 2.3
import QtQuick.LocalStorage 2.0

Item
{
    id: storage
    property string database
    property string version: "1.0"
    property string description: ""

    Item
    {
        id: internal
        property var _database: null

        function database()
        {
            if (!_database)
            {
                _database = LocalStorage.openDatabaseSync(storage.database, "1.0",
                    storage.description, 1000000);
            }
            return _database;
        }
    }

    function clearTable(table_name)
    {
        try
        {
            internal.database().transaction(function (tx)
            {
                tx.executeSql("DELETE FROM " + table_name);
            });
        }
        catch (err)
        {
            console.log("Storage::clearTable:", err);
            return false;
        }
        return true;
    }

    function dropTable(table_name)
    {
        try
        {
            internal.database().transaction(function (tx)
            {
                tx.executeSql("DROP TABLE IF EXISTS " + table_name);
            });
        }
        catch (err)
        {
            console.log("Storage::dropTable:", err);
            return false;
        }
        return true;
    }

    function readTable(table_name)
    {
        try
        {
            var result = [];
            internal.database().transaction(function (tx)
            {
                var rs = tx.executeSql("SELECT * FROM " + table_name);
                result = rs.rows;
            });
            return result;
        }
        catch (err)
        {
            console.log("Storage::readTable:", err);
            return [];
        }
    }

    function updateTable(table_name, entries)
    {
        try
        {
            internal.database().transaction(function (tx)
            {
                var query = "CREATE TABLE IF NOT EXISTS " + table_name + "(";
                var keys = [];

                if (entries.length > 0)
                {
                    var first_entry = entries[0];

                    for (var key in first_entry)
                    {
                        switch(typeof first_entry[key])
                        {
                            case "string":
                            {
                                keys.push({name: key, type: "STRING"});
                                break;
                            }

                            case "number":
                            {
                                keys.push({name: key, type: "FLOAT"});
                                break;
                            }
                        }
                    }
                }

                var placeholder = "VALUES(";

                for (var i = 0; i < keys.length; ++i)
                {
                    query += keys[i].name + " " + keys[i].type;

                    if (i < keys.length - 1)
                    {
                        placeholder += "?, "
                        query += ", ";
                    }
                    else
                    {
                        placeholder += "?)";
                        query += ")";
                    }
                }

                tx.executeSql("DROP TABLE IF EXISTS " + table_name);

                if (entries.length > 0)
                {
                    tx.executeSql(query);
                }

                for (i = 0; i < entries.length; ++i)
                {
                    var values = [];
                    for (var j = 0; j < keys.length; ++j)
                    {
                        var value;
                        if (keys[j].type === "STRING")
                        {
                            value = entries[i][keys[j].name];
                        }
                        else
                        {
                            value = entries[i][keys[j].name];
                        }

                        values.push(value);
                    }

                    tx.executeSql("INSERT INTO " + table_name + " " + placeholder, values);
                }
            });
        }
        catch (err)
        {
            console.log("Storage::updateTable:", err);
            return false;
        }

        return true;
    }
}
