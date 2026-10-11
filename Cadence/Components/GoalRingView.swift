//
//  GoalRingView.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI

struct GoalRingView: View {
    let goal: Goal

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Grey track behind the ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)

                // White arc showing progress
                Circle()
                    .trim(from: 0, to: goal.percentage)
                    .stroke(Theme.textPrimary,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))   // start at the top
                    .animation(.easeInOut(duration: 0.6), value: goal.percentage)

                // Percentage in the centre
                Text("\(Int(goal.percentage * 100))%")
                    .font(.system(size: 18, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 84, height: 84)

            // Goal name under the ring
            Text(goal.name)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .frame(width: 96)
        }
    }
}

#Preview {
    GoalRingView(goal: Goal(name: "Coding", target: 20, progress: 10))
        .padding()
        .background(Theme.background)
}
