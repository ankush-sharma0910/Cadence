//
//  ContentView.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .environment(AppStore())
}
