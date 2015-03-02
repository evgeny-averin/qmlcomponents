import QtQuick 2.0

Item {
    id: root

    property var items: []

    width: 100
    height: 62

    function push(item)
    {
        items.push(item);
    }

    function pop()
    {
        if(items.length > 0) {
            var popped = items.pop();
            popped.close();
        }
    }

    function size()
    {
        return items.length;
    }
}
