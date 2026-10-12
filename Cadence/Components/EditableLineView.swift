//
//  EditableLineView.swift
//  Cadence
//
//  Created by Ankush Sharma on 12/10/26.
//

import SwiftUI

struct EditableLineView: View {
    // Saved automatically on this Mac.
    @AppStorage("savedLine") private var line = ""
    @AppStorage("lineFontSize") private var fontSize = 14
    @AppStorage("lineFontStyle") private var fontStyle: LineFontStyle = .regular

    // true while you are typing; false when just showing the line.
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    private let placeholder = "Write a line worth remembering…"
    private let sizes = [12, 14, 16, 20, 24]

    var body: some View {
        HStack(spacing: 12) {
            lineArea
            styleMenu
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }

    // The line itself: plain text, or a text field while editing.
    private var lineArea: some View {
        Group {
            if isEditing {
                TextField(placeholder, text: $line)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit { isEditing = false }          // Return finishes editing
                    .onAppear { isFocused = true }           // start typing straight away
                    .onChange(of: isFocused) {
                        if !isFocused { isEditing = false }  // clicking elsewhere finishes too
                    }
            } else {
                Text(line.isEmpty ? placeholder : line)
                    .foregroundStyle(line.isEmpty ? Theme.textSecondary
                                                  : Theme.textPrimary.opacity(0.75))
            }
        }
        .font(fontStyle.font(size: CGFloat(fontSize)))
        .foregroundStyle(Theme.textPrimary.opacity(0.75))
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())                           // whole area is clickable
        .onTapGesture {
            if !isEditing { isEditing = true }
        }
    }

    // The small "Aa" menu for choosing size and style.
    private var styleMenu: some View {
        Menu {
            Section("Size") {
                Picker("Size", selection: $fontSize) {
                    ForEach(sizes, id: \.self) { size in
                        Text("\(size) pt").tag(size)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            Section("Style") {
                Picker("Style", selection: $fontStyle) {
                    ForEach(LineFontStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        } label: {
            Text("Aa")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

#Preview {
    EditableLineView()
        .background(Theme.background)
}
