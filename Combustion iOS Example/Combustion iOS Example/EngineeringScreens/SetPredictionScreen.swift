//  SetPredictionScreen.swift

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
import Combine
import SwiftUI
import CombustionBLE

struct SetPredictionScreen: View {
    @ObservedObject var probe: Probe
    
    @AppStorage("displayCelsius") private var displayCelsius = true
    
    @State private var input = ""
    @FocusState private var textIsFocused: Bool
    @State private var showingBeginFailAlert = false
    @State private var disableInputs = false
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack() {
            ZStack() {
                HStack() {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel")
                            .foregroundColor(.red)
                    })
                    Spacer()
                }
                Text("Cook to")
                    .font(.system(size: 24))
            }
            .padding(16)
            
            Spacer()
            
            HStack(alignment: .top) {
                TextField("0", text: $input)
                    .keyboardType(.decimalPad)
                    .fixedSize()
                    .font(.system(size: 48))
                    .focused($textIsFocused)
                    .disabled(disableInputs)
                    .onAppear {
                        // Set inital value
                        input = displayCelsius ? "70" : "160"
                        
                        // After a small delay, set focus on textfield
                        let delay = UIDevice.current.userInterfaceIdiom == .pad ? 1.0 : 0.1
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            textIsFocused = true
                        }
                    }
                    .onReceive(Just(input)) { newValue in
                        let allowedCharacters = "0123456789"
                        let filtered = newValue.filter { allowedCharacters.contains($0) }
                        if filtered != newValue {
                            self.input = filtered
                        }
                    }
                
                Text(displayCelsius ? "°C" : "°F")
                    .font(.system(size: 24))
                    .padding(.top, 8)
            }
            
            Spacer()
            
            Button(action: {
                disableInputs = true
                
                let value: Int = Int(input) ?? 0
                let temperatureCelsius = displayCelsius ? Double(value) : celsius(fahrenheit: Double(value))
                
                DeviceManager.shared.setRemovalPrediction(probe, removalTemperatureC: temperatureCelsius) { success in
                    if(!success) {
                        disableInputs = false
                        showingBeginFailAlert = true
                    }
                    else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
            }, label: {
                Text("Begin Prediction")
            })
            .disabled(disableInputs)
            
            Spacer()
            
        }
        .alert("Failed to begin prediction", isPresented: $showingBeginFailAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
}

struct SetPredictionScreen_Previews: PreviewProvider {
    static var previews: some View {
        SetPredictionScreen(probe: SimulatedProbe())
    }
}
