//
//  TodoItem.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import Foundation

struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var isDone = false
    var date: Date          // the day this task belongs to
}

// Sample tasks for today. Saved tasks come later.
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
