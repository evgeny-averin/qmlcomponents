import QtQuick 2.3
import QtQuick.LocalStorage 2.0

Item {
    property var _database: null

    function database()
    {
        if (!_database) {
            _database = LocalStorage.openDatabaseSync("DictionariesDB", "1.0", "Pretty dictionary database", 1000000);
        }
        return _database;
    }

    function clearTable(table_name)
    {
        try {
            database().transaction(function (tx) {
                tx.executeSql("DELETE FROM TABLE " + table_name);
            });
        } catch (err) {
            console.log("Error during DB operation:", err);
        }
    }

    function dropTable(table_name)
    {
        try {
            database().transaction(function (tx) {
                tx.executeSql("DROP TABLE IF EXISTS " + table_name);
            });
        } catch (err) {
            console.log("Error during DB operation:", err);
        }
    }

    function readTable(table_name, proc)
    {
        try {
            database().transaction(function (tx) {
                    var rs = tx.executeSql("SELECT * FROM " + table_name);
                    proc(rs.rows);
                }
            )
        } catch (err) {
            console.log("Error during DB operation:", err);
        }
    }

    function updateTable(table_name, get_entries_proc)
    {
        try {
            database().transaction(
                function (tx) {
                    var entries = get_entries_proc();
                    var query = "CREATE TABLE IF NOT EXISTS " + table_name + "(";
                    var keys = [];

                    if (entries.length > 0) {
                        var first_entry = entries[0];

                        for (var key in first_entry) {
                            switch(typeof first_entry[key]) {
                                case "string": {
                                    keys.push({name: key, type: "STRING"});
                                    break;
                                }
                                case "number": {
                                    keys.push({name: key, type: "FLOAT"});
                                    break;
                                }
                            }
                        }
                    }

                    var placeholder = "VALUES(";

                    for (var i = 0; i < keys.length; ++i) {
                        query += keys[i].name + " " + keys[i].type;

                        if (i < keys.length - 1) {
                            placeholder += "?, "
                            query += ", ";
                        } else {
                            placeholder += "?)";
                            query += ")";
                        }
                    }

                    console.log("query:", query)

                    tx.executeSql("DROP TABLE IF EXISTS " + table_name);
                    tx.executeSql(query);

                    for (i = 0; i < entries.length; ++i) {
                        var values = [];
                        for (var j = 0; j < keys.length; ++j) {
                            var value;
                            if (keys[j].type === "STRING") {
                                value = entries[i][keys[j].name];
                            } else {
                                value = entries[i][keys[j].name];
                            }

                            values.push(value);
                        }

                        console.log("INSERT INTO " + table_name + " " + placeholder, values);
                        tx.executeSql("INSERT INTO " + table_name + " " + placeholder, values);
                    }
                }
            );
        } catch (err) {
            console.log("Error during DB operation:", err);
        }
    }
}
