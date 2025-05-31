//
//  ThingsManager.swift
//  Things2Calendar
//
//  Created by Lennart Gastler on 30.05.25.
//

import Foundation

/// Represents a time block entry from Things with scheduling information
public struct TimeBlockEntry {
    let id: String // Things ID for deduplication
    let title: String
    let notes: String?
    let startDate: Date
    let duration: TimeInterval?
    let durationTag: String
    let tags: [String]
    
    public var endDate: Date? {
        guard let duration = duration else { return nil }
        return startDate.addingTimeInterval(duration)
    }
}

/// Manager class for interacting with Things app and extracting time block entries
public class ThingsManager {
    
    private let dateFormatter: DateFormatter
    private let isoDateFormatter: ISO8601DateFormatter
    
    public init() {
        // Set up date formatters for parsing reminder dates
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime]
    }
    
    /// Fetches all todos from Things that have time-based scheduling and duration tags
    /// - Returns: Array of TimeBlockEntry objects representing scheduled time blocks
    /// - Throws: ThingsManagerError for various failure conditions
    public func fetchTimeBlockEntries() async throws -> [TimeBlockEntry] {
        // Get todos from Things app using AppleScript
        let todoData = try await fetchThingsTodos()
        
        // Convert to TimeBlockEntry objects
        var timeBlockEntries: [TimeBlockEntry] = []
        
        for todoDict in todoData {
            if let entry = try createTimeBlockEntry(from: todoDict) {
                timeBlockEntries.append(entry)
            }
        }
        
        // Sort by start date
        timeBlockEntries.sort { $0.startDate < $1.startDate }
        
        return timeBlockEntries
    }
    
    /// Creates a TimeBlockEntry from a todo dictionary from Shortcuts
    /// - Parameter todoDict: Dictionary containing todo data from Shortcuts
    /// - Returns: TimeBlockEntry if the todo qualifies, nil otherwise
    /// - Throws: ThingsManagerError.invalidDateFormat if reminderDate can't be parsed
    private func createTimeBlockEntry(from todoDict: [String: Any]) throws -> TimeBlockEntry? {
        // Extract basic todo information including the Things ID
        guard let id = todoDict["ID"] as? String,
              let title = todoDict["title"] as? String,
              let tags = todoDict["tags"] as? [String],
              let reminderDateString = todoDict["reminderDate"] as? String else {
            return nil
        }
        
        // Parse the reminder date
        guard let startDate = parseReminderDate(reminderDateString) else {
            throw ThingsManagerError.invalidDateFormat(reminderDateString)
        }
        
        // Check if todo has tags starting with "d-"
        guard let durationTag = findDurationTag(in: tags) else {
            return nil
        }
        
        // Parse duration from tag
        let duration = parseDuration(from: durationTag)
        
        return TimeBlockEntry(
            id: id,
            title: title,
            notes: nil,
            startDate: startDate,
            duration: duration,
            durationTag: durationTag,
            tags: tags
        )
    }
    
    /// Parses the reminderDate field from Shortcuts output
    /// - Parameter reminderDateString: ISO 8601 date string from Shortcuts
    /// - Returns: Date if parsing succeeds, nil otherwise
    private func parseReminderDate(_ reminderDateString: String) -> Date? {
        // The Shortcuts output uses ISO 8601 format with timezone: "2025-06-01T09:00:00+02:00"
        return isoDateFormatter.date(from: reminderDateString)
    }
    
    /// Finds duration tags (starting with "d-") in the tags array
    /// - Parameter tags: Array of tag strings
    /// - Returns: First duration tag found, nil if none
    private func findDurationTag(in tags: [String]?) -> String? {
        guard let tags = tags else { return nil }
        return tags.first { $0.hasPrefix("d-") }
    }
    
    /// Parses duration from a duration tag
    /// - Parameter durationTag: Tag string starting with "d-"
    /// - Returns: Duration in seconds, nil if can't parse
    private func parseDuration(from durationTag: String) -> TimeInterval? {
        // Remove "d-" prefix
        let durationString = String(durationTag.dropFirst(2))
        
        // Parse different duration formats
        // Examples: "30" (30 minutes), "1h" (1 hour), "2h" (2 hours)
        
        if durationString.hasSuffix("h") {
            // Hour format: "1h", "2h", etc.
            let hourString = String(durationString.dropLast(1))
            if let hours = Double(hourString) {
                return hours * 3600 // Convert hours to seconds
            }
        } else {
            // Assume minutes: "30", "15", "90", etc.
            if let minutes = Double(durationString) {
                return minutes * 60 // Convert minutes to seconds
            }
        }
        
        return nil
    }
    
    /// Fetches data from Things app using Shortcuts command
    /// - Returns: Array of todo dictionaries
    /// - Throws: ThingsManagerError for various failure conditions
    private func fetchThingsTodos() async throws -> [[String: Any]] {
        let process = Process()
        process.launchPath = "/usr/bin/shortcuts"
        process.arguments = ["run", "Get Things2Calendar Todos"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        process.launch()
        process.waitUntilExit()
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        
        guard process.terminationStatus == 0 else {
            print("Shortcuts command error: \(errorOutput)")
            throw ThingsManagerError.thingsNotAvailable
        }
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        // Debug output
        print("Shortcuts output: \(output)")
        
        // If output is empty, return empty array instead of erroring
        if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("No todos found from Shortcuts")
            return []
        }
        
        // Parse the JSON output directly
        return try parseShortcutsOutput(from: output)
    }
    
    /// Parses JSON output from Shortcuts command
    /// - Parameter output: JSON string from Shortcuts
    /// - Returns: Array of todo dictionaries
    /// - Throws: ThingsManagerError.dataCorrupted if parsing fails
    private func parseShortcutsOutput(from output: String) throws -> [[String: Any]] {
        let cleanOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanOutput.data(using: .utf8) else {
            throw ThingsManagerError.dataCorrupted("Could not convert output to data")
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            // Check if it's a valid todo array
            guard let todos = jsonObject as? [[String: Any]] else {
                throw ThingsManagerError.dataCorrupted("Invalid JSON structure - expected array of todos")
            }
            
            return todos
        } catch let jsonError {
            print("JSON parsing error: \(jsonError)")
            print("Raw output: \(cleanOutput)")
            throw ThingsManagerError.dataCorrupted("JSON parsing failed: \(jsonError)")
        }
    }
}
    
