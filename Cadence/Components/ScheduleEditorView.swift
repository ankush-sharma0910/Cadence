//
//  ScheduleEditorView.swift
//  Cadence
//
//  Created by Ankush Sharma on 14/10/26.
//

import SwiftUI

// The popover opened from the schedule's pencil.
// Two modes: change only the day you are looking at, or change your usual schedule.
struct ScheduleEditorView: View {
    @Environment(AppStore.self) private var store

    let date: Date      // the day being looked at on the dashboard

    private enum Mode: Hashable {
        case thisDay
        case usual
    }
    @State private var mode: Mode = .thisDay

    // Which weekday's usual schedule is shown in "usual" mode (1 = Sunday ... 7 = Saturday).
    @State private var editingWeekday: Int

    // The "new entry" form.
    @State private var newTitle = ""
    @State private var newStart = 9 * 60      // minutes since midnight
    @State private var newEnd = 10 * 60
    @State private var newWeekdays: Set<Int>

    // Which field has keyboard focus when the panel opens.
    private enum Field: Hashable {
        case newTitle
    }
    @FocusState private var focusedField: Field?

    init(date: Date) {
        self.date = date
        let weekday = Calendar.current.component(.weekday, from: date)
        _editingWeekday = State(initialValue: weekday)
        _newWeekdays = State(initialValue: [weekday])
    }

    private var dateWeekday: Int {
        Calendar.current.component(.weekday, from: date)
    }

