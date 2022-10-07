//  ChartData.swift

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

import Foundation
import Charts
import CombustionBLE

/// Helper functions for generating chart data for a device
struct ChartData {
    
    /// Generates mulit-line chart data for the specified device
    static func generate(probe: Probe, celsius: Bool) -> [LineChartDataSet] {
        let dataPoints = generateDataPoints(probe: probe, celsius: celsius)
        
        let data : [LineChartDataSet] = [
            LineChartDataSet(entries: dataPoints.t1, label: "T1"),
            LineChartDataSet(entries: dataPoints.t2, label: "T2"),
            LineChartDataSet(entries: dataPoints.t3, label: "T3"),
            LineChartDataSet(entries: dataPoints.t4, label: "T4"),
            LineChartDataSet(entries: dataPoints.t5, label: "T5"),
            LineChartDataSet(entries: dataPoints.t6, label: "T6"),
            LineChartDataSet(entries: dataPoints.t7, label: "T7"),
            LineChartDataSet(entries: dataPoints.t8, label: "T8"),
        ]
        
        return data
    }
    
    /// Struct that organizes each temperature sensor's data points
    private struct ChartDataPoints {
        var t1 = [ChartDataEntry]()
        var t2 = [ChartDataEntry]()
        var t3 = [ChartDataEntry]()
        var t4 = [ChartDataEntry]()
        var t5 = [ChartDataEntry]()
        var t6 = [ChartDataEntry]()
        var t7 = [ChartDataEntry]()
        var t8 = [ChartDataEntry]()
    }
    
    /// Generates arrays of line chart data points
    private static func generateDataPoints(probe: Probe, celsius: Bool) -> ChartDataPoints {
        var dataPoints = ChartDataPoints()
        
        for log in probe.temperatureLogs {
            // Skip log if start time has not been set
            guard let sessionStartTime = log.startTime else { continue }
            
            for dp in log.dataPoints {
                let t1 = celsius ? dp.temperatures.values[0] : fahrenheit(celsius: dp.temperatures.values[0])
                let t2 = celsius ? dp.temperatures.values[1] : fahrenheit(celsius: dp.temperatures.values[1])
                let t3 = celsius ? dp.temperatures.values[2] : fahrenheit(celsius: dp.temperatures.values[2])
                let t4 = celsius ? dp.temperatures.values[3] : fahrenheit(celsius: dp.temperatures.values[3])
                let t5 = celsius ? dp.temperatures.values[4] : fahrenheit(celsius: dp.temperatures.values[4])
                let t6 = celsius ? dp.temperatures.values[5] : fahrenheit(celsius: dp.temperatures.values[5])
                let t7 = celsius ? dp.temperatures.values[6] : fahrenheit(celsius: dp.temperatures.values[6])
                let t8 = celsius ? dp.temperatures.values[7] : fahrenheit(celsius: dp.temperatures.values[7])
                
                // X value of graph is seconds since 1970
                let secondDiff = Int(dp.sequenceNum) * Int(log.sessionInformation.samplePeriod) / 1000
                let dataTimeStamp = Calendar.current.date(byAdding: .second, value: secondDiff, to: sessionStartTime)
                let xValue = dataTimeStamp?.timeIntervalSince1970 ?? 0.0
                
                dataPoints.t1.append(ChartDataEntry(x: xValue, y: t1))
                dataPoints.t2.append(ChartDataEntry(x: xValue, y: t2))
                dataPoints.t3.append(ChartDataEntry(x: xValue, y: t3))
                dataPoints.t4.append(ChartDataEntry(x: xValue, y: t4))
                dataPoints.t5.append(ChartDataEntry(x: xValue, y: t5))
                dataPoints.t6.append(ChartDataEntry(x: xValue, y: t6))
                dataPoints.t7.append(ChartDataEntry(x: xValue, y: t7))
                dataPoints.t8.append(ChartDataEntry(x: xValue, y: t8))
            }
        }
        
        return dataPoints
    }
}
