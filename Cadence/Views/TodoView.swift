//
//  TodoView.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI

struct TodoView: View {
    @Binding var todos: [TodoItem]   // all tasks, owned by the dashboard
    let date: Date                   // the day being shown

    @State private var newTitle = ""

    // Only the tasks that belong to the shown day.
    private var dayTodos: [TodoItem] {
        todos.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                                onDelete: { delete(todo.id) }
                            )
                        }
                    }
                }
            }

            addField
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
}

// One row: checkbox, title, and a delete button that appears on hover.
private struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isDone ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundStyle(todo.isDone ? Theme.textSecondary : Theme.textPrimary)
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .font(.system(size: 14))
                .strikethrough(todo.isDone)
                .foregroundStyle(todo.isDone ? Theme.textSecondary : Theme.textPrimary)

            Spacer()

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
}

#Preview {
    TodoView(todos: .constant(TodoItem.samples), date: Date())
        .padding()
        .background(Theme.background)
}
