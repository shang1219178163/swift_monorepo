//
//  NavigatorShort.swift
//  Navigator
//
//  GetX 风格静态门面：持有引擎 + 跳转 API；destination 由业务 View 挂载。
//

import SwiftUI

/// 按路由名解析标题（由业务注入，如读路由表 `title`）
public typealias RouteTitleProvider = (String) -> String?

/// 页面侧导航入口。须先 `setup`，再使用 `shared` / `toNamed` 等。
@MainActor
public final class NavigatorShort {
    private init() {}

    private static var engine: Navigator?
    /// 是否禁止栈顶重复 push（由业务注入）
    private static var preventsDuplicate: ((String) -> Bool)?
    /// 导航栏标题回落（由业务注入）
    public private(set) static var titleProvider: RouteTitleProvider?

    /// 已注入的引擎；未 `setup` 前访问会 preconditionFailure
    public static var shared: Navigator {
        guard let engine else {
            preconditionFailure("Call NavigatorShort.setup(...) before use")
        }
        return engine
    }

    /// 外部注入引擎配置。引擎只创建一次（避免 Preview 二次 setup 与 `@EnvironmentObject` 脱节）；策略闭包可覆盖。
    public static func setup(
        tabCount: Int,
        initialTab: Int = 0,
        containsRoute: @escaping RouteContains,
        preventsDuplicate: ((String) -> Bool)? = nil,
        titleProvider: RouteTitleProvider? = nil
    ) {
        if engine == nil {
            engine = Navigator(
                tabCount: tabCount,
                initialTab: initialTab,
                containsRoute: containsRoute
            )
        }
        self.preventsDuplicate = preventsDuplicate
        self.titleProvider = titleProvider
    }

    /// GetX `toNamed` → `pushNamed`；返回值 = 目标页 `pop(result:)`
    @discardableResult
    public static func toNamed(_ name: String, args: [String: Any] = [:]) async -> [String: Any]? {
        if preventsDuplicate?(name) == true,
           shared.currentSettings?.name == name {
            dlog("preventDuplicates skip: \(name)")
            return nil
        }
        return await shared.pushNamed(name, args: args)
    }

    /// GetX `offNamed` → `pushReplacementNamed`
    @discardableResult
    public static func offNamed(
        _ name: String,
        args: [String: Any] = [:],
        result: [String: Any]? = nil
    ) async -> [String: Any]? {
        await shared.pushReplacementNamed(name, args: args, result: result)
    }

    /// GetX `offAllNamed`：清空当前 Tab 栈后再 push
    @discardableResult
    public static func offAllNamed(_ name: String, args: [String: Any] = [:]) async -> [String: Any]? {
        await shared.pushNamedAndRemoveUntil(name, { _ in false }, args: args)
    }

    /// GetX `until` → `popUntil`
    public static func until(_ predicate: @escaping RoutePredicate, result: [String: Any]? = nil) {
        shared.popUntil(predicate, result: result)
    }

    /// GetX `back` → `pop`
    public static func back(count: Int = 1, result: [String: Any]? = nil) {
        shared.pop(count: count, result: result)
    }

    // MARK: - 路由监听

    public static var isLog: Bool {
        get { Navigator.isLog }
        set { Navigator.isLog = newValue }
    }

    public static var route: RouteSettings? { shared.route }
    public static var routePre: RouteSettings? { shared.routePre }
    public static var routeName: String? { shared.routeName }
    public static var routeNamePre: String? { shared.routeNamePre }
    public static var pageRouteNames: [String] { shared.pageRouteNames }

    @discardableResult
    public static func addListener(_ handler: @escaping RouteChangeHandler) -> RouteListenerID {
        shared.addListener(handler)
    }

    public static func removeListener(_ id: RouteListenerID) {
        shared.removeListener(id)
    }
}
