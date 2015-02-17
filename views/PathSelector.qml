import QtQuick 2.0

Item {
    id: pathSelector

    property int itemWidth:  50 * mainWindow.scale
    property int itemHeight: 50 * mainWindow.scale

    property ListModel model: ListModel {}
    property Component delegate: null

    property alias currentIndex: view.currentIndex
    property alias interactive:  view.interactive
    property alias moving:       view.moving
    property int   itemsCount:   model.count

    width: 1200
    height: 400

    function setCurrentIndex(room_index)
    {
        if (view.currentIndex !== room_index) {
            view.positionViewAtIndex(room_index, ListView.Beginning);
        }
    }

    function moveLeft()
    {
        var velocity = 3500;

        if (view.flicking) {
            velocity = 7000;
        }

        view.cancelFlick();
        view.flick(velocity, 0);
    }

    function moveRight()
    {
        var velocity = -3500;

        if (view.flicking) {
            velocity = -7000;
        }

        view.cancelFlick();
        view.flick(velocity, 0);
    }

    ListView {
        id: view

        anchors.fill: parent
        model: pathSelector.model

        orientation:    ListView.Horizontal
        boundsBehavior: ListView.StopAtBounds

        preferredHighlightBegin: (view.width - itemWidth) / 2
        preferredHighlightEnd:   (view.width + itemWidth) / 2
        highlightRangeMode: ListView.StrictlyEnforceRange

        maximumFlickVelocity: 10000
        flickDeceleration: 20000

        delegate: Item {
            property bool isCurrent: index == view.currentIndex
            property real itemScale:     isCurrent ? 1 : 0.7
            property real rotationAngle: isCurrent ? 0 : (index >  view.currentIndex) ? -45 : 45
            property Item userItem

            width:  itemWidth
            height: itemHeight
            opacity: isCurrent ? 1 : 0.5

            Behavior on opacity { NumberAnimation { duration: 300 } }

            transform: [
                Rotation {
                    axis { x: 0; y: 1; z: 0 }
                    angle: rotationAngle
                    origin.x: itemWidth / 2
                    Behavior on angle { NumberAnimation { duration: 300 } }
                },

                Scale {
                    origin {x: itemWidth / 2; y: itemWidth / 2 }
                    xScale: itemScale
                    yScale: itemScale
                    Behavior on xScale { NumberAnimation { duration: 300 } }
                    Behavior on yScale { NumberAnimation { duration: 300 } }
                }
            ]

            Component.onCompleted: {
                if (pathSelector.delegate) {
                    userItem = pathSelector.delegate.createObject(this, {model: model, index: index});
                    userItem.anchors.centerIn = this;
                }
            }

            Component.onDestruction: {
                userItem.destroy();
            }
        }
    }
}
