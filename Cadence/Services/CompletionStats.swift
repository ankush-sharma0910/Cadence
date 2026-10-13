//
//  CompletionStats.swift
//  Cadence
//
//  Created by Ankush Sharma on 12/10/26.
//

import Foundation

// Calculations about how much of your to-do lists you complete.
enum CompletionStats {

    // Identifies one month while we are grouping.
    private struct MonthKey: Hashable {
        let year: Int
        let month: Int
    }

    // One record for every month that has at least one counted day.
    static func monthlyRecords(from todos: [TodoItem]) -> [MonthlyRecord] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        // 1. Group tasks by day, ignoring days in the future.
        let tasksByDay = Dictionary(grouping: todos) { calendar.startOfDay(for: $0.date) }
            .filter { $0.key <= startOfToday }

        // 2. Work out each day's completion and file it under its month.
        var completionsByMonth: [MonthKey: [Double]] = [:]
        for (day, dayTodos) in tasksByDay {
            let parts = calendar.dateComponents([.year, .month], from: day)
            guard let year = parts.year, let month = parts.month else { continue }

            let doneCount = dayTodos.filter { $0.isDone }.count
            let completion = Double(doneCount) / Double(dayTodos.count)
            completionsByMonth[MonthKey(year: year, month: month), default: []].append(completion)
        }

        // 3. Average each month's daily values.
        return completionsByMonth.map { key, values in
            MonthlyRecord(
                year: key.year,
                month: key.month,
                averageCompletion: values.reduce(0, +) / Double(values.count),
                daysCounted: values.count
            )
        }
    }
}
