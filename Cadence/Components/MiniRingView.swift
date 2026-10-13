//
//  MiniRingView.swift
//  Cadence
//
//  Created by Ankush Sharma on 12/10/26.
//

import SwiftUI

// A small progress ring with a percentage inside and a tiny caption below.
struct MiniRingView: View {
    let fraction: Double     // 0.0 to 1.0
    let caption: String
    let help: String         // tooltip text shown on hover

    // The value actually drawn. It starts at 0 and animates up to `fraction`.
    @State private var shown = 0.0

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: shown)
                    .stroke(Theme.textPrimary,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.system(size: 9, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 38, height: 38)

            Text(caption)
                .font(.system(size: 9))
                .foregroundStyle(Theme.textSecondary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { shown = fraction }
        }
        .onChange(of: fraction) {
            withAnimation(.easeInOut(duration: 0.5)) { shown = fraction }
        }
        .help(help)
    }
}

#Preview {
    MiniRingView(fraction: 0.75, caption: "7-day avg", help: "Example")
        .padding()
        .background(Theme.background)
}
