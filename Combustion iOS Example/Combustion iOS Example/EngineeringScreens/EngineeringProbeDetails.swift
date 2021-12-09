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
    @ObservedObject var deviceManager = DeviceManager.shared
    let deviceKey: String

    var body: some View {
        VStack(alignment: .leading) {
            if let device = deviceManager.devices[deviceKey] {
                Group {
                    Text("Serial = \(device.name)")
                    Text("MAC = \(device.macAddressString)")
                    Text("RSSI   = \(device.rssi)")
                    let connected = device.connectionState == .connected
                    Text("Connected = \(connected.description)")
                    if let status = device.status {
                        Text("Records = \(status.minSequenceNumber) : \(status.maxSequenceNumber)")
                    }
                    else {
                        Text("Records = ?? : ??")
                    }
                    
                    Text("Logged records: \(device.temperatureLog.dataPoints.count)")

                    if let temps = device.currentTemperatures {
                        let tempStrings = temps.values.map { String(format: "%.02f", $0) }
                        Text("\(tempStrings[0]), \(tempStrings[1]), \(tempStrings[2]), \(tempStrings[3])")
                        Text("\(tempStrings[4]), \(tempStrings[5]), \(tempStrings[6]), \(tempStrings[7])")
                    }
                }
           
                Spacer()
                
                Button(action: {
                    if var dev = deviceManager.devices[deviceKey] {
                        if dev.connectionState == .connected {
                            dev.disconnect()
                        }
                        else {
                            dev.connect()
                        }
                    }
                }){
                    let title = device.connectionState == .connected ? "Disconnect" : "Connect"
                    Text(title).font(.title)
                }
                     
                Spacer()
                
                Button(action: shareRecords) {
                    Image(systemName: "square.and.arrow.up")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 36, height: 36)
                }
            
            }
            
            Spacer(minLength: 400)
        }
        .onDisappear {
            if var dev = deviceManager.devices[deviceKey], dev.connectionState == .connected {
                dev.disconnect()
            }
        }
    }
    
    func shareRecords() {
        guard let device = deviceManager.devices[deviceKey] else { return }
        // Generate the CSV file
        guard let csvUrl = CSV.createCsvFile(device: device) else { return }
        let activityVC = UIActivityViewController(activityItems: [csvUrl], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        // TODO clean up temp file on completion
    }
}
