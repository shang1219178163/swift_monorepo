//
//  ContentView.swift
//  example
//
//  Created by Bin Shang on 2026/9/9.
//

import Navigator
import SFSafeSymbols
import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var navigator: Navigator

  var body: some View {
    TabView(selection: $navigator.selectedTab) {
      ForEach(AppTab.allCases) { tab in
        tabStack(tab: tab)
      }
    }
  }

  @ViewBuilder
  private func tabStack(tab: AppTab) -> some View {
    NavigationStack(path: navigator.pathBinding(for: tab.id)) {
      tab.rootView
        .navigatorDestination(destination: AppRouter.destination)
    }
    .toolbar(tabBarVisibility(for: tab.id), for: .tabBar)
    .tabItem {
      Label(tab.title, systemSymbol: tab.symbol)
    }
    .tag(tab.id)
  }

  private func tabBarVisibility(for tab: Int) -> Visibility {
    navigator.isStackEmpty(for: tab) ? .visible : .hidden
  }
}

#Preview {
  let _ = AppTab.setupNavigator()
  ContentView()
    .environmentObject(Get.shared)
}
