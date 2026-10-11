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

    // Sample goals for now. Real, saved goals come later.
    @State private var goals: [Goal] = [
        Goal(name: "Coding", target: 20, progress: 10),
        Goal(name: "LeetCode", target: 10, progress: 7),
        Goal(name: "Running", target: 5, progress: 1),
        Goal(name: "Flute", target: 7, progress: 0)
    ]

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            verticalLine

            VStack(spacing: 0) {
                // Top: your editable line (placeholder for now)
                Text("Write a line worth remembering…")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Theme.padding)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)

                horizontalLine

                // Goals strip
                section(title: "GOALS") { goalsRow }
                    .frame(height: 210)
                    .overlay(alignment: .bottomTrailing) { editGoalsButton }

                horizontalLine

                // Bottom row: schedule | to-do
                HStack(spacing: 0) {
                    section(title: weekdayTitle) {
                        scheduleRow(time: "2:30 – 3:30", activity: "Example activity")
                        Spacer()
                    }
                    verticalLine
                    section(title: todoTitle) { Spacer() }
                }
            }
        }
        .background(Theme.background)
        .frame(minWidth: 840, minHeight: 600)
        .preferredColorScheme(.dark)
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

    private func scheduleRow(time: String, activity: String) -> some View {
        HStack(spacing: 16) {
            Text(time)
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 100, alignment: .leading)
            Text(activity)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
        }
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
