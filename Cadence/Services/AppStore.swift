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

    // Your USUAL schedule: entries that repeat every week on their weekday.
    var scheduleEntries: [ScheduleEntry] {
        didSet { Storage.save(scheduleEntries, as: "schedule") }
    }

    // Schedules that belong to one particular date only.
    var dayOverrides: [DayOverride] {
        didSet { Storage.save(dayOverrides, as: "dayOverrides") }
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
        dayOverrides = Storage.load([DayOverride].self, from: "dayOverrides") ?? []
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

    // MARK: - Usual schedule

    // Adds one entry for each chosen weekday (1 = Sunday ... 7 = Saturday).
    func addScheduleEntries(title: String, startMinutes: Int, endMinutes: Int, weekdays: Set<Int>) {
        let newEntries = weekdays.sorted().map { weekday in
            ScheduleEntry(weekday: weekday,
                          startMinutes: startMinutes,
                          endMinutes: endMinutes,
                          title: title)
        }
        scheduleEntries.append(contentsOf: newEntries)
    }

    func deleteScheduleEntry(id: UUID) {
        scheduleEntries.removeAll { $0.id == id }
    }

    // The usual schedule for the weekday of a date.
    func usualEntries(for date: Date) -> [ScheduleEntry] {
        let weekday = Calendar.current.component(.weekday, from: date)
        return scheduleEntries.filter { $0.weekday == weekday }
    }

    // MARK: - One-day schedules

    func overrideIndex(for date: Date) -> Int? {
        dayOverrides.firstIndex { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func hasOverride(on date: Date) -> Bool {
        overrideIndex(for: date) != nil
    }

    // What a day actually shows: its own list if it has one,
    // otherwise the usual schedule for that weekday.
    func entries(for date: Date) -> [ScheduleEntry] {
        if let index = overrideIndex(for: date) {
            return dayOverrides[index].entries
        }
        return usualEntries(for: date)
    }

    // Copies the usual schedule into a list that belongs to this date only.
    func customizeDay(_ date: Date) {
        guard !hasOverride(on: date) else { return }
        let weekday = Calendar.current.component(.weekday, from: date)
        let copies = usualEntries(for: date).map {
            ScheduleEntry(weekday: weekday,
                          startMinutes: $0.startMinutes,
                          endMinutes: $0.endMinutes,
                          title: $0.title)
        }
        dayOverrides.append(DayOverride(date: Calendar.current.startOfDay(for: date),
                                        entries: copies))
    }

    // Throws away the day's own list. The day follows the usual schedule again.
    func resetDay(_ date: Date) {
        dayOverrides.removeAll { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // Adds an entry to one date only (making the day's own list first if needed).
    func addEntry(to date: Date, title: String, startMinutes: Int, endMinutes: Int) {
        customizeDay(date)
        guard let index = overrideIndex(for: date) else { return }
        let weekday = Calendar.current.component(.weekday, from: date)
        dayOverrides[index].entries.append(
            ScheduleEntry(weekday: weekday,
                          startMinutes: startMinutes,
                          endMinutes: endMinutes,
                          title: title)
        )
    }

    func deleteEntry(id: UUID, on date: Date) {
        guard let index = overrideIndex(for: date) else { return }
        dayOverrides[index].entries.removeAll { $0.id == id }
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