// MARK: - Extensions for demo/testing

extension ThingsManager {
    /// Creates sample time block entries for testing
    /// - Returns: Array of sample TimeBlockEntry objects
    public func createSampleTimeBlockEntries() -> [TimeBlockEntry] {
        let now = Date()
        let calendar = Calendar.current
        
        let startDate1 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now
        let startDate2 = calendar.date(bySettingHour: 16, minute: 30, second: 0, of: now) ?? now
        let startDate3 = calendar.date(byAdding: .day, value: 1, to: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now) ?? now
        
        return [
            TimeBlockEntry(
                id: "sample-1",
                title: "Team Meeting",
                notes: "Weekly sync with the development team",
                startDate: startDate1,
                duration: 3600,
                durationTag: "d-1h",
                tags: ["work", "d-1h"]
            ),
            TimeBlockEntry(
                id: "sample-2",
                title: "Code Review",
                notes: "Review pull requests",
                startDate: startDate2,
                duration: 1800,
                durationTag: "d-30m",
                tags: ["development", "d-30m"]
            ),
            TimeBlockEntry(
                id: "sample-3",
                title: "Workout",
                notes: "Gym session",
                startDate: startDate3,
                duration: 5400,
                durationTag: "d-1h30m",
                tags: ["health", "d-1h30m"]
            )
        ]
    }
}

/// Errors that can occur during Things data processing
public enum ThingsManagerError: Error, LocalizedError {
    case thingsNotAvailable
    case invalidDateFormat(String)
    case dataCorrupted(String)
    case notImplemented(String)
    
    public var errorDescription: String? {
        switch self {
        case .thingsNotAvailable:
            return "Things app is not available or accessible"
        case .invalidDateFormat(let format):
            return "Invalid date format: \(format)"
        case .dataCorrupted(let reason):
            return "Data corrupted: \(reason)"
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        }
    }
}
