//
//  CadenceApp.swift
//  Cadence
//
//  Created by Ankush Sharma on 11/10/26.
//

import SwiftUI

@main
struct CadenceApp: App {
    // Created once, when the app starts.
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)   // makes the store available to every view inside
        }
    }
}
