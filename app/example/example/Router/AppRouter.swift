import SwiftUI
import Navigator

/// 示例 App 业务路由表。
@MainActor
enum AppRouter {
    static let home = "/"
    static let detail = "/detail"
    static let jsonCodable = "/jsonCodable"
    static let unknown = "/unknown"

    static let pages: [AppPage] = [
        AppPage(name: home, title: "首页") { _ in TabHomeView() },
        AppPage(name: detail, title: "详情") { settings in
            DetailPageView(args: settings.args ?? [:])
        },
        AppPage(name: jsonCodable, title: "JsonCodable") { _ in
            JsonCodableDemoView()
                .navigationBarCustom(title: "JsonCodable")
        },
        AppPage(name: unknown, title: "未知", preventDuplicates: false) { settings in
            UnknownPageView(args: settings.args ?? [:])
        },
    ]

    static func page(for name: String) -> AppPage {
        pages.first { $0.name == name }
            ?? pages.first { $0.name == unknown }!
    }

    static func contains(_ name: String) -> Bool {
        pages.contains { $0.name == name }
    }

    @ViewBuilder
    static func destination(_ settings: RouteSettings) -> some View {
        page(for: settings.name).build(settings)
    }
}
