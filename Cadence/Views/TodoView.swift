//
//  TodoView.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI

struct TodoView: View {
    // The shared store, used here for the saved monthly history.
    @Environment(AppStore.self) private var store

    @Binding var todos: [TodoItem]   // all tasks, owned by the store
    let date: Date                   // the day being shown
    var focusRequest = 0             // each time this number goes up, focus the "Add a task" box

    @State private var newTitle = ""
    @State private var showHistory = false
    @FocusState private var addFieldFocused: Bool

    // Only the tasks that belong to the shown day.
    private var dayTodos: [TodoItem] {
        todos.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Completion for the shown day

    private var completedCount: Int {
        dayTodos.filter { $0.isDone }.count
    }

    // 0.0 to 1.0. Safe when there are no tasks.
    private var completionFraction: Double {
        guard !dayTodos.isEmpty else { return 0 }
        return Double(completedCount) / Double(dayTodos.count)
    }

    // Whole-number percentage, e.g. 0.6667 becomes 67.
    private var completionPercent: Int {
        Int((completionFraction * 100).rounded())
    }

    // MARK: - Monthly ring

    // This month's record if it exists, otherwise the most recent saved month.
    private var ringRecord: MonthlyRecord? {
        let now = Calendar.current.dateComponents([.year, .month], from: Date())
        return store.monthlyRecords.first {
            $0.year == now.year && $0.month == now.month
        } ?? store.monthlyRecords.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !dayTodos.isEmpty || ringRecord != nil {
                summaryRow
            }

            if dayTodos.isEmpty {
                Text("No tasks for this day")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 10)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(dayTodos) { todo in
                            TodoRow(
                                todo: todo,
                                onToggle: { toggle(todo.id) },
                                onDelete: { delete(todo.id) },
                                onRename: { newTitle in rename(todo.id, to: newTitle) }
                            )
                        }
                    }
                }
            }

            addField
        }
        // The "New to-do" menu item bumps focusRequest, which puts the cursor in the add box.
        .onChange(of: focusRequest) {
            addFieldFocused = true
        }
    }

    // MARK: - Summary row (progress for the day + monthly ring)

    private var summaryRow: some View {
        HStack(alignment: .center, spacing: 16) {
            if dayTodos.isEmpty {
                Spacer()
            } else {
                progressSummary
            }

            if let record = ringRecord {
                MiniRingView(
                    fraction: record.averageCompletion,
                    caption: "\(record.shortMonth) avg",
                    help: "Average daily completion in \(record.title.capitalized). Click to see all months."
                )
                .contentShape(Rectangle())
                .onTapGesture { showHistory = true }
                .popover(isPresented: $showHistory, arrowEdge: .bottom) {
                    MonthlyHistoryView(records: store.monthlyRecords)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var progressSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(completedCount) of \(dayTodos.count) done")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(completionPercent)%")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }

            // Thin progress line: grey track with a white fill on top.
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(Theme.textPrimary)
                        .frame(width: geometry.size.width * completionFraction)
                        .animation(.easeInOut(duration: 0.3), value: completionFraction)
                }
            }
            .frame(height: 3)
        }
    }

    // MARK: - Add field

    private var addField: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            TextField("Add a task", text: $newTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
                .focused($addFieldFocused)
                .onSubmit { add() }      // pressing Return adds the task
        }
        .padding(.top, 12)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
    }

    // MARK: - Actions

    private func add() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            todos.append(TodoItem(title: title, date: date))
        }
        newTitle = ""
    }

    private func toggle(_ id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            todos[index].isDone.toggle()
        }
    }

    private func delete(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.15)) {
            todos.removeAll { $0.id == id }
        }
    }

    private func rename(_ id: UUID, to title: String) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].title = title
    }
}

// One row: checkbox, title (double-click to edit), and a delete button on hover.
private struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isDone ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundStyle(todo.isDone ? Theme.textSecondary : Theme.textPrimary)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("Task", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .focused($isFocused)
                    .onSubmit { commitEdit() }                 // Return saves
                    .onExitCommand { isEditing = false }       // Escape cancels
                    .onAppear { isFocused = true }
                    .onChange(of: isFocused) {
                        if !isFocused { commitEdit() }         // clicking elsewhere saves
                    }
            } else {
                Text(todo.title)
                    .font(.system(size: 14))
                    .strikethrough(todo.isDone)
                    .foregroundStyle(todo.isDone ? Theme.textSecondary : Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .help("Double-click to edit")
                    .onTapGesture(count: 2) { startEditing() }
            }

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }

    private func startEditing() {
        draft = todo.title
        isEditing = true
    }

    // Saves the new title (ignored if empty or unchanged) and leaves edit mode.
    private func commitEdit() {
        guard isEditing else { return }
        isEditing = false
        let title = draft.trimmingCharacters(in: .whitespaces)
        if !title.isEmpty && title != todo.title {
            onRename(title)
        }
    }
}

#Preview {
    TodoView(todos: .constant(TodoItem.samples), date: Date())
        .environment(AppStore())
        .padding()
        .background(Theme.background)
}
