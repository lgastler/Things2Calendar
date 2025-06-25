//
//  CalendarSyncService.swift
//  Calverge
//
//  Created by Lennart Gastler on 25.06.25.
//

import Foundation
import EventKit

class CalendarSyncService {
    private let eventStore = EKEventStore()
    
    // Main sync function
    func sync(config: SyncConfiguration) async throws {
        // Step 1: Request calendar access
        let granted = try await requestCalendarAccess()
        guard granted else {
            print("❌ Calendar access denied. Please grant permission in System Preferences.")
            throw CalendarError.accessDenied
        }
        
        print("🔄 Starting sync: \(config.displayName)")
        print("📋 Sync mode: \(config.syncMode.description)")
        
        // Step 2: Validate target calendar
        guard let targetCalendar = getCalendar(for: config.targetCalendarID) else {
            throw CalendarError.calendarNotFound(config.targetCalendarID)
        }
        
        guard targetCalendar.allowsContentModifications else {
            throw CalendarError.calendarReadOnly(targetCalendar.title)
        }
        
        print("📅 Target calendar: \(targetCalendar.title)")
        
        // Step 3: Validate source calendars
        var validSourceCalendars: [EKCalendar] = []
        for sourceID in config.sourceCalendarIDs {
            guard let sourceCalendar = getCalendar(for: sourceID) else {
                print("⚠️  Warning: Source calendar not found: \(sourceID)")
                continue
            }
            validSourceCalendars.append(sourceCalendar)
        }
        
        guard !validSourceCalendars.isEmpty else {
            throw CalendarError.noSourceCalendars
        }
        
        print("📋 Source calendars: \(validSourceCalendars.map { $0.title }.joined(separator: ", "))")
        
        // Step 4: Perform sync for each source calendar
        var totalSynced = 0
        var totalCleaned = 0
        
        for sourceCalendar in validSourceCalendars {
            let (synced, cleaned) = try syncEventsFromSource(
                sourceCalendar, 
                to: targetCalendar, 
                config: config
            )
            totalSynced += synced
            totalCleaned += cleaned
            print("   ✅ \(sourceCalendar.title): \(synced) events synced, \(cleaned) cleaned")
        }
        
        if totalCleaned > 0 {
            print("🧹 Total cleaned up: \(totalCleaned) previously synced events")
        }
        print("🎉 Sync completed! Total events synced: \(totalSynced)")
    }
    
    // Core sync logic for one source calendar
    private func syncEventsFromSource(_ sourceCalendar: EKCalendar, to targetCalendar: EKCalendar, config: SyncConfiguration) throws -> (synced: Int, cleaned: Int) {
        
        // Define sync time range: from now to 1 year in the future
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        
        // STEP 1: CLEANUP - Remove only FUTURE previously synced events from this source
        let cleanedCount = try cleanupPreviouslySyncedEvents(
            fromSource: sourceCalendar,
            inTarget: targetCalendar,
            startDate: startDate,  // Only clean future events
            endDate: endDate
        )
        
        // STEP 2: GET SOURCE EVENTS - Retrieve all future events from source calendar
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [sourceCalendar]
        )
        
        let sourceEvents = eventStore.events(matching: predicate)
        
        // STEP 3: COPY EVENTS - Copy each source event to target calendar
        var syncedCount = 0
        for sourceEvent in sourceEvents {
            if try copyEventToTarget(sourceEvent, targetCalendar: targetCalendar, config: config) {
                syncedCount += 1
            }
        }
        
