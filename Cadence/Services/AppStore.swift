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

    var goalLogs: [GoalLog] {
        didSet { Storage.save(goalLogs, as: "goalLogs") }
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
        let loadedGoals = Storage.load([Goal].self, from: "goals")
        goals = loadedGoals ?? Goal.samples
        goalLogs = Storage.load([GoalLog].self, from: "goalLogs") ?? []
        scheduleEntries = Storage.load([ScheduleEntry].self, from: "schedule") ?? ScheduleEntry.samples
        todos = Storage.load([TodoItem].self, from: "todos") ?? TodoItem.samples
        monthlyRecords = Storage.load([MonthlyRecord].self, from: "monthly") ?? []

        // New sample goals get fresh ids. Save them straight away, otherwise
        // logged entries would point at ids that disappear on the next launch.
        if loadedGoals == nil {
            Storage.save(goals, as: "goals")
        }

        refreshMonthlyRecords()
    }

    // MARK: - Goals

    // The goals that appear on the dashboard.
    var shownGoals: [Goal] {
        goals.filter { $0.isShown }
    }

    func addGoal(name: String, unit: String, target: Double, period: GoalPeriod) {
        goals.append(Goal(name: name, unit: unit, target: target, period: period))
    }

    // Deletes the goal and every entry logged for it.
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        goalLogs.removeAll { $0.goalID == goal.id }
    }

    // MARK: - Goal progress

    // Entries for a goal inside the current day, week or month (newest first).
    func logs(for goal: Goal, on date: Date = Date()) -> [GoalLog] {
        guard let interval = Calendar.current.dateInterval(of: goal.period.calendarComponent,
                                                           for: date) else { return [] }
        return goalLogs
            .filter { $0.goalID == goal.id && interval.contains($0.date) }
            .sorted { $0.date > $1.date }
    }

    // Total logged in the current period, e.g. 4.5 (km).
    func progress(for goal: Goal, on date: Date = Date()) -> Double {
        logs(for: goal, on: date).reduce(0) { $0 + $1.amount }
    }

    // 0.0 to 1.0, stopping at 1.0 even if you log more than the target.
    func fraction(for goal: Goal) -> Double {
        guard goal.target > 0 else { return 0 }
        return min(progress(for: goal) / goal.target, 1.0)
    }

    func addLog(for goal: Goal, amount: Double) {
        goalLogs.append(GoalLog(goalID: goal.id, date: Date(), amount: amount))
    }

    func deleteLog(_ log: GoalLog) {
        goalLogs.removeAll { $0.id == log.id }
    }

    // MARK: - Monthly history

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
