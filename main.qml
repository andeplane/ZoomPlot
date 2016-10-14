import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtCharts 2.1
import Data1D 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 640
    height: 480

    Timer {
        property int count: 0
        running: true
        repeat: true
        interval: 16
        onTriggered: {
            var x = count*0.1
            var y = Math.sin(x)
            data1.add(x,y)
            y = Math.cos(x)
            data2.add(x,y)

            count += 1
        }
    }

    Data1D {
        id: data1
        key: "myData1"
        Component.onCompleted: {
            addSubset("zoom", 1)
            addSubset("preview", 1)
        }
    }

    Data1D {
        id: data2
        key: "myData2"
        Component.onCompleted: {
            addSubset("zoom", 1)
            addSubset("preview", 1)
        }
    }

    ZoomablePlot {
        id: plot
        color: root.color
        anchors.fill: parent
    }

    Button {
        text: "Add plots"

        onClicked: {
            plot.dataSources = {"myData1": data1, "myData2": data2 }
        }
    }
}