        return (syncedCount, cleanedCount)
    }
    
    // SAFETY: Only clean up future events that were previously synced
    private func cleanupPreviouslySyncedEvents(fromSource sourceCalendar: EKCalendar, inTarget targetCalendar: EKCalendar, startDate: Date, endDate: Date) throws -> Int {
        
        // Get only FUTURE events in target calendar
        let targetPredicate = eventStore.predicateForEvents(
            withStart: startDate,  // Start from now (no past events)
            end: endDate,
            calendars: [targetCalendar]
        )
        
        let targetEvents = eventStore.events(matching: targetPredicate)
        let sourceID = sourceCalendar.calendarIdentifier
        
        var deletedCount = 0
        
        // Check each FUTURE event in target calendar
        for event in targetEvents {
            // Additional safety check: ensure we're only touching future events
            guard event.startDate >= Date() else {
                continue  // Skip past events entirely
            }
            
            // Look for our sync metadata in the event notes
            if let notes = event.notes,
               notes.contains("Synced by Calverge"),
               notes.contains("Source: \(sourceID)") {
                
                // This event was previously synced from our source calendar - remove it
                do {
                    try eventStore.remove(event, span: .thisEvent)  // Only remove this specific event
                    deletedCount += 1
                } catch {
                    print("   ⚠️  Warning: Failed to remove event '\(event.title ?? "Unknown")': \(error)")
                }
            }
        }
        
        return deletedCount
    }
    
    // Copy a single event with appropriate details based on sync mode
    @discardableResult
    private func copyEventToTarget(_ sourceEvent: EKEvent, targetCalendar: EKCalendar, config: SyncConfiguration) throws -> Bool {
        
        // Skip past events - only sync future events
        guard sourceEvent.startDate >= Date() else {
            return false
        }
        
        // Create new event in target calendar
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.calendar = targetCalendar
        
        // Copy basic timing properties (always needed)
        newEvent.startDate = sourceEvent.startDate
        newEvent.endDate = sourceEvent.endDate
        newEvent.isAllDay = sourceEvent.isAllDay
        
        // Copy details based on sync mode
        switch config.syncMode {
        case .full:
            // Copy all details
            newEvent.title = sourceEvent.title
            newEvent.location = sourceEvent.location
            
            if config.includeDetails {
                // Copy additional details
                if let recurrenceRules = sourceEvent.recurrenceRules {
                    newEvent.recurrenceRules = recurrenceRules
                }
                
                if let alarms = sourceEvent.alarms {
                    newEvent.alarms = alarms
                }
            }
            
        case .busyOnly:
            // Create generic "Busy" event
            newEvent.title = "Busy"
            // No location, no details, just time blocking
        }
        
        // ADD SYNC METADATA - This is crucial for tracking and cleanup
        let sourceID = sourceEvent.calendar.calendarIdentifier
        let syncIdentifier = UUID().uuidString
        let timestamp = DateFormatter.iso8601.string(from: Date())
        
        let metadataNote = """
        
        ---
        Synced by Calverge CLI
        Config: \(config.displayName)
        Mode: \(config.syncMode.rawValue)
        Source: \(sourceID)
        Original: \(sourceEvent.eventIdentifier ?? "unknown")
        Sync ID: \(syncIdentifier)
        Synced: \(timestamp)
        ---
        """
        
        // Handle notes based on sync mode
        switch config.syncMode {
        case .full:
            if config.includeDetails {
                // Preserve original notes and add our metadata
                if let originalNotes = sourceEvent.notes, !originalNotes.isEmpty {
                    newEvent.notes = originalNotes + metadataNote
                } else {
                    newEvent.notes = metadataNote
                }
            } else {
                newEvent.notes = metadataNote
            }
        case .busyOnly:
            // Only metadata, no original notes
            newEvent.notes = metadataNote
        }
        
        // Save the new event
        do {
            try eventStore.save(newEvent, span: .thisEvent)
            return true
        } catch {
            print("   ⚠️  Warning: Failed to save event '\(sourceEvent.title ?? "Unknown")': \(error)")
            return false
        }
    }
    
    // Helper functions
    private func getCalendar(for calendarID: String) -> EKCalendar? {
        return eventStore.calendars(for: .event).first { $0.calendarIdentifier == calendarID }
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
}

// Date formatter extension
extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
}
