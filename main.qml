import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtCharts 2.1
import Data1D 1.0

ApplicationWindow {
    id: root
    property int count: 0
    visible: true
    width: 640
    height: 480

    Timer {
        id: timer
        running: false
        repeat: true
        interval: 16
        onTriggered: addPoint()
    }

    function addPoint() {
        var x = root.count*0.1
        var y = Math.sin(x)
        data1.add(x,y)
        y = Math.cos(x)
        data2.add(x,y)
        root.count += 1
    }

    Data1D {
        id: data1
        Component.onCompleted: {
            addSubset("zoom", 1)
            addSubset("preview", 1)
        }
    }

    Data1D {
        id: data2
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

    Row {
        Button {
            text: "Add plots"

            onClicked: {
                plot.dataSources = {"myData1": data1, "myData2": data2 }
            }
        }

        Button {
            text: "Add point"
            onClicked: addPoint()
        }

        Button {
            text: timer.running ? "Stop timer" : "Start timer"
            onClicked: {
                if(timer.running) timer.stop()
                else timer.start()
            }
        }
    }
}
