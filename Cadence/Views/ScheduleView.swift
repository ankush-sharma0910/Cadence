//
//  ScheduleView.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI

struct ScheduleView: View {
    let entries: [ScheduleEntry]   // already filtered to one weekday
    var highlightsCurrent = true   // false when looking at a day that is not today

    private var sortedEntries: [ScheduleEntry] {
        entries.sorted { $0.startMinutes < $1.startMinutes }
    }

    private var currentMinutes: Int {
        let now = Date()
        let calendar = Calendar.current
        return calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
    }

    var body: some View {
        if entries.isEmpty {
            Text("Nothing scheduled")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(sortedEntries) { entry in
                            row(for: entry)
                        }
                    }
                }
                .onAppear {
                    // Only today jumps to the current or next entry.
                    guard highlightsCurrent else { return }
                    let target = sortedEntries.first { $0.endMinutes > currentMinutes }
                    if let target {
                        proxy.scrollTo(target.id, anchor: .top)
                    }
                }
            }
        }
    }

    private func row(for entry: ScheduleEntry) -> some View {
        let isCurrent = highlightsCurrent && entry.isActive(at: currentMinutes)
        return HStack(spacing: 16) {
            Text(entry.timeRangeText)
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(isCurrent ? Theme.textPrimary : Theme.textSecondary)
                .frame(width: 150, alignment: .leading)
            Text(entry.title)
                .font(.system(size: 14, weight: isCurrent ? .medium : .regular))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
        .id(entry.id)
    }
}

#Preview {
    ScheduleView(entries: ScheduleEntry.samples.filter { $0.weekday == 2 })
        .padding()
        .background(Theme.background)
}
