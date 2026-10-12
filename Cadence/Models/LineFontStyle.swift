//
//  LineFontStyle.swift
//  Cadence
//
//  Created by Ankush Sharma on 12/10/26.
//

import SwiftUI

// The font styles you can choose for the saved line.
enum LineFontStyle: String, CaseIterable {
    case regular = "Regular"
    case italic = "Italic"
    case bold = "Bold"
    case serif = "Serif"
    case rounded = "Rounded"
    case monospaced = "Monospaced"

    // Builds the real font for a given size.
    func font(size: CGFloat) -> Font {
        switch self {
        case .regular:    return .system(size: size)
        case .italic:     return .system(size: size).italic()
        case .bold:       return .system(size: size, weight: .semibold)
        case .serif:      return .system(size: size, design: .serif)
        case .rounded:    return .system(size: size, design: .rounded)
        case .monospaced: return .system(size: size, design: .monospaced)
        }
    }
}
