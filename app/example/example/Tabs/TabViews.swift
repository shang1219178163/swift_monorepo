import Navigator
import SFSafeSymbols
import SwiftUI

struct TabHomeView: View {
  var body: some View {
    List {
      Section("导航") {
        Button("打开详情") {
          Task {
            _ = await Get.toNamed(
              AppRouter.detail,
              args: [
                "title": "来自首页",
                "id": 1,
              ])
          }
        }
        Button("JsonCodable 演示") {
          Task {
            _ = await Get.toNamed(
              AppRouter.jsonCodable,
              args: [
                "title": "来自首页",
                "id": 2,
              ])
          }
        }
        Button("日期互转演示") {
          Task { _ = await Get.toNamed(AppRouter.dateDemo) }
        }
        Button("不存在的路由") {
          Task {
            _ = await Get.toNamed(
              "/no-such-page",
              args: [
                "from": "home",
                "title": "演示未知页参数",
                "id": 42,
              ])
          }
        }
      }
    }
    .navigationBarCustom(title: AppTab.home.title, hideBack: true)
    .onRouteChanged { _, to in
      dlog(to?.toJson() ?? ["name": "root"])
    }
  }
}

struct TabCenterView: View {
  var body: some View {
    JsonCodableDemoView()
      .navigationBarCustom(title: AppTab.center.title, hideBack: true)
  }
}

struct TabDiscoverView: View {
  var body: some View { placeholderTab(.discover, subtitle: "发现页占位") }
}

struct TabMessageView: View {
  var body: some View { placeholderTab(.message, subtitle: "消息页占位") }
}

struct TabProfileView: View {
  var body: some View { placeholderTab(.profile, subtitle: "我的页占位") }
}

@MainActor
private func placeholderTab(_ tab: AppTab, subtitle: String) -> some View {
  ContentPlaceholder(
    title: tab.title,
    symbol: tab.symbol,
    subtitle: subtitle
  )
  .navigationBarCustom(title: tab.title, hideBack: true)
}

private struct ContentPlaceholder: View {
  let title: String
  let symbol: SFSymbol
  let subtitle: String

  var body: some View {
    VStack(spacing: 12) {
      Image(systemSymbol: symbol)
        .font(.system(size: 44))
        .foregroundStyle(.secondary)
      Text(title).font(.title2.bold())
      Text(subtitle)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