    private var canAdd: Bool {
        !newTitle.trimmingCharacters(in: .whitespaces).isEmpty
            && newEnd > newStart
            && (mode == .thisDay || !newWeekdays.isEmpty)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SCHEDULE")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)

            // What are you changing?
            Picker("Edit", selection: $mode) {
                Text("This day only").tag(Mode.thisDay)
                Text("Every \(Weekday.long(dateWeekday))").tag(Mode.usual)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // The empty form comes before the lists, so the field macOS
            // focuses has nothing to highlight.
            addForm

            if mode == .thisDay {
                DayScheduleList(date: date)
            } else {
                UsualScheduleList(editingWeekday: $editingWeekday)
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

            if mode == .usual {
                // Which weekdays this entry repeats on
                HStack(spacing: 6) {
                    Text("Repeat on")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    ForEach(Weekday.order, id: \.self) { day in
                        weekdayChip(day)
                    }
                }
            } else {
                Text("Adds to this day only: \(dateLabel)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
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

    private var dateLabel: String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased()
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
            Text(Weekday.short(day))
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
        let title = newTitle.trimmingCharacters(in: .whitespaces)

        withAnimation(.easeInOut(duration: 0.15)) {
            if mode == .thisDay {
                store.addEntry(to: date, title: title,
                               startMinutes: newStart, endMinutes: newEnd)
            } else {
                store.addScheduleEntries(title: title,
                                         startMinutes: newStart,
                                         endMinutes: newEnd,
                                         weekdays: newWeekdays)
                // Make sure the new entry is visible in the list below.
                if !newWeekdays.contains(editingWeekday),
                   let first = Weekday.order.first(where: { newWeekdays.contains($0) }) {
                    editingWeekday = first
                }
            }
        }
        newTitle = ""
        focusedField = .newTitle      // ready for the next entry
    }
}

// MARK: - "This day only" list

private struct DayScheduleList: View {
    @Environment(AppStore.self) private var store
    let date: Date

    private var dateLabel: String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)).uppercased()
    }

    var body: some View {
        let customized = store.hasOverride(on: date)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(customized ? "CUSTOMIZED · \(dateLabel)" : "USUAL SCHEDULE · \(dateLabel)")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()

                if customized {
                    TwoStepButton(title: "Reset to usual", confirmTitle: "Reset?") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            store.resetDay(date)
                        }
                    }
                } else if !store.entries(for: date).isEmpty {
                    Button("Customize") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            store.customizeDay(date)
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                }
            }

            if customized {
                editableList
            } else {
                readOnlyList
            }
        }
    }

    // The day follows the usual schedule: show it, but don't edit it here.
    @ViewBuilder
    private var readOnlyList: some View {
        let entries = store.usualEntries(for: date).sorted { $0.startMinutes < $1.startMinutes }

        Text("This day follows your usual schedule. Press Customize, or add an entry, to change just this day.")
            .font(.system(size: 11))
            .foregroundStyle(Theme.textSecondary)

        if entries.isEmpty {
            Text("Nothing scheduled.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(entries) { entry in
                        ReadOnlyEntryRow(entry: entry)
                    }
                }
            }
            .frame(maxHeight: 220)
        }
    }

    // The day has its own list: every row can be edited.
    @ViewBuilder
    private var editableList: some View {
        @Bindable var store = store

        if let dayIndex = store.overrideIndex(for: date) {
            let ids = store.dayOverrides[dayIndex].entries.map { $0.id }

            if ids.isEmpty {
                Text("Nothing scheduled on this day.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(ids, id: \.self) { id in
                            if let entryIndex = store.dayOverrides[dayIndex].entries
                                .firstIndex(where: { $0.id == id }) {
                                ScheduleEditRow(
                                    entry: $store.dayOverrides[dayIndex].entries[entryIndex]
                                ) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        store.deleteEntry(id: id, on: date)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
    }
}

// MARK: - "Every <weekday>" list (the usual schedule)

private struct UsualScheduleList: View {
    @Environment(AppStore.self) private var store
    @Binding var editingWeekday: Int

    // The ids of the entries on the weekday being shown, in the order they were added.
    private var entryIDs: [UUID] {
        store.scheduleEntries
            .filter { $0.weekday == editingWeekday }
            .map { $0.id }
    }

    var body: some View {
        @Bindable var store = store

        VStack(alignment: .leading, spacing: 16) {
            // Which weekday's usual schedule to look at
            Picker("Day", selection: $editingWeekday) {
                ForEach(Weekday.order, id: \.self) { day in
                    Text(Weekday.short(day)).tag(day)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text("EVERY \(Weekday.long(editingWeekday).uppercased()) · CHANGES ALL OF THEM")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Theme.textSecondary)

            if entryIDs.isEmpty {
                Text("Nothing scheduled for \(Weekday.long(editingWeekday))s yet.")
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
    }
}

// MARK: - Rows

// A usual-schedule entry shown as plain text (not editable).
private struct ReadOnlyEntryRow: View {
    let entry: ScheduleEntry

    var body: some View {
        HStack(spacing: 16) {
            Text(entry.timeRangeText)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 150, alignment: .leading)
            Text(entry.title)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// One editable entry: title, start and end times, and a delete button.
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
        .help("Delete this entry")
        .task(id: confirmingDelete) {
            // If you don't confirm within 3 seconds, go back to the trash icon.
            guard confirmingDelete else { return }
            try? await Task.sleep(for: .seconds(3))
            confirmingDelete = false
        }
    }
}

// A text button that needs two clicks: the first asks, the second does it.
private struct TwoStepButton: View {
    let title: String
    let confirmTitle: String
    let action: () -> Void

    @State private var confirming = false

    var body: some View {
        Button {
            if confirming {
                confirming = false
                action()
            } else {
                confirming = true
            }
        } label: {
            Text(confirming ? confirmTitle : title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(confirming ? Theme.textPrimary : Theme.textSecondary)
        }
        .buttonStyle(.plain)
        .task(id: confirming) {
            // If you don't confirm within 3 seconds, go back to the first label.
            guard confirming else { return }
            try? await Task.sleep(for: .seconds(3))
            confirming = false
        }
    }
}

// MARK: - Helpers

// Weekday names. Weekday numbers follow Apple: 1 = Sunday ... 7 = Saturday.
private enum Weekday {
    // Monday first, Sunday last.
    static let order = [2, 3, 4, 5, 6, 7, 1]

    static func short(_ weekday: Int) -> String {
        Calendar.current.shortWeekdaySymbols[weekday - 1]
    }

    static func long(_ weekday: Int) -> String {
        Calendar.current.weekdaySymbols[weekday - 1]
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
    ScheduleEditorView(date: Date())
        .environment(AppStore())
}
