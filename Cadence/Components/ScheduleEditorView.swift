//
//  ScheduleEditorView.swift
//  Cadence
//
//  Created by Ankush Sharma on 14/10/26.
//

import SwiftUI

// The popover opened from the schedule's pencil: add, edit and delete
// entries of your USUAL weekly schedule.
struct ScheduleEditorView: View {
    @Environment(AppStore.self) private var store

    // Which weekday's usual schedule is shown below (1 = Sunday ... 7 = Saturday).
    @State private var editingWeekday = ScheduleEditorView.todayWeekday

    // The "new entry" form.
    @State private var newTitle = ""
    @State private var newStart = 9 * 60      // minutes since midnight
    @State private var newEnd = 10 * 60
    @State private var newWeekdays: Set<Int> = [ScheduleEditorView.todayWeekday]

    // Which field has keyboard focus when the panel opens.
    private enum Field: Hashable {
        case newTitle
    }
    @FocusState private var focusedField: Field?

    // MARK: - Weekday helpers

    private static var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    // Monday first, Sunday last.
    private static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]

    private static func shortName(_ weekday: Int) -> String {
        Calendar.current.shortWeekdaySymbols[weekday - 1]
    }

    private static func longName(_ weekday: Int) -> String {
        Calendar.current.weekdaySymbols[weekday - 1]
    }

    private var canAdd: Bool {
        !newTitle.trimmingCharacters(in: .whitespaces).isEmpty
            && !newWeekdays.isEmpty
            && newEnd > newStart
    }

    // The ids of the entries on the weekday being shown, in the order they were added.
    private var entryIDs: [UUID] {
        store.scheduleEntries
            .filter { $0.weekday == editingWeekday }
            .map { $0.id }
    }

    var body: some View {
        // Lets each row edit its entry directly in the store.
        @Bindable var store = store

        VStack(alignment: .leading, spacing: 16) {
            Text("SCHEDULE")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)

            // The empty form comes first, so the field macOS focuses has nothing to highlight.
            addForm

            // Which weekday's usual schedule to look at
            Picker("Day", selection: $editingWeekday) {
                ForEach(Self.weekdayOrder, id: \.self) { day in
                    Text(Self.shortName(day)).tag(day)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text("EVERY \(Self.longName(editingWeekday).uppercased())")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Theme.textSecondary)

            if entryIDs.isEmpty {
                Text("Nothing scheduled for \(Self.longName(editingWeekday))s yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(entryIDs, id: \.self) { id in
                            if let index = store.scheduleEntries.firstIndex(where: { $0.id == id }) {
                                ScheduleEditRow(entry: $store.scheduleEntries[index]) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        store.deleteScheduleEntry(id: id)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .padding(Theme.padding)
        .frame(width: 400)
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .defaultFocus($focusedField, .newTitle)
        // Changing the weekday also changes where a new entry goes by default.
        .onChange(of: editingWeekday) {
            newWeekdays = [editingWeekday]
        }
    }

    // MARK: - New entry form

    private var addForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEW ENTRY")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Theme.textSecondary)

            TextField("Title, e.g. Classes", text: $newTitle)
                .inputBox()
                .focused($focusedField, equals: .newTitle)

            HStack(spacing: 8) {
                DatePicker("Start", selection: timeBinding($newStart),
                           displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.stepperField)
                Text("–")
                    .foregroundStyle(Theme.textSecondary)
                DatePicker("End", selection: timeBinding($newEnd),
                           displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.stepperField)
            }
            // Keep the end after the start.
            .onChange(of: newStart) {
                if newEnd <= newStart { newEnd = min(newStart + 60, 23 * 60 + 59) }
            }

            // Which weekdays this entry repeats on
            HStack(spacing: 6) {
                Text("Repeat on")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                ForEach(Self.weekdayOrder, id: \.self) { day in
                    weekdayChip(day)
                }
            }

            Button("Add entry") { addEntry() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .opacity(canAdd ? 1 : 0.3)
                .disabled(!canAdd)
        }
        .padding(.bottom, 4)
        .onSubmit { if canAdd { addEntry() } }   // Return adds the entry
    }

    private func weekdayChip(_ day: Int) -> some View {
        let isOn = newWeekdays.contains(day)
        return Button {
            if isOn {
                newWeekdays.remove(day)
            } else {
                newWeekdays.insert(day)
            }
        } label: {
            Text(Self.shortName(day))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isOn ? Color.black : Theme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(isOn ? Theme.textPrimary : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private func addEntry() {
        guard canAdd else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            store.addScheduleEntries(
                title: newTitle.trimmingCharacters(in: .whitespaces),
                startMinutes: newStart,
                endMinutes: newEnd,
                weekdays: newWeekdays
            )
            // Make sure the new entry is visible in the list below.
            if !newWeekdays.contains(editingWeekday),
               let first = Self.weekdayOrder.first(where: { newWeekdays.contains($0) }) {
                editingWeekday = first
            }
        }
        newTitle = ""
        focusedField = .newTitle      // ready for the next entry
    }
}

// One entry in the list: title, start and end times, and a delete button.
private struct ScheduleEditRow: View {
    @Binding var entry: ScheduleEntry
    let onDelete: () -> Void

    @State private var confirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("Title", text: $entry.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                deleteButton
            }

            HStack(spacing: 8) {
                DatePicker("Start", selection: timeBinding($entry.startMinutes),
                           displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.stepperField)
                Text("–")
                    .foregroundStyle(Theme.textSecondary)
                DatePicker("End", selection: timeBinding($entry.endMinutes),
                           displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.stepperField)
            }
        }
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
        .onChange(of: entry.startMinutes) { keepEndAfterStart() }
        .onChange(of: entry.endMinutes) { keepEndAfterStart() }
    }

    // An entry must end after it starts (and before midnight).
    private func keepEndAfterStart() {
        if entry.endMinutes <= entry.startMinutes {
            entry.endMinutes = min(entry.startMinutes + 30, 23 * 60 + 59)
            if entry.endMinutes <= entry.startMinutes {
                entry.startMinutes = entry.endMinutes - 1
            }
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
        .help("Delete this entry from your usual schedule")
        .task(id: confirmingDelete) {
            // If you don't confirm within 3 seconds, go back to the trash icon.
            guard confirmingDelete else { return }
            try? await Task.sleep(for: .seconds(3))
            confirmingDelete = false
        }
    }
}

// Bridges our "minutes since midnight" numbers to the clock value a time picker uses.
private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
    Binding(
        get: {
            Calendar.current.date(
                bySettingHour: minutes.wrappedValue / 60,
                minute: minutes.wrappedValue % 60,
                second: 0,
                of: Date()
            ) ?? Date()
        },
        set: { newDate in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newDate)
            minutes.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    )
}

// The look shared by the text boxes in this file.
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
    ScheduleEditorView()
        .environment(AppStore())
}
