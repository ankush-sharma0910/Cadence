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
        didSet { Storage.save(todos, as: "todos") }
    }

    // Runs once when the store is created: load saved data, or use samples.
    init() {
        goals = Storage.load([Goal].self, from: "goals") ?? Goal.samples
        scheduleEntries = Storage.load([ScheduleEntry].self, from: "schedule") ?? ScheduleEntry.samples
        todos = Storage.load([TodoItem].self, from: "todos") ?? TodoItem.samples
    }
}
