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
    @State private var showingSetColorFailAlert = false
    @State private var showingSetIDFailAlert = false
    @State private var showingShareSheet = false
    @State private var showingShareFailAlert = false
    
    @State private var csvUrl: URL?
    
    let sessionDateFormatter: DateFormatter
        
    init(probe: Probe) {
        self.probe = probe
        sessionDateFormatter = DateFormatter()
        sessionDateFormatter.dateFormat = "HH:mm:ss"
    }

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
                    makeRow(key: "Battery", data: "\(probe.batteryStatus)")
                    makeRow(key: "Firmware", data: "\(probe.firmareVersion ?? "—")")
                    makeRow(key: "Hardware rev", data: "\(probe.hardwareRevision ?? "—")")
                }
                Section(header: Text("Records")) {
                    if probe.connectionState == .connected,
                        let min = probe.minSequenceNumber, let max = probe.maxSequenceNumber {
                        makeRow(key: "Range on probe", data: "\(min) : \(max)")
                    }
                    else {
                        makeRow(key: "Range on probe", data: "-- : --")
                    }
                    
                    if probe.connectionState == .disconnected {
                        makeRow(key: "Records downloaded", data: "-")
                    }
                    else if probe.logsUpToDate {
                        makeRow(key: "Downloading records", data: "Complete")
                    }
                    else {
                        makeRow(key: "Downloading records", data: "In progress")
                    }
                }
                
                Section(header: Text("Sessions")) {
                    ForEach(probe.temperatureLogs) { log in
                        
                        if let startTime = log.startTime {
                            makeRow(key: "ID: \(log.id) (\(sessionDateFormatter.string(from: startTime)))", data: "\(log.dataPoints.count)")
                        }
                        else {
                            makeRow(key: "ID: \(log.id) (--:--:--)", data: "\(log.dataPoints.count)")
                        }
                    }
                }
                
                Section(header: Text("Sensors")) {
                    if let instantReadTemperature = probe.instantReadTemperature {
                        makeRow(key: "Instant Read", data: String(format: "%.02f", instantReadTemperature))
                    }
                    else {
                        makeRow(key: "Instant Read", data: "--")
                    }
                
                    if let temps = probe.currentTemperatures {
                        let tempStrings = temps.values.map { String(format: "%.02f", $0) }

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
                            DeviceManager.shared.setProbeID(probe, id: probeID, completionHandler: { success in
                                if(!success) {
                                    showingSetIDFailAlert = true
                                }
                            })
                        }
                    }
                }
                .alert("Failed to set ID", isPresented: $showingSetIDFailAlert) {
                    Button("OK", role: .cancel) { }
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
                            DeviceManager.shared.setProbeColor(probe, color: color, completionHandler: { (success) in
                                if(!success) {
                                    showingSetColorFailAlert = true
                                }
                            })
                        }
                    }
                }
                .alert("Failed to set color", isPresented: $showingSetColorFailAlert) {
                    Button("OK", role: .cancel) { }
                }
                .disabled(probe.connectionState != .connected)
            }
            ToolbarItem(placement: .navigation) {
                Button(action: shareRecords, label: {
                    Image(systemName: "square.and.arrow.up")
                })
                .disabled(!probe.logsUpToDate)
                .opacity(probe.logsUpToDate ? 1.0 : 0.3)
            }
        }
        .navigationTitle("\(probe.name)")
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [csvUrl as Any])
        }
        .alert("Failed to export CSV", isPresented: $showingShareFailAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func shareRecords() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let appVersion = "Engineering \(String(describing: version))"
        if let url = CSV.createCsvFile(probe: probe, appVersion: appVersion) {
            csvUrl = url
            showingShareSheet = true
        }
        else {
            showingShareFailAlert = true
        }
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
