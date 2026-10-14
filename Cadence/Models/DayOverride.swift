//
//  DayOverride.swift
//  Cadence
//
//  Created by Ankush Sharma on 14/10/26.
//

import Foundation

// A schedule that belongs to ONE date only.
// A date with no DayOverride simply follows the usual schedule for its weekday.
struct DayOverride: Identifiable, Codable, Equatable {
    var date: Date                  // the start of that day
    var entries: [ScheduleEntry]

    var id: Date { date }
}
