//
//  MonthlyRecord.swift
//  Cadence
//
//  Created by Ankush Sharma on 13/10/26.
//

import Foundation

// One month's summary: the average of that month's daily completion percentages.
struct MonthlyRecord: Identifiable, Codable, Equatable {
    var year: Int
    var month: Int
    var averageCompletion: Double   // 0.0 to 1.0
    var daysCounted: Int            // days that had at least one task

    // Computed, so it is not saved to disk.
    var id: String { "\(year)-\(month)" }

    // Whole-number percentage, e.g. 0.7499 becomes 75.
    var percent: Int { Int((averageCompletion * 100).rounded()) }

    private var firstDay: Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
    }

    // "OCTOBER 2026"
    var title: String {
        firstDay.formatted(.dateTime.month(.wide).year()).uppercased()
    }

    // "OCT"
    var shortMonth: String {
        firstDay.formatted(.dateTime.month(.abbreviated)).uppercased()
    }
}
