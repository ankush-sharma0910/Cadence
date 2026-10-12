//
//  Goal.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import Foundation

struct Goal: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var target: Int      // e.g. 20 problems
    var progress: Int    // e.g. 10 solved

    // 0.0 to 1.0. Never divides by zero, never exceeds 100%.
    var percentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }
}

// Starting goals, used only when nothing has been saved yet.
extension Goal {
    static var samples: [Goal] {
        [
            Goal(name: "Coding", target: 20, progress: 10),
            Goal(name: "LeetCode", target: 10, progress: 7),
            Goal(name: "Running", target: 5, progress: 1),
            Goal(name: "Flute", target: 7, progress: 0)
        ]
    }
}
