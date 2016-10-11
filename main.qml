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
    property var zoomSeries
    property var previewSeries
    property var zoomData
    property var previewData

    Data1D {
        id: data
        Component.onCompleted: {
            addSubset("zoom", 1)
            addSubset("preview", 10)
            zoomData = data.subsets["zoom"]
            zoomData.onUpdated.connect(updateZoom)

            previewData = data.subsets["preview"]
            previewData.onUpdated.connect(updatePreview)

            root.zoomSeries = chart.createSeries(ChartView.SeriesTypeLine, "series", axisX, axisY);
            root.previewSeries = previewChart.createSeries(ChartView.SeriesTypeLine, "series", previewAxisX, previewAxisY);
        }
    }

    function updatePreview() {
        previewData.updateData(root.previewSeries)
        previewData.updateLimits()
    }

    function updateZoom() {
        zoomData.updateData(root.zoomSeries)
        zoomData.updateLimits()
    }

    Timer {
        property int count: 0
        running: true
        repeat: true
        interval: 100
        onTriggered: {
            var x = count*0.1
            var y = Math.sin(x)
            // var y = sin(x) + cos(x*x)*cos(x)
            data.add(x,y)

            count += 1
        }
    }

    ChartView {
        id: chart
        anchors {
            left: parent.left
            right: parent.right
        }
        height: root.height*0.8
        theme: ChartView.ChartThemeDark
        antialiasing: true
        legend.visible: true
        title: "A plot"
        titleColor: "black"

        ValueAxis {
            id: axisX
            tickCount: 3
            min: zoomRectangle.xMin
            max: zoomRectangle.xMax
            titleText: "y"
            color: "white"
            labelsColor: "black"
        }

        ValueAxis {
            id: axisY
            tickCount: 3
            min: zoomData.yMin
            max: zoomData.yMax
            titleText: "x"
            color: "white"
            labelsColor: "black"
        }
    }

    ChartView {
        id: previewChart
        anchors {
            left: parent.left
            right: parent.right
            top: chart.bottom
            bottom: parent.bottom
        }

        theme: ChartView.ChartThemeDark
        height: root.height * 0.8
        antialiasing: true
        legend.visible: false
        onWidthChanged: {
            selectionLeft.x = width*selectionLeft.percentagePosition
            selectionRight.x = width*selectionRight.percentagePosition
        }

        ValueAxis {
            id: previewAxisX
            tickCount: 0
            min: previewData.xMin
            max: previewData.xMax
            gridVisible: false
            visible: false
            color: "white"
        }

        ValueAxis {
            id: previewAxisY
            tickCount: 0
            min: previewData.yMin
            max: previewData.yMax
            gridVisible: false
            visible: false
            color: "white"
        }

        Rectangle {
            id: selectionLeft
            x: 10
            width: 10
            color: "red"

            anchors {
                top: previewChart.top
                bottom: previewChart.bottom
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.target: parent
            }
        }

        Rectangle {
            id: selectionRight
            x: 30
            width: 10
            color: "red"

            anchors {
                top: previewChart.top
                bottom: previewChart.bottom
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.target: parent
            }
        }

        Rectangle {
            id: zoomRectangle
            property real xMin: previewAxisX.min + x / previewChart.width * (previewAxisX.max - previewAxisX.min)
            property real xMax: (x+width) > 0.95*previewChart.width ? previewAxisX.max : (previewAxisX.min + (x+width) / previewChart.width * (previewAxisX.max - previewAxisX.min))
            onXMinChanged: console.log("xlim: [", xMin, ", ", xMax, "]")
            onXMaxChanged: console.log("xlim: [", xMin, ", ", xMax, "]")
            radius: 10
            anchors {
                top: previewChart.top
                bottom: previewChart.bottom
                left: selectionLeft.right
                right: selectionRight.left
            }

            color: Qt.rgba(1.0, 1.0, 1.0, 0.3)
        }
    }
}
