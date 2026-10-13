//
//  GoalEditorView.swift
//  Cadence
//
//  Created by Ankush Sharma on 13/10/26.
//

import SwiftUI

// The popover opened from the pencil: add, edit, delete, show or hide goals.
struct GoalEditorView: View {
    @Environment(AppStore.self) private var store

    // Fields for the "new goal" form.
    @State private var newName = ""
    @State private var newTarget = ""
    @State private var newUnit = ""
    @State private var newPeriod: GoalPeriod = .daily

    // Which field has keyboard focus when the panel opens.
    private enum Field: Hashable {
        case newName
    }
    @FocusState private var focusedField: Field?

    // The typed target as a number, or nil if it is empty, not a number, or not above zero.
    private var parsedTarget: Double? {
        let text = newTarget
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(text), value > 0 else { return nil }
        return value
    }

    private var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespaces).isEmpty && parsedTarget != nil
    }

    var body: some View {
        // Lets each row edit its goal directly in the store.
        @Bindable var store = store

        VStack(alignment: .leading, spacing: 16) {
            Text("GOALS")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)

            // The empty new-goal form comes first, so the first text field
            // macOS focuses has nothing in it to highlight.
            addForm

            if store.goals.isEmpty {
                Text("No goals yet. Add your first one above.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 18) {
                        ForEach($store.goals) { $goal in
                            GoalEditRow(goal: $goal) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    store.deleteGoal(goal)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 340)
            }
        }
        .padding(Theme.padding)
        .frame(width: 380)
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .defaultFocus($focusedField, .newName)
    }

    // MARK: - New goal form

    private var addForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEW GOAL")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Theme.textSecondary)

            TextField("Name, e.g. Running", text: $newName)
                .inputBox()
                .focused($focusedField, equals: .newName)

            HStack(spacing: 8) {
                TextField("Target", text: $newTarget)
                    .inputBox()
                    .frame(width: 70)
                TextField("Unit, e.g. km", text: $newUnit)
                    .inputBox()
                Picker("Period", selection: $newPeriod) {
                    ForEach(GoalPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }

            Button("Add goal") { addGoal() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .opacity(canAdd ? 1 : 0.3)
                .disabled(!canAdd)
        }
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
        .onSubmit { if canAdd { addGoal() } }   // Return adds the goal
    }

    private func addGoal() {
        guard let target = parsedTarget else { return }
        let unit = newUnit.trimmingCharacters(in: .whitespaces)
        withAnimation(.easeInOut(duration: 0.15)) {
            store.addGoal(
                name: newName.trimmingCharacters(in: .whitespaces),
                unit: unit.isEmpty ? "times" : unit,
                target: target,
                period: newPeriod
            )
        }
        newName = ""
        newTarget = ""
        newUnit = ""
        newPeriod = .daily
        focusedField = .newName      // ready for the next goal
    }
}

// One goal in the list: show/hide, name, delete, then target, unit and period.
private struct GoalEditRow: View {
    @Binding var goal: Goal
    let onDelete: () -> Void

    @State private var confirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button { goal.isShown.toggle() } label: {
                    Image(systemName: goal.isShown ? "eye" : "eye.slash")
                        .font(.system(size: 13))
                        .foregroundStyle(goal.isShown ? Theme.textPrimary : Theme.textSecondary)
                        .frame(width: 18)
                }
                .buttonStyle(.plain)
                .help(goal.isShown ? "Shown on the dashboard" : "Hidden from the dashboard")

                TextField("Name", text: $goal.name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(goal.isShown ? Theme.textPrimary : Theme.textSecondary)

                deleteButton
            }

            HStack(spacing: 8) {
                TextField("Target", value: $goal.target, format: .number)
                    .inputBox()
                    .frame(width: 70)
                TextField("Unit", text: $goal.unit)
                    .inputBox()
                Picker("Period", selection: $goal.period) {
                    ForEach(GoalPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            }
            .padding(.leading, 28)
        }
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
    }

    // Two clicks to delete: the first asks, the second confirms.
    private var deleteButton: some View {
        Button {
            if confirmingDelete {
                onDelete()
            } else {
                confirmingDelete = true
            }
        } label: {
            if confirmingDelete {
                Text("Delete?")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
            } else {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .help("Delete this goal and everything logged for it")
        .task(id: confirmingDelete) {
            // If you don't confirm within 3 seconds, go back to the trash icon.
            guard confirmingDelete else { return }
            try? await Task.sleep(for: .seconds(3))
            confirmingDelete = false
        }
    }
}

// The look shared by every input box in this file.
private extension View {
    func inputBox() -> some View {
        self
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    GoalEditorView()
        .environment(AppStore())
}
