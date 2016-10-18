import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtCharts 2.1
import Data1D 1.0

Rectangle {
    id: root
    property var dataSources: []
    property real xMin: 0
    property real xMax: 1
    property real xMinLimit
    property real xMaxLimit
    property real yMin: 0
    property real yMax: 1
    onDataSourcesChanged: updateSeries("line")
    onXMinLimitChanged: zoom()
    onXMaxLimitChanged: zoom()

    function zoom() {
        if(dataSources.length===0) return

        chart.zoomReset()
        var p1 = chart.mapToPosition(Qt.point(root.xMinLimit, root.yMin), dataSources[0].xySeries)
        var p2 = chart.mapToPosition(Qt.point(root.xMaxLimit, root.yMax), dataSources[0].xySeries)
        console.log("Zooming with xminlimit: ", root.xMinLimit)
        console.log("Zooming with xmaxlimit: ", root.xMaxLimit)

        console.log("Zooming with ymin: ", root.yMin)
        console.log("Zooming with ymax: ", root.yMax)
        var w = p2.x - p1.x
        var h = p1.y - p2.y
        console.log("Corresponds to rectangle: ", p1.x, ", ", p1.y-h, ", ", w, ", ", h)
        chart.zoomIn(Qt.rect(p1.x, p1.y-h, w, h))
    }

    function updateSeries(type) {
        chart.removeAllSeries();

        if (type === "line") {
            for(var key in dataSources) {
                var dataSource = dataSources[key]
                dataSource.onUpdated.connect(updateLimits)
                var series = chart.createSeries(ChartView.SeriesTypeLine, key, axisX, axisY);
                dataSource.setXySeries(series)
            }
        }
    }

    function updateLimits() {
        if(dataSources.length === 0) return
        var newXMin = dataSources[0].xMin
        var newXMax = dataSources[0].xMax
        var newYMin = dataSources[0].yMin
        var newYMax = dataSources[0].yMax

        for(var key in dataSources) {
            var dataSource = dataSources[key]
            dataSource.updateLimits()
            newXMin = Math.min(newXMin, dataSource.xMin)
            newXMax = Math.max(newXMax, dataSource.xMax)
            newYMin = Math.min(newYMin, dataSource.yMin)
            newYMax = Math.max(newYMax, dataSource.yMax)
        }
        // TODO: will set guards fix this? I think yes
        if(Math.abs(root.xMin - newXMin) > 1e-2) root.xMin = newXMin
        if(Math.abs(root.xMax - newXMax) > 1e-2) root.xMax = newXMax
        if(Math.abs(root.yMin - newYMin) > 1e-2) root.yMin = newYMin
        if(Math.abs(root.yMax - newYMax) > 1e-2) root.yMax = newYMax
    }

    ChartView {
        id: chart
        anchors.fill: parent
        theme: ChartView.ChartThemeDark
        backgroundColor: root.color
        antialiasing: true
        legend.visible: true
        title: "A plot"
        titleColor: "black"

        ValueAxis {
            id: axisX
            tickCount: 3
            min: root.xMin
            max: root.xMax
            titleText: "y"
            color: "white"
            labelsColor: "black"
        }

        ValueAxis {
            id: axisY
            tickCount: 3
            min: root.yMin
            max: root.yMax
            titleText: "x"
            color: "white"
            labelsColor: "black"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: console.log("Mouse pos: ", mouse.x, ", ", mouse.y)
        }
    }
}
