import SwiftUI
import Navigator
import SFSafeSymbols

/// 主导航 Tab（rawValue = TabView.tag / pathTabs 下标）
enum AppTab: Int, CaseIterable, Identifiable, Hashable {
    case home
    case center
    case discover
    case message
    case profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "首页"
        case .center: "中心"
        case .discover: "发现"
        case .message: "消息"
        case .profile: "我的"
        }
    }

    var symbol: SFSymbol {
        switch self {
        case .home: .houseFill
        case .center: .squareGrid2x2Fill
        case .discover: .safariFill
        case .message: .messageFill
        case .profile: .personFill
        }
    }

    static var count: Int { allCases.count }

    @MainActor
    static func setupNavigator() {
        NavigatorShort.setup(
            tabCount: count,
            initialTab: home.id,
            containsRoute: AppRouter.contains,
            preventsDuplicate: { name in
                AppRouter.page(for: name).preventDuplicates
            },
            titleProvider: { name in
                AppRouter.page(for: name).title
            },
            unknownRoute: AppRouter.unknown
        )
        #if DEBUG
        NavigatorShort.isLog = true
        #endif
    }

    @MainActor
    @ViewBuilder
    var rootView: some View {
        switch self {
        case .home: TabHomeView()
        case .center: TabCenterView()
        case .discover: TabDiscoverView()
        case .message: TabMessageView()
        case .profile: TabProfileView()
        }
    }
}
