//
//  DashboardView.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI
import AppKit

struct DashboardView: View {
    // The shared data store, provided by CadenceApp.
    @Environment(AppStore.self) private var store

    // The day being looked at. Starts as today; the magnifying glass changes it.
    @State private var selectedDate = Date()

    // True while you have not picked another date, so we move to the new day at midnight.
    @State private var followingToday = true

    // The current time, refreshed regularly so "now" stays correct.
    @State private var now = Date()

    // Each time this goes up, the to-do panel focuses its "Add a task" box.
    @State private var addTodoRequest = 0

    // Whether the popovers are open.
    @State private var showLogPanel = false
    @State private var showGoalEditor = false
    @State private var showScheduleEditor = false
    @State private var showDateSearch = false

    private var isViewingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        // Lets us pass two-way links like $store.todos to child views.
        @Bindable var store = store

        HStack(spacing: 0) {
            sidebar
            verticalLine

            VStack(spacing: 0) {
                // Top: your own editable line
                EditableLineView()

                horizontalLine

                // Goals strip
                section(title: "GOALS") { goalsRow }
                    .frame(height: 220)
                    .overlay(alignment: .bottomTrailing) { editGoalsButton }

                horizontalLine

                // Bottom row: schedule | to-do
                HStack(spacing: 0) {
                    section(title: scheduleTitle) {
                        ScheduleView(entries: store.entries(for: selectedDate),
                                     highlightsCurrent: isViewingToday,
                                     now: now)
                            // Rebuild when the day changes, so scrolling and highlight reset.
                            .id(Calendar.current.startOfDay(for: selectedDate))
                    }
                    .overlay(alignment: .bottomTrailing) { editScheduleButton }

                    verticalLine

                    section(title: todoTitle) {
                        TodoView(todos: $store.todos,
                                 date: selectedDate,
                                 focusRequest: addTodoRequest)
                    }
                }
            }
        }
        .background(Theme.background)
        .frame(minWidth: 840, minHeight: 600)
        .preferredColorScheme(.dark)
        // Remember whether you are following today or looking at another date.
        .onChange(of: selectedDate) {
            followingToday = Calendar.current.isDateInToday(selectedDate)
        }
        // Refresh "now" every 30 seconds.
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                refreshNow()
            }
        }
        // And straight away when you switch back to Cadence (e.g. after the Mac wakes up).
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshNow()
        }
    }

    // MARK: - Keeping today correct

    private func refreshNow() {
        now = Date()
        if Calendar.current.isDateInToday(selectedDate) {
            followingToday = true
        } else if followingToday {
            // Midnight passed while you were looking at "today": move to the new today.
            selectedDate = Date()
        }
    }

    // MARK: - Schedule

    private var editScheduleButton: some View {
        Button { showScheduleEditor = true } label: {
            Image(systemName: "pencil")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .buttonStyle(.plain)
        .help("Edit the schedule")
        .padding(Theme.padding)
        .popover(isPresented: $showScheduleEditor) {
            ScheduleEditorView(date: selectedDate)
                .environment(store)
        }
    }

    // MARK: - Goals

    @ViewBuilder
    private var goalsRow: some View {
        if store.shownGoals.isEmpty {
            Text("No goals shown. Click the pencil to choose.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Centred when it fits, scrolls sideways when there are many goals.
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 32) {
                        ForEach(store.shownGoals) { goal in
                            GoalRingView(
                                name: goal.name,
                                fraction: store.fraction(for: goal),
                                detail: "\(store.progress(for: goal).cleaned) / \(goal.target.cleaned) \(goal.unit)"
                            )
                        }
                    }
                    .frame(minWidth: geometry.size.width)
                }
            }
        }
    }

    private var editGoalsButton: some View {
        Button { showGoalEditor = true } label: {
            Image(systemName: "pencil")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .buttonStyle(.plain)
        .help("Edit goals")
        .padding(Theme.padding)
        .popover(isPresented: $showGoalEditor) {
            GoalEditorView()
                .environment(store)
        }
    }

    // MARK: - Left panel

    private var sidebar: some View {
        VStack(spacing: 20) {
            // Add something new
            Menu {
                Button("New goal") { showGoalEditor = true }
                Button("New schedule entry") { showScheduleEditor = true }
                Button("New to-do") { addTodoRequest += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()

            // Log progress on a goal
            Button { showLogPanel = true } label: {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .help("Log goal progress")
            .popover(isPresented: $showLogPanel) {
                LogProgressView()
                    .environment(store)
            }

            // Search by date
            Button { showDateSearch = true } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .help("Go to a date")
            // A small dot while you are looking at a day that is not today.
            .overlay(alignment: .topTrailing) {
                if !isViewingToday {
                    Circle()
                        .fill(Theme.textPrimary)
                        .frame(width: 6, height: 6)
                        .offset(x: 5, y: -3)
                }
            }
            .popover(isPresented: $showDateSearch) {
                DateSearchView(selectedDate: $selectedDate)
            }

            Spacer()
        }
        .padding(.top, Theme.padding)
        .frame(width: 56)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Automatic titles

    // "MONDAY", "TUESDAY · 20 OCT", plus "· CUSTOM" when that day has its own schedule.
    private var scheduleTitle: String {
        var title = selectedDate.formatted(.dateTime.weekday(.wide)).uppercased()
        if !isViewingToday {
            let day = selectedDate.formatted(.dateTime.day().month(.abbreviated)).uppercased()
            title += " · \(day)"
        }
        if store.hasOverride(on: selectedDate) {
            title += " · CUSTOM"
        }
        return title
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
        .environment(AppStore())
}
