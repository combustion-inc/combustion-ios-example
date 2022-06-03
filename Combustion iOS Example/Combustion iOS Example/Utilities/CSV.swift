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
    private static func probeDataToCsv(probe: Probe, date: Date = Date()) -> String {
        var output = [String]()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: date)
        
        output.append("Combustion Inc. Probe Data")
        output.append("CSV version: 2")
        output.append("Probe S/N: \(String(format: "%4X", probe.serialNumber))")
        output.append("Probe FW version: \(probe.firmareVersion ?? "??")")
        output.append("Probe HW revision: \(probe.hardwareRevision ?? "??")")
        output.append("\(dateString)")
        output.append("")
        
        // TODO add app version to this header
        
        // Header
        output.append("Timestamp,SessionID,SequenceNumber,T1,T2,T3,T4,T5,T6,T7,T8")
        
        // Add temperature data points
        if let firstSessionStart = probe.temperatureLogs.first?.startTime?.timeIntervalSince1970 {
            for session in probe.temperatureLogs {
                for dataPoint in session.dataPoints {
                    
                    // Calculate timestamp for current data point
                    var timeStamp = 0
                    if let currentSessionStart = session.startTime?.timeIntervalSince1970 {
                        // Number of seconds between first session start time and current start time
                        let sessionStartTimeDiff = Int(currentSessionStart - firstSessionStart)
                        
                        // Number of seconds beteen current data point and session start time
                        let dataPointSeconds = Int(dataPoint.sequenceNum) * Int(session.sessionInformation.samplePeriod) / 1000
                        
                        // Number of seconds between current data point and first session start
                        timeStamp = dataPointSeconds + sessionStartTimeDiff
                    }

                    
                    output.append(String(format: "%d,%u,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f",
                                         timeStamp,
                                         session.id,
                                         dataPoint.sequenceNum,
                                         dataPoint.temperatures.values[0], dataPoint.temperatures.values[1],
                                         dataPoint.temperatures.values[2], dataPoint.temperatures.values[3],
                                         dataPoint.temperatures.values[4], dataPoint.temperatures.values[5],
                                         dataPoint.temperatures.values[6], dataPoint.temperatures.values[7]))
                }
            }
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
