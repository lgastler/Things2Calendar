//
//  CalendarManager.swift
//  Things2Calendar
//
//  Created by Lennart Gastler on 30.05.25.
//

import Foundation
import EventKit
import ArgumentParser

class CalendarManager {
    private let eventStore = EKEventStore()
    
    func createEvent(from timeBlockEntry: TimeBlockEntry, calendarIdentifier: String) async throws {
        let granted = try await requestCalendarAccess()
        guard granted else {
            print("Calendar access denied. Please grant permission in System Preferences.")
            throw ExitCode.failure
        }
        
        let calendars = eventStore.calendars(for: .event)
        guard let selectedCalendar = calendars.first(where: { $0.calendarIdentifier == calendarIdentifier }) else {
            print("Error: Calendar with identifier '\(calendarIdentifier)' not found")
            throw ExitCode.failure
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = timeBlockEntry.title
        event.startDate = timeBlockEntry.startDate
        event.endDate = timeBlockEntry.endDate ?? timeBlockEntry.startDate.addingTimeInterval(3600) // Default to 1 hour if no end date
        event.calendar = selectedCalendar
        
        // Set the Things URL as the event URL for deduplication and direct access
        event.url = URL(string: "things:///show?id=\(timeBlockEntry.id)")
        
        // Set notes if available
        if let notes = timeBlockEntry.notes, !notes.isEmpty {
            event.notes = notes
        }
        
        try eventStore.save(event, span: .thisEvent)
        print("Created event: \(event.title ?? "Untitled") from \(dateTimeFormatter.string(from: event.startDate)) to \(dateTimeFormatter.string(from: event.endDate))")
    }
    
    func syncTimeBlockEntries(_ entries: [TimeBlockEntry], calendarIdentifier: String) async throws {
        print("Syncing \(entries.count) time block entries to calendar...")
        
        // Get existing events with Things IDs to check for duplicates
        let existingEventsMap = try await getExistingThingsEvents(calendarIdentifier: calendarIdentifier)
        
        // Create a set of current Things IDs for quick lookup
        let currentThingsIds = Set(entries.map { $0.id })
        
        // Process current entries (create or update)
        for entry in entries {
            do {
                if let existingEvent = existingEventsMap[entry.id] {
                    // Check if the existing event needs updating
                    if needsUpdate(existingEvent: existingEvent, newEntry: entry) {
                        try await updateEvent(existingEvent, with: entry)
                    } else {
                        print("Event '\(entry.title)' is up to date, skipping")
                    }
                } else {
                    // Create new event
                    try await createEvent(from: entry, calendarIdentifier: calendarIdentifier)
                }
            } catch {
                print("Error processing event for '\(entry.title)': \(error)")
            }
        }
        
        // Remove orphaned events (exist in calendar but not in current Things todos)
        let orphanedEvents = existingEventsMap.filter { !currentThingsIds.contains($0.key) }
        if !orphanedEvents.isEmpty {
            print("Found \(orphanedEvents.count) orphaned events that are no longer in Things:")
            for (thingsId, event) in orphanedEvents {
                print("  - '\(event.title ?? "Untitled")' (ID: \(thingsId)) scheduled for \(dateTimeFormatter.string(from: event.startDate))")
            }
            
            print("Removing orphaned events from calendar...")
            for (thingsId, event) in orphanedEvents {
                do {
                    // Only remove future events as a safety measure
                    if event.startDate > Date() {
                        try await removeEvent(event, thingsId: thingsId)
                    } else {
                        print("Skipping past event: '\(event.title ?? "Untitled")' (Things ID: \(thingsId))")
                    }
                } catch {
                    print("Error removing orphaned event '\(event.title ?? "Untitled")': \(error)")
                }
            }
        }
        
        print("Sync completed!")
    }
    
    /// Retrieves existing calendar events that were created from Things entries
    /// - Parameter calendarIdentifier: The calendar identifier to search in
    /// - Returns: Dictionary mapping Things IDs to their corresponding calendar events
    private func getExistingThingsEvents(calendarIdentifier: String) async throws -> [String: EKEvent] {
        let granted = try await requestCalendarAccess()
        guard granted else {
            throw NSError(domain: "CalendarAccess", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
        }
        
        let calendars = eventStore.calendars(for: .event)
        guard let selectedCalendar = calendars.first(where: { $0.calendarIdentifier == calendarIdentifier }) else {
            throw NSError(domain: "CalendarNotFound", code: 2, userInfo: [NSLocalizedDescriptionKey: "Calendar not found"])
        }
        
        // Search for events from now to future 30 days (don't touch past events)
        let calendar = Calendar.current
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [selectedCalendar])
        let events = eventStore.events(matching: predicate)
        
        var thingsEventsMap: [String: EKEvent] = [:]
        
        for event in events {
            if let thingsId = extractThingsId(from: event) {
                thingsEventsMap[thingsId] = event
            }
        }
        
        print("Found \(thingsEventsMap.count) existing Things events in calendar")
        return thingsEventsMap
    }
    
    /// Extracts the Things ID from an event's URL
    /// - Parameter event: The calendar event
    /// - Returns: The Things ID if found, nil otherwise
    private func extractThingsId(from event: EKEvent) -> String? {
        guard let url = event.url,
              url.scheme == "things",
              url.host == nil || url.host == "",
              url.path == "/show" else { return nil }
        
        // Parse the query parameters to find the id
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        
        return queryItems.first { $0.name == "id" }?.value
    }
    
    /// Checks if an existing event needs to be updated with new data
    /// - Parameters:
    ///   - existingEvent: The existing calendar event
    ///   - newEntry: The new time block entry from Things
    /// - Returns: True if the event needs updating, false otherwise
    private func needsUpdate(existingEvent: EKEvent, newEntry: TimeBlockEntry) -> Bool {
        // Check if title, start date, or end date have changed
        if existingEvent.title != newEntry.title {
            return true
        }
        
        if existingEvent.startDate != newEntry.startDate {
            return true
        }
        
        let expectedEndDate = newEntry.endDate ?? newEntry.startDate.addingTimeInterval(3600)
        if existingEvent.endDate != expectedEndDate {
            return true
        }
        
        return false
    }
    
    /// Updates an existing calendar event with new data from Things
    /// - Parameters:
    ///   - event: The existing calendar event to update
    ///   - entry: The new time block entry data
    private func updateEvent(_ event: EKEvent, with entry: TimeBlockEntry) async throws {
        event.title = entry.title
        event.startDate = entry.startDate
        event.endDate = entry.endDate ?? entry.startDate.addingTimeInterval(3600)
        
        // Update the Things URL (should be the same, but ensure it's set correctly)
        event.url = URL(string: "things:///show?id=\(entry.id)")
        
        // Update notes 
        if let notes = entry.notes, !notes.isEmpty {
            event.notes = notes
        } else {
            event.notes = nil
        }
        
        try eventStore.save(event, span: .thisEvent)
        print("Updated event: \(event.title ?? "Untitled") from \(dateTimeFormatter.string(from: event.startDate)) to \(dateTimeFormatter.string(from: event.endDate))")
    }

    func listCalendars() async throws {
        let granted = try await requestCalendarAccess()
        guard granted else {
            print("Calendar access denied. Please grant permission in System Preferences.")
            throw ExitCode.failure
        }
        
        let calendars = eventStore.calendars(for: .event)
        print("Available calendars:")
        for calendar in calendars {
            print("  - \(calendar.title) (ID: \(calendar.calendarIdentifier))")
        }
    }

    private func requestCalendarAccess() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.requestFullAccessToEvents { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    /// Removes an orphaned calendar event that no longer has a corresponding Things todo
    /// - Parameters:
    ///   - event: The calendar event to remove
    ///   - thingsId: The Things ID for logging purposes
    private func removeEvent(_ event: EKEvent, thingsId: String) async throws {
        try eventStore.remove(event, span: .thisEvent)
        print("Removed orphaned event: '\(event.title ?? "Untitled")' (Things ID: \(thingsId))")
    }
}
