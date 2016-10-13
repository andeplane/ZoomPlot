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

    Timer {
        property int count: 0
        running: true
        repeat: true
        interval: 16
        onTriggered: {
            var x = count*0.1
            var y = Math.sin(x)
            data.add(x,y)

            count += 1
        }
    }


}
