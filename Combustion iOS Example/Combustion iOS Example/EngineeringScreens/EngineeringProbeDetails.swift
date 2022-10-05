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
    
    @AppStorage("displayCelsius") private var displayCelsius = true
    
    @State private var showingSetPrediction = false
    @State private var showingFirmwareUpgrade = false
    @State private var showingIDSelection = false
    @State private var showingColorSelection = false
    @State private var showingSetColorFailAlert = false
    @State private var showingSetIDFailAlert = false
    @State private var showingShareSheet = false
    @State private var showingShareFailAlert = false
    
    @State private var predictionExpanded = true
    @State private var instantReadExpanded = true
    @State private var temperatureExpanded = true
    
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
                if(probe.isDFURunning()) {
                    dfuView()
                }
                else {
                    predictionSection()
                    instantReadSection()
                    temperatureSection()
                    sensorsSection()
                    recordsSection()
                    detailsSection()
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
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
                .disabled(probe.isDFURunning() ||
                          !probe.isConnectable && probe.connectionState != .connected)
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
        .sheet(isPresented: $showingFirmwareUpgrade) {
            FirmwareUpgradeScreen(probe: probe)
        }
        .sheet(isPresented: $showingSetPrediction) {
            SetPredictionScreen(probe: probe)
        }
        .alert("Failed to export CSV", isPresented: $showingShareFailAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    @ViewBuilder
    func dfuView() -> some View {
        Row(key: "State", value: probe.dfuState?.description ?? "--")
            
        if let uploadProgress = probe.dfuUploadProgress, probe.dfuState == .uploading {
            Row(key: "Upload step", value: "\(uploadProgress.part) of \(uploadProgress.totalParts)")
            Row(key: "Percent complete", value: "\(uploadProgress.progress)")
        }
        
        if(probe.dfuState == .aborted) {
            Row(key: "Error", value: probe.dfuError?.message ?? "--")
        }
    }
    
    @ViewBuilder
    func predictionSection() -> some View {
        Section() {
            DisclosureGroup("Prediction", isExpanded: $predictionExpanded) {
                VStack {
                    if let predictionStatus = probe.predictionStatus {
                        HStack {
                            Spacer()
                            Text(timeString(seconds: Double(predictionStatus.predictionValueSeconds)))
                                .font(.system(size: 32))
                            Spacer()
                        }
                        
                        Row(key: "Cooking State", value: "\(predictionStatus.predictionState)")
                        Row(key: "Cooking to", value: temperatureString(valueCelsius: predictionStatus.predictionSetPointTemperature))
                        let progressPrecent = Int((predictionStatus.estimatedCoreTemperature - predictionStatus.heatStartTemperature) / (predictionStatus.predictionSetPointTemperature - predictionStatus.heatStartTemperature) * 100.0)
                        Row(key: "Cook Progress", value: "\(progressPrecent) %")
                        
                        HStack() {
                            Spacer()
                            Button("Enter Removal Temperature") {
                                showingSetPrediction = true
                            }
                            .disabled(probe.connectionState != .connected)
                            Spacer()
                        }
                    } else {
                        HStack {
                            Spacer()
                            VStack {
                                ProgressView()
                                Text("Please connect...")
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func instantReadSection() -> some View {
        Section() {
            DisclosureGroup("Instant Read", isExpanded: $instantReadExpanded) {
                HStack {
                    Spacer()
                    
                    Text(temperatureString(valueCelsius: probe.instantReadTemperature ))
                        .font(.system(size: 32))
                    
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    func temperatureSection() -> some View {
        Section() {
            DisclosureGroup("Temperatures", isExpanded: $temperatureExpanded) {
                HStack {
                    VStack {
                        Text("Core")
                        Text(temperatureString(valueCelsius: probe.coreTemperature))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Surface")
                        Text(temperatureString(valueCelsius: probe.surfaceTemperature))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Ambient")
                        Text(temperatureString(valueCelsius: probe.ambientTemperature))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func detailsSection() -> some View {
        Section() {
            DisclosureGroup("Details") {
                VStack {
                    Group {
                        Row(key: "Connection", value: "\(probe.connectionState)")
                        Row(key: "Connectable", value: "\(probe.isConnectable)")
                        Row(key: "Battery status", value: "\(probe.batteryStatus)")
                        Row(key: "Signal strength", value: "\(probe.rssi)")
                        Divider()
                    }
                    
                    Group {
                        if let sensors = probe.virtualSensors {
                            Row(key: "Core Sensor", value: "\(sensors.virtualCore)")
                            Row(key: "Surface Sensor", value: "\(sensors.virtualSurface)")
                            Row(key: "Ambient Sensor", value: "\(sensors.virtualAmbient)")
                        } else {
                            Row(key: "Core Sensor", value: "--")
                            Row(key: "Surface Sensor", value: "--")
                            Row(key: "Ambient Sensor", value: "--")
                        }
                        
                        Divider()
                    }
                    
                    Group {
                        Row(key: "ID", value: "\(probe.id)")
                        Row(key: "Color", value: "\(probe.color)")
                        
                        Divider()
                    }
                    
                    Group {
                        if let predictionStatus = probe.predictionStatus {
                            Row(key: "Prediction Mode", value: "\(predictionStatus.predictionMode)")
                            Row(key: "Prediction Type", value: "\(predictionStatus.predictionType)")
                            Row(key: "Heat start", value: temperatureString(valueCelsius: predictionStatus.heatStartTemperature))
                            Row(key: "Estimated Core", value: temperatureString(valueCelsius: predictionStatus.estimatedCoreTemperature))
                        } else {
                            Row(key: "Prediction Mode", value: "--")
                            Row(key: "Prediction Type", value: "--")
                            Row(key: "Heat start", value: "--")
                            Row(key: "Estimated Core", value: "--")
                        }

                        Divider()
                    }

                    Group {
                        Row(key: "Firmware", value: "\(probe.firmareVersion ?? "—")")
                        Row(key: "Hardware rev", value: "\(probe.hardwareRevision ?? "—")")
                        Row(key: "MAC", value: "\(probe.macAddressString)")
                        
                        Divider()
                    }
                    
                    actionsGroup()
                }
            }
        }
    }
    
    @ViewBuilder
    func recordsSection() -> some View {
        Section() {
            DisclosureGroup("Records") {
                if probe.connectionState == .connected,
                   let min = probe.minSequenceNumber, let max = probe.maxSequenceNumber {
                    Row(key: "Range on probe", value: "\(min) : \(max)")
                }
                else {
                    Row(key: "Range on probe", value: "-- : --")
                }
                
                if probe.connectionState == .disconnected {
                    Row(key: "Records downloaded", value: "-")
                }
                else if probe.logsUpToDate {
                    Row(key: "Downloading records", value: "Complete")
                }
                else {
                    Row(key: "Downloading records", value: "In progress")
                }
                
                ForEach(probe.temperatureLogs) { log in
                    if let startTime = log.startTime {
                        Row(key: "Session (\(sessionDateFormatter.string(from: startTime)))", value: "\(log.dataPoints.count)")
                    }
                    else {
                        Row(key: "Session (--:--:--)", value: "\(log.dataPoints.count)")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func sensorsSection() -> some View {
        Section() {
            DisclosureGroup("Sensors") {
                HStack {
                    VStack {
                        Text("T1")
                        Text(temperatureString(valueCelsius: probe.currentTemperatures?.values[0]))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("T2")
                        Text(temperatureString(valueCelsius: probe.currentTemperatures?.values[1]))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("T3")
                        Text(temperatureString(valueCelsius: probe.currentTemperatures?.values[2]))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("T4")
                        Text(temperatureString(valueCelsius: probe.currentTemperatures?.values[3]))
                    }
                }
                
                
                HStack {
                    VStack {
                        Text("T5")
                        Text(temperatureString(valueCelsius: probe.currentTemperatures?.values[4]))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("T6")
                        Text(temperatureString(valueCelsius: probe.currentTemperatures?.values[5]))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("T7")
                        Text(temperatureString(valueCelsius: probe.currentTemperatures?.values[6]))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("T8")
                        Text(temperatureString(valueCelsius: probe.currentTemperatures?.values[7]))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func actionsGroup() -> some View {
        Group {
            HStack() {
                Spacer()
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
                Spacer()
            }
            
            HStack() {
                Spacer()
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
                Spacer()
            }
            
            HStack() {
                Spacer()
                Button("Firmware Upgrade") {
                    showingFirmwareUpgrade = true
                }
                .disabled(probe.connectionState != .connected)
                Spacer()
            }
        }
    }
    
    private func temperatureString(valueCelsius: Double?) -> String {
        guard let valueCelsius = valueCelsius else { return  "--" }
        
        let coreValue = displayCelsius ? valueCelsius : fahrenheit(celsius: valueCelsius)
        return String(format: "%.01f", coreValue)
    }
    
    private func timeString(seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        
        return formatter.string(from: seconds) ?? ""
    }
    
    private func shareRecords() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let appVersion = "Engineering \(String(describing: version ?? "--"))"
        if let url = CSV.createCsvFile(probe: probe, appVersion: appVersion) {
            csvUrl = url
            showingShareSheet = true
        }
        else {
            showingShareFailAlert = true
        }
    }
}

struct EngineeringProbeDetails_Previews: PreviewProvider {
    static var previews: some View {
        EngineeringProbeDetails(probe: SimulatedProbe())
    }
}
