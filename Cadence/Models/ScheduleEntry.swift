//
//  ScheduleEntry.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import Foundation

struct ScheduleEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var weekday: Int        // 1 = Sunday ... 7 = Saturday
    var startMinutes: Int   // minutes since midnight, e.g. 870 = 2:30 PM
    var endMinutes: Int
    var title: String

    // Change to true for 14:30 style times.
    static let uses24HourClock = false

    // Is this entry happening at the given minute of the day?
    func isActive(at minutes: Int) -> Bool {
        startMinutes <= minutes && minutes < endMinutes
    }

    // "2:30 – 3:30 PM", or "11:30 AM – 12:30 PM" when AM/PM differ.
    var timeRangeText: String {
        let start = Self.clock(startMinutes)
        let end = Self.clock(endMinutes)
        if Self.uses24HourClock {
            return "\(start.text) – \(end.text)"
        }
        if start.isPM == end.isPM {
            return "\(start.text) – \(end.text) \(end.isPM ? "PM" : "AM")"
        }
        return "\(start.text) \(start.isPM ? "PM" : "AM") – \(end.text) \(end.isPM ? "PM" : "AM")"
    }

    private static func clock(_ minutes: Int) -> (text: String, isPM: Bool) {
        let hour24 = (minutes / 60) % 24
        let minute = minutes % 60
        if uses24HourClock {
            return (String(format: "%02d:%02d", hour24, minute), hour24 >= 12)
        }
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        return (String(format: "%d:%02d", hour12, minute), hour24 >= 12)
    }
}

// Starting schedule, used only when nothing has been saved yet.
extension ScheduleEntry {
    static var samples: [ScheduleEntry] {
        let template: [(start: Int, end: Int, title: String)] = [
            (5 * 60,        6 * 60,        "Wake up"),
            (6 * 60,        7 * 60,        "Exercise"),
            (9 * 60,        13 * 60,       "Classes"),
            (14 * 60 + 30,  15 * 60 + 30,  "Study"),
            (17 * 60,       19 * 60,       "Coding"),
            (21 * 60,       21 * 60 + 30,  "Review the day")
        ]
        return (1...7).flatMap { day in
            template.map {
                ScheduleEntry(weekday: day, startMinutes: $0.start, endMinutes: $0.end, title: $0.title)
            }
        }
    }
}
