//  EngineeringProbeDetails.swift

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

struct EngineeringProbeDetails: View {
    @ObservedObject var probe: Probe
    
    @State private var showingIDSelection = false
    @State private var showingColorSelection = false

    var body: some View {
        VStack() {
            List {
                Section(header: Text("Probe")) {
                    
                    if (probe.connectionState == .connected) {
                        makeRow(key: "Connection", data: "\(probe.connectionState)", image: Image(systemName: "circle.fill"), color: Color.green)
                    } else if (probe.connectionState == .connecting) {
                        makeRow(key: "Connection", data: "\(probe.connectionState)", image: Image(systemName: "circle.fill"), color: Color.yellow)
                    } else if (probe.connectionState == .disconnected) {
                        makeRow(key: "Connection", data: "\(probe.connectionState)", image: Image(systemName: "circle"), color: Color.gray)
                    } else if (probe.connectionState == .failed) {
                        makeRow(key: "Connection", data: "\(probe.connectionState)", image: Image(systemName: "exclamationmark.circle.fill"), color: Color.red)
                    }

                    makeRow(key: "Serial", data: probe.name)
                    makeRow(key: "MAC", data: "\(probe.macAddressString)")
                    makeRow(key: "ID", data: "\(probe.id)")
                    makeRow(key: "Color", data: "\(probe.color)")
                    makeRow(key: "RSSI", data: "\(probe.rssi)")
                    makeRow(key: "Firmware", data: "\(probe.firmareVersion ?? "—")")

                    if let min = probe.minSequenceNumber, let max = probe.maxSequenceNumber {
                        makeRow(key: "Records", data: "\(min) : \(max)")
                    }
                    else {
                        makeRow(key: "Records", data: "-- : --")
                    }
                    makeRow(key: "Records logged", data: "\(probe.temperatureLog.dataPoints.count)")
                }
                if let temps = probe.currentTemperatures {
                    let tempStrings = temps.values.map { String(format: "%.02f", $0) }
                    Section(header: Text("Sensors")) {
                        ForEach(Array(tempStrings.enumerated()), id: \.offset) { index, element in
                            makeRow(key: "T\(index + 1)", data: element)
                        }
                    }
                }
            }.listStyle(InsetGroupedListStyle())
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    if probe.connectionState == .connected {
                        probe.disconnect()
                    }
                    else {
                        probe.connect()
                    }
                }, label: {
                    let state = probe.connectionState == .connected ? "Disconnect" : "Connect"
                    Text(state)
                })
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Set ID") {
                    showingIDSelection = true
                }
                .confirmationDialog("Select Probe ID", isPresented: $showingIDSelection, titleVisibility: .visible) {
                    ForEach(ProbeID.allCases, id: \.self) { probeID in
                        Button(String(describing: probeID)) {
                            DeviceManager.shared.setProbeID(probe, id: probeID)
                        }
                    }
                }
                .disabled(probe.connectionState != .connected)
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Set Color") {
                    showingColorSelection = true
                }
                .confirmationDialog("Select Color", isPresented: $showingColorSelection, titleVisibility: .visible) {
                    ForEach(ProbeColor.allCases, id: \.self) { color in
                        Button(String(describing: color)) {
                            DeviceManager.shared.setProbeColor(probe, color: color)
                        }
                    }
                }
                .disabled(probe.connectionState != .connected)
            }
            ToolbarItem(placement: .navigation) {
                Button(action: shareRecords, label: {
                    Image(systemName: "square.and.arrow.up")
                })
            }
        }
        .navigationTitle("\(probe.name)")
    }
    
    func shareRecords() {
        // Generate the CSV file
        guard let csvUrl = CSV.createCsvFile(probe: probe) else { return }
        let activityVC = UIActivityViewController(activityItems: [csvUrl], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        // TODO clean up temp file on completion
    }

    func makeRow(key:String, data:String) -> some View {
        let row = HStack() {
            Text(key)
            Spacer()
            Text(data)
                .font(.system(.body, design: .monospaced))
        }
        return row
    }

    func makeRow(key:String, data:String, image:Image, color:Color) -> some View {
        let row = HStack() {
            Text(key)
            Spacer()
            Text(capFirstLetter(string:data))
                .font(.system(.body, design: .monospaced))
            image.foregroundColor(color)
        }
        return row
    }
    
    func capFirstLetter(string:String) -> String {
        var text = string
        let cap = "\(text.remove(at: text.startIndex))"
        text = "\(cap.capitalized)\(text)"
        return text
    }
}
