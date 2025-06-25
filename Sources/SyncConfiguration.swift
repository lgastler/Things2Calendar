//
//  SyncConfiguration.swift
//  Calverge
//
//  Created by Lennart Gastler on 25.06.25.
//

import Foundation

enum SyncMode: String, Codable, CaseIterable {
    case full = "full"           // Copy all event details (title, location, notes, etc.)
    case busyOnly = "busy-only"  // Create "Busy" placeholder events only
    
    var description: String {
        switch self {
        case .full:
            return "Full event details (title, location, notes, etc.)"
        case .busyOnly:
            return "Busy time blocks only (no details)"
        }
    }
}

struct SyncConfiguration: Codable {
    let name: String?
    let targetCalendarID: String
    let sourceCalendarIDs: [String]
    let syncMode: SyncMode
    let includeDetails: Bool
    
    init(name: String? = nil, targetCalendarID: String, sourceCalendarIDs: [String], syncMode: SyncMode = .full, includeDetails: Bool = true) {
        self.name = name
        self.targetCalendarID = targetCalendarID
        self.sourceCalendarIDs = sourceCalendarIDs
        self.syncMode = syncMode
        self.includeDetails = includeDetails
    }
    
    var displayName: String {
        return name ?? "Unnamed Sync"
    }
}
