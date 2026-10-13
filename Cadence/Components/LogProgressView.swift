//
//  LogProgressView.swift
//  Cadence
//
//  Created by Ankush Sharma on 13/10/26.
//

import SwiftUI

// The popover opened from the left panel, where you log progress for each goal.
struct LogProgressView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LOG PROGRESS")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)

            if store.goals.isEmpty {
                Text("No goals yet")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(store.goals) { goal in
                            GoalLogRow(goal: goal)
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
        }
        .padding(Theme.padding)
        .frame(width: 340)
        .background(Theme.background)
        .preferredColorScheme(.dark)
    }
}

// One goal: its progress, an amount box, and this period's entries.
private struct GoalLogRow: View {
    @Environment(AppStore.self) private var store
    let goal: Goal

    @State private var amountText = ""

    // The typed amount as a number, or nil if it is empty, not a number, or not above zero.
    private var parsedAmount: Double? {
        let text = amountText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(text), value > 0 else { return nil }
        return value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Name, period and total so far
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(goal.period.rawValue) · target \(goal.target.cleaned) \(goal.unit)")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("\(store.progress(for: goal).cleaned) / \(goal.target.cleaned)")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }

            // Amount box and Add button
            HStack(spacing: 8) {
                TextField("Amount", text: $amountText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onSubmit { add() }

                Text(goal.unit)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)

                Button("Add") { add() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(parsedAmount == nil ? 0.3 : 1)
                    .disabled(parsedAmount == nil)
            }

            // Entries in the current day, week or month
            ForEach(store.logs(for: goal)) { log in
                LogEntryRow(log: log, unit: goal.unit) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        store.deleteLog(log)
                    }
                }
            }
        }
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
    }

    private func add() {
        guard let amount = parsedAmount else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            store.addLog(for: goal, amount: amount)
        }
        amountText = ""
    }
}

// One logged entry, with a delete button that appears on hover.
private struct LogEntryRow: View {
    let log: GoalLog
    let unit: String
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack {
            Text("\(log.amount.cleaned) \(unit)")
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(Theme.textPrimary.opacity(0.8))
            Text(log.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                .font(.system(size: 10))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}

#Preview {
    LogProgressView()
        .environment(AppStore())
}
