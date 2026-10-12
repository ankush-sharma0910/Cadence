//
//  DashboardView.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI

struct DashboardView: View {
    // The date whose to-do list is shown. Starts as today.
    @State private var selectedDate = Date()
    private let today = Date()

    // Each list loads from disk. If nothing is saved yet, it uses the samples.
    @State private var goals: [Goal] =
        Storage.load([Goal].self, from: "goals") ?? Goal.samples

    @State private var scheduleEntries: [ScheduleEntry] =
        Storage.load([ScheduleEntry].self, from: "schedule") ?? ScheduleEntry.samples

    @State private var todos: [TodoItem] =
        Storage.load([TodoItem].self, from: "todos") ?? TodoItem.samples

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            verticalLine

            VStack(spacing: 0) {
                // Top: your own editable line
                EditableLineView()

                horizontalLine

                // Goals strip
                section(title: "GOALS") { goalsRow }
                    .frame(height: 210)
                    .overlay(alignment: .bottomTrailing) { editGoalsButton }

                horizontalLine

                // Bottom row: schedule | to-do
                HStack(spacing: 0) {
                    section(title: weekdayTitle) {
                        ScheduleView(entries: todaysEntries)
                    }
                    verticalLine
                    section(title: todoTitle) {
                        TodoView(todos: $todos, date: selectedDate)
                    }
                }
            }
        }
        .background(Theme.background)
        .frame(minWidth: 840, minHeight: 600)
        .preferredColorScheme(.dark)
        // Save automatically whenever a list changes.
        .onChange(of: goals) { Storage.save(goals, as: "goals") }
        .onChange(of: scheduleEntries) { Storage.save(scheduleEntries, as: "schedule") }
        .onChange(of: todos) { Storage.save(todos, as: "todos") }
    }

    // MARK: - Schedule

    // Only the entries that belong to today's weekday.
    private var todaysEntries: [ScheduleEntry] {
        let weekday = Calendar.current.component(.weekday, from: today)
        return scheduleEntries.filter { $0.weekday == weekday }
    }

    // MARK: - Goals

    private var goalsRow: some View {
        HStack(spacing: 40) {
            ForEach(goals) { goal in
                GoalRingView(goal: goal)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var editGoalsButton: some View {
        Button { } label: {
            Image(systemName: "pencil")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .buttonStyle(.plain)
        .padding(Theme.padding)
    }

    // MARK: - Left panel

    private var sidebar: some View {
        VStack(spacing: 20) {
            Menu {
                Button("New goal") { }
                Button("New schedule entry") { }
                Button("New to-do") { }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            Button { } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.top, Theme.padding)
        .frame(width: 56)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Automatic titles

    private var weekdayTitle: String {
        today.formatted(.dateTime.weekday(.wide)).uppercased()
    }

    private var todoTitle: String {
        selectedDate.formatted(.dateTime.day().month(.abbreviated).year()).uppercased()
    }

    // MARK: - Building blocks

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
            content()
        }
        .padding(Theme.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var horizontalLine: some View {
        Rectangle().fill(Theme.separator).frame(height: 1)
    }

    private var verticalLine: some View {
        Rectangle().fill(Theme.separator).frame(width: 1)
    }
}

#Preview {
    DashboardView()
}
