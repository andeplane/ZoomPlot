import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtCharts 2.1
import Data1D 1.0

Rectangle {
    id: root
    property var dataSources: []
    onDataSourcesChanged: updateSeries("line")

    function updateSeries(type) {
        zoomChart.removeAllSeries();
        previewChart.removeAllSeries();

        d.zoomSeries = ({})
        d.previewSeries = ({})
        d.zoomData = ({})
        d.previewData = ({})

        if (type === "line") {
            var i = 0
            for(var key in dataSources) {
                var dataSource = dataSources[key]
                var zoomData = dataSource.subsets["zoom"]
                var previewData = dataSource.subsets["preview"]

                d.zoomData[i] = zoomData
                d.previewData[i] = previewData

                var series = zoomChart.createSeries(ChartView.SeriesTypeLine, key, axisX, axisY);
                d.zoomSeries[i] = series
                zoomData.setXySeries(series)

                series = previewChart.createSeries(ChartView.SeriesTypeLine, key, previewAxisX, previewAxisY);
                series.useOpenGL=true
                d.previewSeries[i] = series
                previewData.setXySeries(series)

                zoomData.onUpdated.connect( function() { updateZoom() } )
                previewData.onUpdated.connect( function() { updatePreview() } )

                i += 1
            }
        }
    }

    QtObject {
        id: d
        property real xMin: 0
        property real xMax: 1
        property real yMin: 0
        property real yMax: 1
        property real previewXMin: 0
        property real previewXMax: 1
        property real previewYMin: 0
        property real previewYMax: 1

        property var zoomSeries: ({})
        property var previewSeries: ({})
        property var zoomData: ({})
        property var previewData: ({})

        function updatePreviewLimits() {
            if(previewData.length === 0) return
            var first = true
            for(var key in zoomData) {
                if(first) {
                    previewXMin = previewData[key].xMin
                    previewXMax = previewData[key].xMax
                    previewYMin = previewData[key].yMin
                    previewYMax = previewData[key].yMax
                }

                previewXMin = Math.min(previewXMin, previewData[key].xMin)
                previewXMax = Math.max(previewXMax, previewData[key].xMax)
                previewYMin = Math.min(previewYMin, previewData[key].yMin)
                previewYMax = Math.max(previewYMax, previewData[key].yMax)
            }
        }

        function updateZoomLimits() {
            if(zoomData.length === 0) return
            var first = true
            for(var key in zoomData) {
                if(first) {
                    xMin = zoomData[key].xMin
                    xMax = zoomData[key].xMax
                    yMin = zoomData[key].yMin
                    yMax = zoomData[key].yMax
                    first = false
                }

                xMin = Math.min(xMin, zoomData[key].xMin)
                xMax = Math.max(xMax, zoomData[key].xMax)
                yMin = Math.min(yMin, zoomData[key].yMin)
                yMax = Math.max(yMax, zoomData[key].yMax)
            }
        }
    }

    function updateZoomRectangle() {
        var leftPos = previewChart.mapToPosition(Qt.point(d.xMin, 0), d.previewSeries[0]).x
        var rightPos = previewChart.mapToPosition(Qt.point(d.xMax, 0), d.previewSeries[0]).x

        zoomRectangle.x = leftPos
        if(zoomRectangle.snappedToRight) {
            zoomRectangle.width = zoomRectangle.parent.width-leftPos
        } else {
            zoomRectangle.width = rightPos-leftPos
        }
    }

    function updatePreview() {
        if(handleAreaRight.drag.active || handleAreaLeft.drag.active || moveHandle.drag.active) return;

        for(var key in d.previewData) {
            d.previewData[key].updateLimits()
        }
        d.updatePreviewLimits()
        updateZoomRectangle()

        if(d.previewXMax > previewAxisX.max) {
            previewAxisX.max = previewAxisX.max * 2
        }
    }

    function updateZoom() {
        for(var key in d.zoomData) {
            d.zoomData[key].updateLimits()
        }
        d.updateZoomLimits()
        updateZoomRectangle()
    }

    ChartView {
        id: zoomChart
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
            min: d.xMin
            max: d.xMax
            titleText: "y"
            color: "white"
            labelsColor: "black"
        }

        ValueAxis {
            id: axisY
            tickCount: 3
            min: d.yMin
            max: d.yMax
            titleText: "x"
            color: "white"
            labelsColor: "black"
        }
    }

    Rectangle {
        id: previewRectangle
        anchors {
            left: zoomChart.left
            right: zoomChart.right
            top: zoomChart.bottom
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
                min: d.previewYMin
                max: d.previewYMax
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

                var newXMaxLimit = previewChart.mapToValue(Qt.point(x+rect.oldWidth, 0), d.previewSeries[0]).x
                if(newXMaxLimit > d.previewXMax) {
                    zoomRectangle.snappedToRight = true
                } else {
                    zoomRectangle.snappedToRight = false
                }

                for(var key in d.zoomData) {
                    if(zoomRectangle.snappedToRight) {
                        d.zoomData[key].xMaxLimit = Infinity
                    } else {
                        d.zoomData[key].xMaxLimit = newXMaxLimit
                    }
                    d.zoomData[key].xMinLimit = previewChart.mapToValue(Qt.point(x, 0), d.previewSeries[0]).x
                }

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

                drag.onActiveChanged: {
                    for(var key in d.zoomSeries) {
                        d.zoomSeries[key].useOpenGL = drag.active
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
                    var newXMin = previewChart.mapToValue(Qt.point(x, 0), d.previewSeries[0]).x
                    for(var key in d.zoomData) {
                        d.zoomData[key].xMinLimit = newXMin
                    }
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
                drag.onActiveChanged: {
                    for(var key in d.zoomSeries) {
                        d.zoomSeries[key].useOpenGL = drag.active
                    }
                }
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
                if(d.previewData.length===0) return;
                if(handleAreaRight.drag.active) {
                    zoomRectangle.snappedToRight = previewChart.mapToValue(Qt.point(x, 0), d.previewSeries[0]).x >= d.previewXMax
                    for(var key in d.zoomData) {
                        if(zoomRectangle.snappedToRight) {
                            d.zoomData[key].xMaxLimit = Infinity
                        } else {
                            d.zoomData[key].xMaxLimit = previewChart.mapToValue(Qt.point(x, 0), d.previewSeries[0]).x
                        }
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
                drag.onActiveChanged: {
                    for(var key in d.zoomSeries) {
                        d.zoomSeries[key].useOpenGL = drag.active
                    }
                }
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
