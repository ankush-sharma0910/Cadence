//
//  AppStore.swift
//  Cadence
//
//  Created by Ankush Sharma on 12/10/26.
//

import Foundation
import Observation

// The single source of truth for the app's data.
// Every screen reads from this one object, so they never disagree.
@Observable
final class AppStore {
    // Each list saves itself to disk whenever it changes.
    var goals: [Goal] {
        didSet { Storage.save(goals, as: "goals") }
    }

    var scheduleEntries: [ScheduleEntry] {
        didSet { Storage.save(scheduleEntries, as: "schedule") }
    }

    var todos: [TodoItem] {
        didSet {
            Storage.save(todos, as: "todos")
            refreshMonthlyRecords()      // keep the monthly history up to date
        }
    }

    // Saved month-by-month averages, newest first.
    var monthlyRecords: [MonthlyRecord] {
        didSet { Storage.save(monthlyRecords, as: "monthly") }
    }

    // Runs once when the store is created: load saved data, or use samples.
    init() {
        goals = Storage.load([Goal].self, from: "goals") ?? Goal.samples
        scheduleEntries = Storage.load([ScheduleEntry].self, from: "schedule") ?? ScheduleEntry.samples
        todos = Storage.load([TodoItem].self, from: "todos") ?? TodoItem.samples
        monthlyRecords = Storage.load([MonthlyRecord].self, from: "monthly") ?? []
        refreshMonthlyRecords()
    }

    // Recalculates every month that still has tasks. Months whose tasks are gone
    // keep their last saved record, so history is never lost.
    private func refreshMonthlyRecords() {
        var updated = monthlyRecords

        for record in CompletionStats.monthlyRecords(from: todos) {
            if let index = updated.firstIndex(where: { $0.id == record.id }) {
                updated[index] = record
            } else {
                updated.append(record)
            }
        }

        updated.sort { ($0.year, $0.month) > ($1.year, $1.month) }

        if updated != monthlyRecords {
            monthlyRecords = updated     // only saves when something changed
        }
    }
}
