import QtQuick 2.3

Item {
    id: waitingIcon

    height: 45 * mainWindow.scale
    width: height

    Repeater {
        model: [0, 1, 2, 3, 4]
        delegate: Item {
            width:  waitingIcon.width
            height: width

            SequentialAnimation on rotation {
                NumberAnimation {
                    duration: 120 * index
                }

                NumberAnimation {
                    from: -index * 15
                    to: 720 - index * 15
                    running: true
                    loops: Animation.Infinite
                    duration: 4000
                    easing.type: Easing.InOutCubic
                }
            }

            Rectangle{
                height: 6 * mainWindow.scale; width: height; radius: height; smooth:true
                color: "#99ffffff"
                border.color: "#cdffffff"
                border.width: 1
                opacity: 0.8
            }
        }
    }
}
