//
//  GoalLog.swift
//  Cadence
//
//  Created by Ankush Sharma on 13/10/26.
//

import Foundation

// One logged entry, e.g. "Running, 3.5 km, today at 6:30 PM".
struct GoalLog: Identifiable, Codable, Equatable {
    var id = UUID()
    var goalID: UUID        // which goal this entry belongs to
    var date: Date
    var amount: Double
}
