//  FirmwareUpgradeScreen.swift

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

import Foundation
import SwiftUI
import CombustionBLE

struct FirmwareUpgradeScreen: View {
    @ObservedObject var probe: Probe
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedFile: URL?
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack() {
            List {
                makeRow(key: "Current firmware", data: probe.firmareVersion ?? "--")
                makeRow(key: "OTA file", data: selectedFile?.lastPathComponent ?? "--")
                
                HStack() {
                    Spacer()
                    Button(action: {
                        showingFilePicker = true
                    }, label: {
                        Text("Select file")
                    })
                    Spacer()
                }
                
                HStack() {
                    Spacer()
                    Button(action: {
                        if let dfuFileURL = selectedFile {
                            if(probe.runSoftwareUpgrade(dfuFile: dfuFileURL)) {
                                presentationMode.wrappedValue.dismiss()
                            }
                            else {
                                print("Invalid file")
                            }
                        }
                    }, label: {
                        Text("Run firmware update")
                    })
                    .disabled(selectedFile == nil)
                    Spacer()
                }
            }.listStyle(InsetGroupedListStyle())
        }
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(selectedFile: $selectedFile)
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
}

