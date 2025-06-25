//
//  CalendarError.swift
//  Calverge
//
//  Created by Lennart Gastler on 25.06.25.
//

import Foundation

enum CalendarError: Error, LocalizedError {
    case accessDenied
    case calendarNotFound(String)
    case calendarReadOnly(String)
    case noSourceCalendars
    case invalidConfiguration(String)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied"
        case .calendarNotFound(let id):
            return "Calendar not found: \(id)"
        case .calendarReadOnly(let name):
            return "Calendar '\(name)' is read-only"
        case .noSourceCalendars:
            return "No valid source calendars found"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}
