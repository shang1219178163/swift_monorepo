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
          Task { _ = await Get.toNamed(AppRouter.jsonCodable) }
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
  }
}

struct TabCenterView: View {
  var body: some View {
    JsonCodableDemoView()
      .navigationBarCustom(title: AppTab.center.title, hideBack: true)
  }
}

struct TabDiscoverView: View {
  var body: some View {
    ContentPlaceholder(
      title: AppTab.discover.title,
      symbol: AppTab.discover.symbol,
      subtitle: "发现页占位"
    )
    .navigationBarCustom(title: AppTab.discover.title, hideBack: true)
  }
}

struct TabMessageView: View {
  var body: some View {
    ContentPlaceholder(
      title: AppTab.message.title,
      symbol: AppTab.message.symbol,
      subtitle: "消息页占位"
    )
    .navigationBarCustom(title: AppTab.message.title, hideBack: true)
  }
}

struct TabProfileView: View {
  var body: some View {
    ContentPlaceholder(
      title: AppTab.profile.title,
      symbol: AppTab.profile.symbol,
      subtitle: "我的页占位"
    )
    .navigationBarCustom(title: AppTab.profile.title, hideBack: true)
  }
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

struct DetailPageView: View {
  let args: [String: Any]

  private var titleText: String {
    (args["title"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "详情"
  }

  private var idText: String {
    if let id = args["id"] {
      return String(describing: id)
    }
    return "-"
  }

  var body: some View {
    List {
      LabeledContent("标题", value: titleText)
      LabeledContent("ID", value: idText)
      Button("返回并回传") {
        Get.back(result: ["from": "detail", "ok": true])
      }
    }
    .navigationBarCustom(title: titleText)
  }
}

struct UnknownPageView: View {
  let args: [String: Any]

  private var intended: String {
    (args[NavigatorArgKey.intendedRoute] as? String) ?? "(未提供)"
  }

  /// 业务传入参数（不含引擎写入的 intendedRoute）
  private var payloadKeys: [String] {
    args.keys.filter { $0 != NavigatorArgKey.intendedRoute }.sorted()
  }

  var body: some View {
    List {
      Section("路由") {
        LabeledContent("原目标", value: intended)
        LabeledContent("实际落地", value: AppRouter.unknown)
      }
      Section("参数") {
        if payloadKeys.isEmpty {
          Text("（无业务参数）")
            .foregroundStyle(.secondary)
        } else {
          ForEach(payloadKeys, id: \.self) { key in
            LabeledContent(key, value: stringify(args[key]))
          }
        }
      }
      Button("返回") {
        Get.back()
      }
    }
    .navigationBarCustom(title: "未知页面")
  }

  private func stringify(_ value: Any?) -> String {
    guard let value else { return "nil" }
    if let s = value as? String { return s }
    return String(describing: value)
  }
}
