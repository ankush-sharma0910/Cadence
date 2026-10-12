//
//  TodoItem.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isDone = false
    var date: Date          // the day this task belongs to
}

// Starting tasks, used only when nothing has been saved yet.
extension TodoItem {
    static var samples: [TodoItem] {
        let today = Date()
        return [
            TodoItem(title: "Complete a DSA lecture", date: today),
            TodoItem(title: "Solve two LeetCode problems", date: today),
            TodoItem(title: "Review Git concepts", isDone: true, date: today),
            TodoItem(title: "Practise the flute", date: today)
        ]
    }
}
