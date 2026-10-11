//
//  Goal.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import Foundation

struct Goal: Identifiable {
    let id = UUID()
    var name: String
    var target: Int      // e.g. 20 problems
    var progress: Int    // e.g. 10 solved

    // 0.0 to 1.0. Never divides by zero, never exceeds 100%.
    var percentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }
}
