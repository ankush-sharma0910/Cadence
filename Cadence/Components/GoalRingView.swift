//
//  GoalRingView.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI

struct GoalRingView: View {
    let name: String
    let fraction: Double     // 0.0 to 1.0
    let detail: String       // e.g. "1 / 2 problems"

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Grey track behind the ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)

                // White arc showing progress
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Theme.textPrimary,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))   // start at the top
                    .animation(.easeInOut(duration: 0.6), value: fraction)

                // Percentage in the centre
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.system(size: 18, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 84, height: 84)

            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)

                Text(detail)
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(width: 110)
        }
    }
}

#Preview {
    GoalRingView(name: "Coding", fraction: 0.5, detail: "1.5 / 3 hours")
        .padding()
        .background(Theme.background)
}
