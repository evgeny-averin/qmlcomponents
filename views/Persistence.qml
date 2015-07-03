import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import QtSensors 5.0
import "../storage"

Item
{
    id: persistence

/**
  *     API properties
  *
  */
    property var roles: []
    property SqlTableModel storage

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
        return storage.get(index);
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
                throw "Persistence::verify(): Object properties" +
                        " length (" + Object.keys(jsobject).length + ") is invalid (must be = "
                        + roles.length + ")";
            }

            for (var i = 0; i < roles.length; ++i)
            {
                if (!jsobject.hasOwnProperty(roles[i]))
                {
                    throw "Persistence::verify(): Object " +
                            "missing property " + roles[i];
                }
            }
        }

        function verifyIndex(scope, index)
        {
            if (index >= storage.count)
            {
                throw "Persistence::" + scope + ": Invalid index ("
                        + index + ")"
            }
        }
    }
}
