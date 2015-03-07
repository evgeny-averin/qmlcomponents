import QtQuick 2.3
import QtQuick.Window 2.1
import "../../../common/utils.js" as Utils
import "../../../views"

Rectangle
{
    id: mainWindow
    width: 480
    height: 640
    color: "#454545"

    PersistentListView
    {
        id: list
        database: "testDatabase"
        table: "PersistentListViewTest"
        roles: [
            "role1",
            "role2",
            "role3",
            "role4"
        ]

        anchors.fill: parent

        onLoadingFinished:
        {
            list.append({role1: Math.floor(Math.random(10) * 100), role2: 4, role3: 5, role4: 6})
        }
    }
}

