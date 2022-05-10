//
//  CSV.swift
//  Combustion_iOS
//
//  Created by Jason Machacek on 10/22/21.
//

import Foundation
import CombustionBLE

struct CSV {
    
    /// Helper function that generates a CSV representation of probe data.
    static func probeDataToCsv(probe: Probe, date: Date = Date()) -> String {
        var output = [String]()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        
        output.append("Combustion Inc. Probe Data")
        output.append("Probe S/N: \(String(format: "%4X", probe.serialNumber))")
        output.append("Probe FW version: \(probe.firmareVersion ?? "??")")
        output.append("Probe HW revision: \(probe.hardwareRevision ?? "??")")
        output.append("\(dateString)")
        output.append("")
        
        // TODO app version to this header
        
        // Header
        output.append("SequenceNumber,T1,T2,T3,T4,T5,T6,T7,T8")
        
        // Add temperature data points
        for dp in probe.temperatureLog.dataPoints {
            output.append(String(format: "%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f",
                                 dp.sequenceNum,
                                 dp.temperatures.values[0], dp.temperatures.values[1],
                                 dp.temperatures.values[2], dp.temperatures.values[3],
                                 dp.temperatures.values[4], dp.temperatures.values[5],
                                 dp.temperatures.values[6], dp.temperatures.values[7]))
        }
        
        
        return output.joined(separator: "\n")
    }
    
    /// Creates a CSV file for export.
    /// - param probe: Probe for which to create the file
    /// - returns: URL of file
    static func createCsvFile(probe: Probe) -> URL? {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH_mm_ss"
        let dateString = dateFormatter.string(from: date)
        
        let filename = "Probe Data - \(String(format: "%4X", probe.serialNumber)) - \(dateString).csv"
        
        // Generate the CSV
        let csv = probeDataToCsv(probe: probe, date: date)
        
        // Create the temporary file
        let filePath = NSTemporaryDirectory() + "/" + filename;
        
        let csvURL = URL(fileURLWithPath: filePath)
        
        do {
            try csv.write(to: csvURL, atomically: true, encoding: String.Encoding.utf8)
            
        } catch {
            // Failed to write file, return nothing
            return nil
        }
        
        return csvURL
    }
    
    
    /// Cleans up the temporary CSV file at location
    func cleanUpCsvFile(url: URL) {
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: url.absoluteString) {
                try fileManager.removeItem(atPath: url.absoluteString)
            }
        } catch {
            // Couldn't delete, don't worry about it
        }
    }
    
}
