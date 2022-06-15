//  EngineeringProbeRow.swift

/*--
MIT License

Copyright (c) 2021 Combustion Inc.

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
import CombustionBLE

struct EngineeringProbeRow: View {
    @ObservedObject var probe: Probe

    var body: some View {
        VStack() {
            // overlays the connection status icon and the serial/mac/rssi
            ZStack {
                HStack {
                    Spacer()
                    if (probe.connectionState == .connected) {
                        Image(systemName: "circle.fill").foregroundColor(Color.green)
                    } else if (probe.connectionState == .connecting) {
                        Image(systemName: "circle.fill").foregroundColor(Color.yellow)
                    } else if (probe.connectionState == .disconnected) {
                        Image(systemName: "circle").foregroundColor(Color.gray)
                    } else if (probe.connectionState == .failed) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundColor(Color.red)
                    }
                }.padding(.trailing)
                VStack(alignment: .leading, spacing: 2) {
                    makeRow(key: "Serial", data: probe.name)
                    makeRow(key: "MAC", data: probe.macAddressString)
                    makeRow(key: "ID", data: "\(probe.id)")
                    makeRow(key: "Color", data: "\(probe.color)")
                    makeRow(key: "RSSI", data: "\(probe.rssi)")
                    makeRow(key: "Battery", data: "\(probe.batteryStatus)")
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Divider()
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                if let instantReadTemperature = probe.instantReadTemperature {
                    makeRow(key: "Instant Read", data: String(format: "%.02f", instantReadTemperature))
                }
                else {
                    makeRow(key: "Instant Read", data: "--")
                }
                
                if let temps = probe.currentTemperatures {
                    Divider()
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    
                    let tempStrings = temps.values.map { String(format: "%.02f", $0) }
                    ForEach(tempStrings.indices) {i in
                        makeRow(key: "T\(i + 1)", data: "\(tempStrings[i])")
                    }
                }
                
            }
            
        }.padding(.vertical, 8)
    }

    func makeRow(key:String, data:String) -> some View {
        let row = HStack() {
            Text(key)
                .frame(minWidth: 60, alignment: .leading)
            Text(data)
                .font(.system(.body, design: .monospaced))
                .frame(alignment: .leading)
            Spacer()
        }
        return row
    }
}
