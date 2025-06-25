//
//  CalendarManager.swift
//  Calverge
//
//  Created by Lennart Gastler on 30.05.25.
//

import Foundation
import EventKit
import ArgumentParser

class CalendarManager {
    private let eventStore = EKEventStore()

    func listCalendars() async throws {
        let granted = try await requestCalendarAccess()
        guard granted else {
            print("Calendar access denied. Please grant permission in System Preferences.")
            throw ExitCode.failure
        }
        
        let calendars = eventStore.calendars(for: .event)
        print("Available calendars:")
        for calendar in calendars {
            let permissions = calendar.allowsContentModifications ? "(Read/Write)" : "(Read Only)"
            print("  - \(calendar.title) \(permissions)")
            print("    ID: \(calendar.calendarIdentifier)")
            print("    Source: \(calendar.source.title)")
            print("")
        }
    }
    
    func validateCalendar(id: String) async throws -> EKCalendar? {
        let granted = try await requestCalendarAccess()
        guard granted else {
            return nil
        }
        
        return eventStore.calendars(for: .event).first { $0.calendarIdentifier == id }
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
