import Navigator
import SwiftUI

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
