import QtQuick 2.3

Rectangle
{
    id: shadow

    anchors.top: parent.bottom
    width:       parent.width
    height:      12 * mainWindow.scale
    opacity:     0.67

    gradient: Gradient
    {
        GradientStop {color: "#50000000"; position: 0}
        GradientStop {color: "#40000000"; position: 0.008}
        GradientStop {color: "#30000000"; position: 0.064}
        GradientStop {color: "#20000000"; position: 0.216}
        GradientStop {color: "#10000000"; position: 0.512}
        GradientStop {color: "#00000000"; position: 1}
    }
}
