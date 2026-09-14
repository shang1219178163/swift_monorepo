import Navigator
import SwiftUI

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
