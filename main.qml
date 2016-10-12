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
            addSubset("preview", 1)
            zoomData = data.subsets["zoom"]
            zoomData.onUpdated.connect(updateZoom)

            previewData = data.subsets["preview"]
            previewData.onUpdated.connect(updatePreview)

            root.zoomSeries = chart.createSeries(ChartView.SeriesTypeLine, "series", axisX, axisY);
            root.previewSeries = previewChart.createSeries(ChartView.SeriesTypeLine, "series", previewAxisX, previewAxisY);
        }
    }

    function updateZoomRectangle() {
        var leftPos = previewChart.mapToPosition(Qt.point(zoomData.xMin, 0), previewSeries).x
        var rightPos = previewChart.mapToPosition(Qt.point(zoomData.xMax, 0), previewSeries).x
        console.log("Snapped to right: ", zoomRectangle.snappedToRight)
        console.log("Setting left = ", leftPos, " since xMin = ", zoomData.xMin)

        zoomRectangle.x = leftPos
        if(zoomRectangle.snappedToRight) {
            zoomRectangle.width = zoomRectangle.parent.width-leftPos
        } else {
            zoomRectangle.width = rightPos-leftPos
        }
    }

    function updatePreview() {
        previewData.updateData(root.previewSeries)
        if(handleAreaRight.drag.active || handleAreaLeft.drag.active) return;

        previewData.updateLimits()
        updateZoomRectangle()
        if(previewData.xMax > previewAxisX.max) {
            previewAxisX.max = previewAxisX.max * 2
        }
    }

    function updateZoom() {
        zoomData.updateData(root.zoomSeries)
        zoomData.updateLimits()
        updateZoomRectangle()
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
            min: zoomData.xMin
            max: zoomData.xMax
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

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: {

                // console.log("Mouse pos: ", Qt.point(mouse.x, mouse.y), " P: ", chart.mapToValue(Qt.point(mouse.x, mouse.y), zoomSeries))
            }
        }
    }

    Rectangle {
        id: previewRectangle
        anchors {
            left: chart.left
            right: chart.right
            top: chart.bottom
            bottom: parent.bottom
        }

        radius: 2
        color: root.color
        border.color: "white"
        border.width: 2

        ChartView {
            id: previewChart
            anchors.fill: parent
            property real xRange: previewAxisX.max - previewAxisX.min
            backgroundColor: root.color
            theme: ChartView.ChartThemeDark
            antialiasing: true
            legend.visible: false
            onWidthChanged: {
                selectionLeft.x = width*selectionLeft.percentagePosition
                selectionRight.x = width*selectionRight.percentagePosition
            }

            ValueAxis {
                id: previewAxisX
                tickCount: 0
                min: 0
                max: 1
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
        }

        Rectangle {
            id: selectionLeft
            anchors.horizontalCenter: zoomRectangle.left
            onXChanged: {
                console.log("x: ", x)
                if(handleAreaLeft.drag.active) {
                    zoomData.xMinLimit = previewChart.mapToValue(Qt.point(x, 0), previewSeries).x
                }
            }

            width: 10
            color: "red"

            anchors {
                top: parent.top
                bottom: parent.bottom
            }

            MouseArea {
                id: handleAreaLeft
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.target: parent
                drag.threshold: 0
                drag.maximumX: selectionRight.x-20
                drag.minimumX: 15
            }

            states: [
                State {
                    when: handleAreaLeft.drag.active
                    AnchorChanges {
                        target: selectionLeft
                        anchors.horizontalCenter: undefined
                    }
                }
            ]
        }

        Rectangle {
            id: selectionRight
            anchors.horizontalCenter: zoomRectangle.right
            onXChanged: {
                if(!previewData) return;
                if(handleAreaRight.drag.active) {
                    zoomRectangle.snappedToRight = previewChart.mapToValue(Qt.point(x, 0), previewSeries).x >= previewData.xMax
                    if(zoomRectangle.snappedToRight) {
                        zoomData.xMaxLimit = Infinity
                    } else {
                        zoomData.xMaxLimit = previewChart.mapToValue(Qt.point(x, 0), previewSeries).x
                        console.log("zoomData.xMaxLimit: ", zoomData.xMaxLimit)
                        console.log("zoomdata.xmax", zoomData.xMax)
                    }
                }
            }

            width: 10
            color: "red"

            anchors {
                top: parent.top
                bottom: parent.bottom
            }

            MouseArea {
                id: handleAreaRight
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                drag.target: parent
                drag.threshold: 0
                drag.maximumX: previewChart.width-15
                drag.minimumX: selectionLeft.x+20
            }

            states: [
                State {
                    when: handleAreaRight.drag.active
                    AnchorChanges {
                        target: selectionRight
                        anchors.horizontalCenter: undefined
                    }
                }
            ]
        }

        Rectangle {
            id: zoomRectangle
            property bool snappedToRight: true
            onXChanged: {
                console.log("Changed x to ", x)
            }

            radius: 2
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: snappedToRight ? previewRectangle.right : undefined
            }


            color: Qt.rgba(1.0, 1.0, 1.0, 0.3)
        }
    }
}
