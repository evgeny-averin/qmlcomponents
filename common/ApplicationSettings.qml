import QtQuick 2.3
import "../../qmlcomponents/views"
import "../../qmlcomponents/storage"
import "qrc:/../../qmlcomponents/views"
import "qrc:/../../qmlcomponents/storage"

Item
{
    id: applicationSettings

    property alias database: storage.database
    property alias table:    storage.table
    property alias roles:    persistence.roles

    signal loadingFinished()
    signal loadingFailed()

    width: 100
    height: 62

    function get(role, defaultValue)
    {
        persistence.internalSettings = undefined;

        if (storage.count > 0)
        {
            persistence.internalSettings = {};

            var storageItem = storage.get(0);
            for (var i = 0; i < roles.length; ++i)
            {
                persistence.internalSettings[roles[i]] = storageItem[roles[i]];
            }
        }

        if (persistence.internalSettings)
        {
            return persistence.internalSettings[role];
        }

        return defaultValue;
    }

    function set(role, value)
    {
        if (!persistence.internalSettings)
        {
            persistence.internalSettings = {};
        }

        persistence.internalSettings[role] = value;

        if (storage.count == 0)
        {
            persistence.append(persistence.internalSettings);
        }
        else
        {
            persistence.set(persistence.internalSettings, 0);
        }
    }

    function clear()
    {
        persistence.clear();
    }

    Persistence
    {
        id: persistence

        property var internalSettings

        storage: SqlTableModel
        {
            id: storage

            onLoadingFinished:
            {
                applicationSettings.loadingFinished();
            }

            onLoadingFailed:
            {
                applicationSettings.loadingFailed();
            }
        }
    }
}

