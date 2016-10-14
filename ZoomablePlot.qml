import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtCharts 2.1
import Data1D 1.0

Rectangle {
    id: root
    property var zoomSeries
    property var previewSeries
    property var zoomData
    property var previewData
    property alias dataSource: data

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

        zoomRectangle.x = leftPos
        if(zoomRectangle.snappedToRight) {
            zoomRectangle.width = zoomRectangle.parent.width-leftPos
        } else {
            zoomRectangle.width = rightPos-leftPos
        }
    }

    function updatePreview() {
        previewData.updateData(root.previewSeries)
        if(handleAreaRight.drag.active || handleAreaLeft.drag.active || moveHandle.drag.active) return;

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

    ChartView {
        id: chart
        anchors {
            left: parent.left
            right: parent.right
        }
        height: root.height*0.8
        theme: ChartView.ChartThemeDark
        backgroundColor: root.color
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
        border.width: 0

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

        Item {
            id: rect
            property real oldWidth: 0
            anchors.horizontalCenter: zoomRectangle.horizontalCenter
            anchors.verticalCenter: zoomRectangle.verticalCenter
            width: zoomRectangle.width
            height: zoomRectangle.height
            onXChanged: {
                if(!moveHandle.drag.active) return

                var newXMaxLimit = previewChart.mapToValue(Qt.point(x+rect.oldWidth, 0), previewSeries).x
                if(newXMaxLimit > data.xMax) {
                    zoomRectangle.snappedToRight = true
                } else {
                    zoomRectangle.snappedToRight = false
                }

                if(zoomRectangle.snappedToRight) {
                    zoomData.xMaxLimit = Infinity
                } else {
                    zoomData.xMaxLimit = newXMaxLimit
                }
                zoomData.xMinLimit = previewChart.mapToValue(Qt.point(x, 0), previewSeries).x

            }

            MouseArea {
                id: moveHandle
                anchors.fill: parent
                drag.target: parent
                drag.threshold: 0
                drag.minimumX: 15
                drag.maximumX: previewChart.width-15

                onPressed: {
                    if(!zoomRectangle.snappedToRight || rect.oldWidth===0) {
                        rect.oldWidth = rect.width
                    }
                }
            }

            states: [
                State {
                    when: moveHandle.drag.active
                    AnchorChanges {
                        target: rect
                        anchors.horizontalCenter: undefined
                        anchors.verticalCenter: undefined
                    }
                }
            ]
        }

        Rectangle {
            id: zoomRectangle
            property bool snappedToRight: true
            color: Qt.rgba(1.0, 1.0, 1.0, 0.3)

            radius: 2
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: snappedToRight ? previewRectangle.right : undefined
                rightMargin: snappedToRight ? 15 : 0
            }
        }

        Item {
            id: selectionLeft
            width: 15
            anchors.horizontalCenter: zoomRectangle.left
            onXChanged: {
                if(handleAreaLeft.drag.active) {
                    zoomData.xMinLimit = previewChart.mapToValue(Qt.point(x, 0), previewSeries).x
                }
            }

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
                drag.maximumX: selectionRight.x-50
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

        Item {
            id: selectionRight
            width: zoomRectangle.snappedToRight ? 30 : 15
            anchors.horizontalCenter: zoomRectangle.right
            onXChanged: {
                if(!previewData) return;
                if(handleAreaRight.drag.active) {
                    zoomRectangle.snappedToRight = previewChart.mapToValue(Qt.point(x, 0), previewSeries).x >= previewData.xMax
                    if(zoomRectangle.snappedToRight) {
                        zoomData.xMaxLimit = Infinity
                    } else {
                        zoomData.xMaxLimit = previewChart.mapToValue(Qt.point(x, 0), previewSeries).x
                    }
                }
            }


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
                drag.minimumX: selectionLeft.x+50
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
    }
}
