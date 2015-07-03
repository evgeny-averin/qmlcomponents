import QtQuick 2.0

Item
{
    id: maximizableItem

    property bool maximized_: false
    property Item parentOnMaximized
    property Item originalParent
    property Item view


    signal aboutToMaximize()
    signal aboutToMinimize()
    signal maximized()
    signal minimized()

    height: parent.height
    width:  parent.width
    x: 0
    y: 0

    function maximize()
    {
        maximized_ = true;
    }

    function minimize()
    {
        maximized_ = false;
    }

    MouseArea
    {
        anchors.fill: parent
        onClicked:
        {
            if (!maximized_)
            {
                maximized_ = true;
            }
        }
    }

    states:
    [
        State
        {
            name: "expandedState"
            when: maximizableItem.maximized_
            ParentChange    { target: maximizableItem; parent: parentOnMaximized; width: parentOnMaximized.width; height: parentOnMaximized.height }
            PropertyChanges { target: maximizableItem; x: 0; y: 0; z: 2 }
            PropertyChanges { target: originalParent;  z: 2 }
            PropertyChanges { target: view;            z: 2 }
        }
    ]

    transitions:
    [
        Transition
        {
            to: "expandedState"
            ParentAnimation { NumberAnimation
            {
                target: maximizableItem
                properties: "x,y,width,height"
                duration: 500
                easing.type: Easing.InOutQuad
            }}

            onRunningChanged:
            {
                if (running)
                {
                    maximizableItem.aboutToMaximize();
                }
                else
                {
                    maximizableItem.maximized();
                }
            }
        },

        Transition
        {
            from: "expandedState"
            SequentialAnimation
            {
                ParentAnimation { NumberAnimation
                {
                    properties: "x,y,width,height"
                    duration: 500
                    easing.type: Easing.InOutQuad
                }}
                NumberAnimation { properties: "z"; duration: 0 }
            }

            onRunningChanged:
            {
                if (running)
                {
                    maximizableItem.aboutToMinimize();
                }
                else
                {
                    maximizableItem.minimized();
                }
            }
        }
    ]
}

