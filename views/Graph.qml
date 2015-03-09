import QtQuick 2.3

Item
{
    readonly property int stepPre: 1
    readonly property int stepPost: 2

    readonly property int lines: 1
    readonly property int bars: 2

    readonly property bool isPersistentGraph: true

    property string name
    property string role
    property color color
    property int step
    property int style
}
