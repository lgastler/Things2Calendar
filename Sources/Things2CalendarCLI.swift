//
//  Things2CalendarCLI.swift
//  Things2Calendar
//
//  Created by Lennart Gastler on 31.05.25.
//

import Foundation
import ArgumentParser

@main
struct Things2CalendarCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "Things2Calendar",
        abstract: "A utility to sync Things time blocks to your calendar",
        version: "0.0.1",
        subcommands: [Calendars.self, Sync.self]
    )
}

extension Things2CalendarCLI {
    struct Calendars: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "calendars",
            abstract: "List all available calendars"
        )
        
        func run() async throws {
            let calendarManager = CalendarManager()
            try await calendarManager.listCalendars()
        }
    }
    
    struct Sync: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "sync",
            abstract: "Sync Things time blocks to a specified calendar"
        )
        
        @Option(name: .long, help: "The identifier of the target calendar")
        var calendarIdentifier: String
        
        func run() async throws {
            let thingsManager = ThingsManager()
            let calendarManager = CalendarManager()
            
            print("Fetching time block entries from Things...")
            let timeBlockEntries = try await thingsManager.fetchTimeBlockEntries()
            
            if timeBlockEntries.isEmpty {
                print("No time block entries found in Things.")
                print("Checking for orphaned calendar events to clean up...")
            }
            
            try await calendarManager.syncTimeBlockEntries(timeBlockEntries, calendarIdentifier: calendarIdentifier)
        }
    }
}
