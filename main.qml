import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Controls 1.4 as QQC1
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
            addSubset("stride", 1)
        }
    }

    Data1D {
        id: data2
        Component.onCompleted: {
            addSubset("zoom", 1)
            addSubset("preview", 1)
            addSubset("stride", 1)
        }
    }

    ZoomablePlot {
        id: plot
        color: root.color
        anchors.fill: parent
    }

//    ZoomablePlot2 {
//        id: plot
//        color: root.color
//        // xMinLimit: slider.first.value
//        // xMaxLimit: slider.second.value
//        xMaxLimit: slider.value
//        anchors.fill: parent
//    }

    Column {
        Row {
            id: row
            Button {
                text: "Add plots"

                onClicked: {
                    plot.dataSources = [data1, data2]
                }
            }

            Button {
                text: "Add point"
                onClicked: addPoint()
            }

            Button {
                text: "Zoom"
                onClicked: plot.zoom()
            }

            Button {
                text: timer.running ? "Stop timer" : "Start timer"
                onClicked: {
                    if(timer.running) timer.stop()
                    else timer.start()
                }
            }
        }
        Row {
//            Label {
//                width: 50
//                text: slider.first.value.toFixed(2)
//            }
//            RangeSlider {
//                id: slider
//                from: 0
//                to: 100
//                second.value: 100
//                first.value: 0
//                width: row.width
//            }

            QQC1.Slider {
                id: slider
                minimumValue: 0
                maximumValue: 100
                value: 100
                width: row.width
            }

            Label {
                text: slider.value.toFixed(2)
            }
        }
    }
}
