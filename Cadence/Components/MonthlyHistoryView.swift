//
//  MonthlyHistoryView.swift
//  Cadence
//
//  Created by Ankush Sharma on 13/10/26.
//

import SwiftUI

// The popover that lists every stored month.
struct MonthlyHistoryView: View {
    let records: [MonthlyRecord]    // newest first

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MONTHLY AVERAGE")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)

            if records.isEmpty {
                Text("No history yet")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(records) { record in
                            row(for: record)
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(Theme.padding)
        .frame(width: 300)
        .background(Theme.background)
        .preferredColorScheme(.dark)
    }

    private func row(for record: MonthlyRecord) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.title)
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(Theme.textPrimary)
                    Text(record.daysCounted == 1 ? "1 day" : "\(record.daysCounted) days")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("\(record.percent)%")
                    .font(.system(size: 14, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }

            // Thin bar: grey track with a white fill on top.
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(Theme.textPrimary)
                        .frame(width: geometry.size.width * record.averageCompletion)
                }
            }
            .frame(height: 3)
        }
    }
}

// Fake months, so you can see the layout without touching real data.
#Preview {
    MonthlyHistoryView(records: [
        MonthlyRecord(year: 2026, month: 10, averageCompletion: 0.75, daysCounted: 12),
        MonthlyRecord(year: 2026, month: 9, averageCompletion: 0.62, daysCounted: 25)
    ])
}
