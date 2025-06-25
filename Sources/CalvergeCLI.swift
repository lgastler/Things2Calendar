//
//  CalvergeCLI.swift
//  Calverge
//
//  Created by Lennart Gastler on 31.05.25.
//

import Foundation
import ArgumentParser

@main
struct CalvergeCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calverge",
        abstract: "A utility to sync calendars",
        version: "0.0.1",
        subcommands: [Calendars.self, Sync.self]
    )
}

extension CalvergeCLI {
    struct Calendars: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "calendars",
            abstract: "List all available calendars with their IDs"
        )
        
        func run() async throws {
            let calendarManager = CalendarManager()
            try await calendarManager.listCalendars()
        }
    }
}

extension CalvergeCLI {
    struct Sync: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "sync",
            abstract: "Sync calendars using command-line arguments or a JSON config file"
        )
        
        // Option 1: Use JSON config file
        @Option(name: .long, help: "Path to JSON configuration file")
        var config: String?
        
        // Option 2: Use command-line arguments
        @Option(name: .long, help: "Target calendar ID (where events will be synced to)")
        var target: String?
        
        @Option(name: .long, help: "Source calendar IDs (comma-separated)")
        var sources: String?
        
        @Option(name: .long, help: "Sync mode: 'full' or 'busy-only' (default: full)")
        var mode: String = "full"
        
        @Flag(name: .long, help: "Include full event details (notes, alarms, recurrence)")
        var includeDetails: Bool = false
        
        func run() async throws {
            let syncService = CalendarSyncService()
            
            // Determine which method to use
            if let configPath = config {
                // Use JSON file
                try await syncFromConfigFile(syncService: syncService, configPath: configPath)
            } else if let target = target, let sources = sources {
                // Use command-line arguments
                try await syncFromArguments(
                    syncService: syncService, 
                    target: target, 
                    sources: sources,
                    mode: mode,
                    includeDetails: includeDetails
                )
            } else {
                print("Error: Either provide --config <path> OR --target and --sources")
                print("\nExamples:")
                print("  calverge sync --config sync-config.json")
                print("  calverge sync --target <target-id> --sources <source1,source2>")
                print("  calverge sync --target <target-id> --sources <source1,source2> --mode busy-only")
                print("  calverge sync --target <target-id> --sources <source1,source2> --include-details")
                throw ExitCode.failure
            }
        }
        
        private func syncFromConfigFile(syncService: CalendarSyncService, configPath: String) async throws {
            let url = URL(fileURLWithPath: configPath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("Error: Config file not found at '\(configPath)'")
                throw ExitCode.failure
            }
            
            do {
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(SyncConfiguration.self, from: data)
                try await syncService.sync(config: config)
            } catch let decodingError as DecodingError {
                print("Error: Invalid JSON configuration file")
                print("Details: \(decodingError.localizedDescription)")
                throw ExitCode.failure
            } catch {
                print("Error reading config file: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        }
        
        private func syncFromArguments(syncService: CalendarSyncService, target: String, sources: String, mode: String, includeDetails: Bool) async throws {
            let sourceIDs = sources.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            // Validate sync mode
            guard let syncMode = SyncMode(rawValue: mode) else {
                print("Error: Invalid sync mode '\(mode)'. Valid options: \(SyncMode.allCases.map { $0.rawValue }.joined(separator: ", "))")
                throw ExitCode.failure
            }
            
            let config = SyncConfiguration(
                name: nil,  // No name needed for CLI arguments
                targetCalendarID: target,
                sourceCalendarIDs: sourceIDs,
                syncMode: syncMode,
                includeDetails: includeDetails
            )
            
            try await syncService.sync(config: config)
        }
    }
}
