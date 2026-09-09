//
//  ContentView.swift
//  example
//
//  Created by Bin Shang on 2026/9/9.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("按钮") {
                print("按钮")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
