//  ChartView.swift

/*--
MIT License

Copyright (c) 2022 Combustion Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--*/

import SwiftUI
import Charts

class XAxisDateFormatter : AxisValueFormatter {
    let dateFormatter = DateFormatter()
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}

struct ChartView: UIViewRepresentable {
    var dataSets: [LineChartDataSet]
    
    var visible : Bool
    
    let dataSetColors : [NSUIColor] = [
        .green,
        .cyan,
        .gray,
        .blue,
        .orange,
        .purple,
        .magenta,
        .red
    ]
    
    let xAxisDateFormatter = XAxisDateFormatter()
    
    func makeUIView(context: Context) -> LineChartView {
        let chart = LineChartView()
        chart.data = addData()
        chart.xAxis.valueFormatter = xAxisDateFormatter
        return chart
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        //when data changes, chart update is required
        if(self.visible) {
            uiView.data = addData()
        }
    }
    
    func addData() -> LineChartData {
        let data = LineChartData()
        var count = 0
        for dataSet in dataSets {
            if count < dataSetColors.count {
                dataSet.colors = [dataSetColors[count]] as [NSUIColor]
            }
            dataSet.drawValuesEnabled = false
            dataSet.drawCirclesEnabled = false
            dataSet.drawCircleHoleEnabled = false
            dataSet.lineWidth = 1.5
            data.dataSets.append(dataSet)
            count += 1
        }
        return data
    }
    
    typealias UIViewType = LineChartView
}

struct Line_Previews: PreviewProvider {
    static var previews: some View {
        let data : [LineChartDataSet] = [
            LineChartDataSet(entries: [
                ChartDataEntry(x: 1.0, y: 10.0),
                ChartDataEntry(x: 2.0, y: 25.0),
                ChartDataEntry(x: 3.0, y: 35.0),
                ChartDataEntry(x: 4.0, y: 40.0),
                ChartDataEntry(x: 5.0, y: 55.0)
            ], label: "T1"),
            LineChartDataSet(entries: [
                ChartDataEntry(x: 1.0, y: 10.0),
                ChartDataEntry(x: 2.0, y: 20.0),
                ChartDataEntry(x: 3.0, y: 25.0),
                ChartDataEntry(x: 4.0, y: 30.0),
                ChartDataEntry(x: 5.0, y: 40.0)
            ], label: "T2"),
            LineChartDataSet(entries: [
                ChartDataEntry(x: 1.0, y: 10.0),
                ChartDataEntry(x: 2.0, y: 22.0),
                ChartDataEntry(x: 3.0, y: 30.0),
                ChartDataEntry(x: 4.0, y: 45.0),
                ChartDataEntry(x: 5.0, y: 60.0)
            ], label: "T3"),
            LineChartDataSet(entries: [
                ChartDataEntry(x: 1.0, y: 10.0),
                ChartDataEntry(x: 2.0, y: 23.0),
                ChartDataEntry(x: 3.0, y: 33.0),
                ChartDataEntry(x: 4.0, y: 41.0),
                ChartDataEntry(x: 5.0, y: 45.0)
            ], label: "T4"),
            LineChartDataSet(entries: [
                ChartDataEntry(x: 1.0, y: 10.0),
                ChartDataEntry(x: 2.0, y: 30.0),
                ChartDataEntry(x: 3.0, y: 55.0),
                ChartDataEntry(x: 4.0, y: 75.0),
                ChartDataEntry(x: 5.0, y: 105.0)
            ], label: "T5"),
            LineChartDataSet(entries: [
                ChartDataEntry(x: 1.0, y: 10.0),
                ChartDataEntry(x: 2.0, y: 25.0),
                ChartDataEntry(x: 3.0, y: 45.0),
                ChartDataEntry(x: 4.0, y: 70.0),
                ChartDataEntry(x: 5.0, y: 90.0)
            ], label: "T6"),
            LineChartDataSet(entries: [
                ChartDataEntry(x: 1.0, y: 10.0),
                ChartDataEntry(x: 2.0, y: 30.0),
                ChartDataEntry(x: 3.0, y: 50.0),
                ChartDataEntry(x: 4.0, y: 80.0),
                ChartDataEntry(x: 5.0, y: 100.0)
            ], label: "T7"),
            LineChartDataSet(entries: [
                ChartDataEntry(x: 1.0, y: 10.0),
                ChartDataEntry(x: 2.0, y: 40.0),
                ChartDataEntry(x: 3.0, y: 60.0),
                ChartDataEntry(x: 4.0, y: 85.0),
                ChartDataEntry(x: 5.0, y: 110.0)
            ], label: "T8"),
        ]
        
        Group {
            ChartView(dataSets: data, visible: true)
            ChartView(dataSets: data, visible: true)
                .preferredColorScheme(.dark)
        }
    }
}
