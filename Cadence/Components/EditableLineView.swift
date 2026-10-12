//
//  EditableLineView.swift
//  Cadence
//
//  Created by Ankush Sharma on 12/10/26.
//

import SwiftUI

struct EditableLineView: View {
    // Saved automatically on this Mac, under the key "savedLine".
    @AppStorage("savedLine") private var line = ""

    // Tracks whether the text field is being edited.
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Write a line worth remembering…", text: $line)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundStyle(Theme.textPrimary.opacity(0.75))
            .focused($isFocused)
            .onSubmit { isFocused = false }   // Return finishes editing
            .padding(.horizontal, Theme.padding)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
    }
}

#Preview {
    EditableLineView()
        .background(Theme.background)
}
