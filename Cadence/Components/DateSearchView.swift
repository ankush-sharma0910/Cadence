//
//  DateSearchView.swift
//  Cadence
//
//  Created by Ankush Sharma on 14/10/26.
//

import SwiftUI

// The popover opened from the magnifying glass: pick a date to look at.
struct DateSearchView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            Text("GO TO DATE")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                // Clicking a day picks it and closes the panel.
                .onChange(of: selectedDate) { dismiss() }

            Button("Back to today") {
                selectedDate = Date()
                dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
        }
        .padding(Theme.padding)
        .frame(width: 290)
        .background(Theme.background)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    DateSearchView(selectedDate: .constant(Date()))
}
