//
//  Goal.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import Foundation

// How often a goal's progress starts again from zero.
enum GoalPeriod: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    // The calendar unit used to find the current day, week or month.
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily:   return .day
        case .weekly:  return .weekOfYear
        case .monthly: return .month
        }
    }
}

struct Goal: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var unit: String        // e.g. "problems", "km", "hours"
    var target: Double      // e.g. 2 problems, 15 km
    var period: GoalPeriod  // the target applies to each day, week or month
    var isShown = true      // is this goal shown on the dashboard?

    enum CodingKeys: String, CodingKey {
        case id, name, unit, target, period, isShown
    }
}

extension Goal {
    // Goals saved before `isShown` existed don't have it in their file.
    // Treat a missing value as "shown", so old goals and their logs load unchanged.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        unit = try container.decode(String.self, forKey: .unit)
        target = try container.decode(Double.self, forKey: .target)
        period = try container.decode(GoalPeriod.self, forKey: .period)
        isShown = try container.decodeIfPresent(Bool.self, forKey: .isShown) ?? true
    }
}

// Starting goals, used only when nothing has been saved yet.
extension Goal {
    static var samples: [Goal] {
        [
            Goal(name: "Coding", unit: "hours", target: 3, period: .daily),
            Goal(name: "LeetCode", unit: "problems", target: 2, period: .daily),
            Goal(name: "Running", unit: "km", target: 15, period: .weekly),
            Goal(name: "Flute", unit: "hours", target: 5, period: .weekly)
        ]
    }
}

extension Double {
    // 2.0 becomes "2", 3.5 stays "3.5".
    var cleaned: String {
        self == self.rounded() ? String(Int(self)) : String(format: "%.1f", self)
    }
}
