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
    
    @AppStorage("displayCelsius") private var displayCelsius = true

    var body: some View {
        VStack {
            HStack {
                Text(displayCelsius ? "°C" : "°F")
                
                Spacer()
                
                Text(probe.name)
                    .font(.title)
                
                Spacer()
            }
            
            HStack {
                Spacer()
                
                VStack {
                    Text("Instant Read")
                    Text(temperatureString(valueCelsius: probe.instantReadTemperature))
                    Text("Surface")
                    if let virutalTemps = probe.virtualTemperatures {
                        Text(temperatureString(valueCelsius: virutalTemps.surfaceTemperature))
                    }
                    else {
                        Text("--")
                    }

                }
                
                Spacer()
                
                VStack {
                    Text("Core")
                    if let virutalTemps = probe.virtualTemperatures {
                        Text(temperatureString(valueCelsius: virutalTemps.coreTemperature))
                    }
                    else {
                        Text("--")
                    }
                    Text("Ambient")
                    if let virutalTemps = probe.virtualTemperatures {
                        Text(temperatureString(valueCelsius: virutalTemps.ambientTemperature))
                    }
                    else {
                        Text("--")
                    }
                }
                
                Spacer()
            }
            .padding(4)
            
            Row(title: "Battery status", value: "\(probe.batteryStatus)")
        }
    }
    
    private func temperatureString(valueCelsius: Double?) -> String {
        guard let valueCelsius = valueCelsius else { return  "--" }
        
        let coreValue = displayCelsius ? valueCelsius : fahrenheit(celsius: valueCelsius)
        return String(format: "%.01f", coreValue)
    }
}

struct EngineeringProbeRow_Previews: PreviewProvider {
    static var previews: some View {
        EngineeringProbeRow(probe: SimulatedProbe())
    }
}
