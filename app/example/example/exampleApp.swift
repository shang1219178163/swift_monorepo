//
//  exampleApp.swift
//  example
//
//  Created by Bin Shang on 2026/9/9.
//

import SwiftUI
import Navigator

@main
struct exampleApp: App {
    init() {
        AppTab.setupNavigator()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NavigatorShort.shared)
        }
    }
}
