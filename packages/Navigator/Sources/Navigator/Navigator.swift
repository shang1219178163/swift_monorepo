//
//  Navigator.swift
//  Navigator
//
//  纯路由引擎：不含业务路由表 / Tab 配置；由外部注入。
//  契约：async 跳转返回值 = 目标页 `pop(result:)` 的 result（侧滑未带 result 则为 nil）。
//

import SwiftUI

/// Flutter `typedef bool RoutePredicate(Route<dynamic> route)` 等价：按 name 判断
public typealias RoutePredicate = (String) -> Bool

/// 校验路由名是否合法（由业务层注入，如 `AppRouter.contains`）
public typealias RouteContains = (String) -> Bool

/// 路由变化回调（对齐 Flutter `void Function({Route? from, Route? to})`）
public typealias RouteChangeHandler = (_ from: RouteSettings?, _ to: RouteSettings?) -> Void

/// `addListener` 返回的注销凭证（Swift 闭包不可比，用 token 代替函数引用）
public struct RouteListenerID: Hashable, Sendable {
    fileprivate let uuid = UUID()
}

// MARK: - RouteSettings

/// `[String: Any]` 非 Sendable，用盒子承接 continuation 回传（Swift 6）
private final class RouteResultBox: @unchecked Sendable {
    let value: [String: Any]?
    init(_ value: [String: Any]?) { self.value = value }
}

/// 对齐 Flutter `RouteSettings`：name + 可选 args；持有 push 侧 continuation。
@MainActor
public final class RouteSettings: Hashable {
    public let name: String
    public var args: [String: Any]?

    private var continuation: CheckedContinuation<RouteResultBox, Never>?

    public init(name: String, args: [String: Any]? = nil) {
        self.name = name
        self.args = args
    }

    /// 挂起直到本页被 `complete`（通常由 `pop(result:)` 触发）
    public func waitForResult() async -> [String: Any]? {
        await withCheckedContinuation { cont in
            if let old = continuation {
                continuation = nil
                old.resume(returning: RouteResultBox(nil))
            }
            continuation = cont
        }.value
    }

    /// 结束等待；`result` 即对应 `await pushNamed` 的返回值
    public func complete(with result: [String: Any]? = nil) {
        let cont = continuation
        continuation = nil
        cont?.resume(returning: RouteResultBox(result))
    }

    public nonisolated static func == (lhs: RouteSettings, rhs: RouteSettings) -> Bool {
        lhs === rhs
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// 对齐 GetX `GetPage`：具名路由 + 页面构建（始终带 `RouteSettings`）。
@MainActor
public final class AppPage {
    /// 路由名，须以 `/` 开头（同 GetPage assert）
    public let name: String
    /// 可选标题（元数据，不强制写进页面）
    public let title: String?
    /// 对齐 GetX `preventDuplicates`：栈顶已是同名时不再 push
    public let preventDuplicates: Bool

    private let pageBuilder: @MainActor (RouteSettings) -> AnyView

    /// - Parameters:
    ///   - name: 路径，如 `/settings`
    ///   - title: 可选标题
    ///   - preventDuplicates: 是否禁止栈顶重复 push
    ///   - page: 页面构建，参数为 `RouteSettings`
    public init(
        name: String,
        title: String? = nil,
        preventDuplicates: Bool = true,
        @ViewBuilder page: @escaping @MainActor (RouteSettings) -> some View
    ) {
        precondition(name.hasPrefix("/"), "Route name must start with '/': \(name)")
        self.name = name
        self.title = title
        self.preventDuplicates = preventDuplicates
        self.pageBuilder = { settings in AnyView(page(settings)) }
    }

    /// 构建页面（对齐 GetPageRoute 最终 `page()`）
    public func build(_ settings: RouteSettings) -> AnyView {
        pageBuilder(settings)
    }
}

// MARK: - 当前页 RouteSettings

private struct RouteSettingsKey: EnvironmentKey {
    static let defaultValue: RouteSettings? = nil
}

extension EnvironmentValues {
    /// 本页路由；优先于 `Navigator.currentArgs`（栈顶全局值）
    public var routeSettings: RouteSettings? {
        get { self[RouteSettingsKey.self] }
        set { self[RouteSettingsKey.self] = newValue }
    }
}

// MARK: - Navigator（无业务依赖）

/// 路由管理器：多 Tab `NavigationPath` + 具名路由栈。
@MainActor
public final class Navigator: ObservableObject {
    /// 为 true 时每次路由变化打印日志
    public static var isLog = false

    @Published public var selectedTab: Int
    /// 仅经 `pathBinding` / 命名 push·pop 变更
    @Published public private(set) var pathTabs: [NavigationPath]

    /// 与 path 等深的路由快照（与 NavigationPath 中为同一 RouteSettings 实例）
    private var routeTabs: [[RouteSettings]]
    private let containsRoute: RouteContains

    /// 之前路由
    public private(set) var routePre: RouteSettings?
    /// 当前路由；栈空则为 nil，表示 Tab 根
    public private(set) var route: RouteSettings?

    private var listeners: [(id: RouteListenerID, handler: RouteChangeHandler)] = []

    /// - Parameters:
    ///   - tabCount: Tab 数量（由业务传入）
    ///   - initialTab: 初始选中 Tab
    ///   - containsRoute: 路由名是否存在（由业务传入）
    public init(
        tabCount: Int,
        initialTab: Int = 0,
        containsRoute: @escaping RouteContains
    ) {
        precondition(tabCount > 0, "tabCount must be > 0")
        self.selectedTab = initialTab
        self.containsRoute = containsRoute
        pathTabs = Array(repeating: NavigationPath(), count: tabCount)
        routeTabs = Array(repeating: [], count: tabCount)
    }

    /// 当前 Tab 导航路径（只读；写入请用 `pathBinding` 或命名 API）
    public var path: NavigationPath {
        guard pathTabs.indices.contains(selectedTab) else { return NavigationPath() }
        return pathTabs[selectedTab]
    }

    /// 当前 Tab 路由栈（自底向顶）
    public var pageRoutes: [RouteSettings] {
        guard routeTabs.indices.contains(selectedTab) else { return [] }
        return routeTabs[selectedTab]
    }

    public var routeName: String? { route?.name }
    public var routeNamePre: String? { routePre?.name }
    public var pageRouteNames: [String] { pageRoutes.map(\.name) }

    // MARK: - 路由监听

    @discardableResult
    public func addListener(_ handler: @escaping RouteChangeHandler) -> RouteListenerID {
        let id = RouteListenerID()
        listeners.append((id, handler))
        return id
    }

    public func removeListener(_ id: RouteListenerID) {
        listeners.removeAll { $0.id == id }
    }

    private func notifyListeners(from: RouteSettings?, to: RouteSettings?) {
        routePre = from
        route = to
        let snapshot = listeners
        for item in snapshot {
            item.handler(from, to)
        }
        dlog("route: \(from?.name ?? "root") → \(to?.name ?? "root"), stack: \(pageRouteNames)")
    }

    public func pathBinding(for tab: Int) -> Binding<NavigationPath> {
        Binding(
            get: {
                guard self.pathTabs.indices.contains(tab) else { return NavigationPath() }
                return self.pathTabs[tab]
            },
            set: { newValue in
                guard self.pathTabs.indices.contains(tab) else { return }
                var tabs = self.pathTabs
                tabs[tab] = newValue
                self.pathTabs = tabs
                // 系统侧滑等：无 result，await 得到 nil
                self.syncStacks(withPathCount: newValue.count, tab: tab)
            }
        )
    }

    public func isStackEmpty(for tab: Int) -> Bool {
        guard pathTabs.indices.contains(tab) else { return true }
        return pathTabs[tab].isEmpty
    }

    public var canPop: Bool {
        guard routeTabs.indices.contains(selectedTab) else { return false }
        return !routeTabs[selectedTab].isEmpty
    }

    public var currentSettings: RouteSettings? {
        guard routeTabs.indices.contains(selectedTab) else { return nil }
        return routeTabs[selectedTab].last
    }

    /// 当前 Tab 栈顶参数（跨页/嵌套勿用；本页请用 `@Environment(\.routeSettings)`）
    public var currentArgs: [String: Any]? { currentSettings?.args }

    /// 当前 Tab 路由名栈（自底向顶）
    public var routes: [String] {
        guard routeTabs.indices.contains(selectedTab) else { return [] }
        return routeTabs[selectedTab].map(\.name)
    }

    // MARK: - 命名路由 API
    // 所有 async 方法返回值 = 目标页 `pop(result:)` 传入的 result

    /// 压入新页并等待其 `pop(result:)`；返回值即该 result。
    @discardableResult
    public func pushNamed(_ name: String, args: [String: Any] = [:]) async -> [String: Any]? {
        guard let settings = appendRoute(name, args: args) else { return nil }
        return await settings.waitForResult()
    }

    /// 先 pop 当前页（`result` 交给**被替换页**的 await），再 push 新页。
    /// - Returns: **新页** 之后 `pop(result:)` 的值（不是参数 `result`）。
    @discardableResult
    public func pushReplacementNamed(
        _ name: String,
        args: [String: Any] = [:],
        result: [String: Any]? = nil
    ) async -> [String: Any]? {
        if canPop { pop(result: result) }
        return await pushNamed(name, args: args)
    }

    /// 先 `popUntil`，再 push 新页。
    /// - Parameter result: 交给最后一次被 pop 掉的那一页的 await。
    /// - Returns: **新页** 之后 `pop(result:)` 的值。
    @discardableResult
    public func pushNamedAndRemoveUntil(
        _ name: String,
        _ predicate: @escaping RoutePredicate,
        args: [String: Any] = [:],
        result: [String: Any]? = nil
    ) async -> [String: Any]? {
        popUntil(predicate, result: result)
        return await pushNamed(name, args: args)
    }

    /// - Parameter count: 多级 pop 便捷参数。
    /// - Parameter result: 回传给**栈顶**被移除页的 `await pushNamed`。
    public func pop(count: Int = 1, result: [String: Any]? = nil) {
        guard routeTabs.indices.contains(selectedTab) else { return }
        let popCount = min(count, path.count, routeTabs[selectedTab].count)
        guard popCount > 0 else { return }

        var stack = routeTabs[selectedTab]
        let removed = Array(stack.suffix(popCount))
        stack.removeLast(popCount)
        routeTabs[selectedTab] = stack

        // 仅栈顶（removed 末项）带 result；其余 complete(nil)
        for (index, settings) in removed.enumerated() {
            settings.complete(with: index == removed.count - 1 ? result : nil)
        }

        var nextPath = path
        nextPath.removeLast(popCount)
        var paths = pathTabs
        paths[selectedTab] = nextPath
        pathTabs = paths
        notifyListeners(from: removed.last, to: stack.last)
        log(prefix: "pop >>> ")
    }

    /// 回退直到 `predicate` 为 true（该页保留）；未命中则清空栈。
    /// - Parameter result: 交给最后一次被 pop 掉的栈顶页。
    public func popUntil(_ predicate: @escaping RoutePredicate, result: [String: Any]? = nil) {
        guard routeTabs.indices.contains(selectedTab) else { return }
        let stack = routeTabs[selectedTab]
        guard !stack.isEmpty else { return }
        if let top = stack.last, predicate(top.name) { return }

        var popCount = 0
        for entry in stack.reversed() {
            if predicate(entry.name) { break }
            popCount += 1
        }
        if popCount > 0 {
            pop(count: popCount, result: result)
        }
    }

    // MARK: - Private

    @discardableResult
    private func appendRoute(_ name: String, args: [String: Any]) -> RouteSettings? {
        guard containsRoute(name) else {
            dlog("⚠️ Route not found: \(name)")
            return nil
        }

        let settings = RouteSettings(name: name, args: args.isEmpty ? nil : args)
        let from = routeTabs[selectedTab].last

        var nextRoutes = routeTabs[selectedTab]
        nextRoutes.append(settings)
        routeTabs[selectedTab] = nextRoutes

        var nextPath = path
        nextPath.append(settings)
        var paths = pathTabs
        paths[selectedTab] = nextPath
        pathTabs = paths

        notifyListeners(from: from, to: settings)
        log(prefix: "pushNamed >>> ")
        return settings
    }

    /// 仅用于系统手势改 path：补齐 routeTabs，并以 nil complete（无业务 result）
    private func syncStacks(withPathCount pathCount: Int, tab: Int) {
        guard routeTabs.indices.contains(tab) else { return }
        guard routeTabs[tab].count > pathCount else { return }
        let removed = Array(routeTabs[tab].suffix(from: pathCount))
        for settings in removed {
            settings.complete(with: nil)
        }
        routeTabs[tab] = Array(routeTabs[tab].prefix(pathCount))
        notifyListeners(from: removed.last, to: routeTabs[tab].last)
    }

    private func log(prefix: String = "") {
        let depths = pathTabs.enumerated().map { "\($0.offset)_\($0.element.count)" }
        dlog("\(prefix) tab:\(selectedTab) path: \(depths.joined(separator: ",")), routes: \(routes)")
    }
}

// MARK: - Destination

extension View {
    /// 挂载 `RouteSettings` destination；页面构建由外部传入
    public func navigatorDestination(
        @ViewBuilder destination: @escaping (RouteSettings) -> some View
    ) -> some View {
        navigationDestination(for: RouteSettings.self) { settings in
            destination(settings)
                .environment(\.routeSettings, settings)
        }
    }

    /// 路由变化监听。进入注册；**被新页盖住仍保留**；本页 `RouteSettings` 出栈（pop）后销毁。
    public func onRouteChange(_ handler: @escaping RouteChangeHandler) -> some View {
        modifier(RouteChangeListenerModifier(handler: handler))
    }
}

/// 子页级路由监听：栈内存活期间保持，避免 push 盖住后收不到返回事件。
private struct RouteChangeListenerModifier: ViewModifier {
    @Environment(\.routeSettings) private var routeSettings
    let handler: RouteChangeHandler
    @State private var box = ListenerTokenBox()

    func body(content: Content) -> some View {
        content
            .onAppear { registerIfNeeded() }
            .onDisappear { unregisterIfRouteGone() }
    }

    private func registerIfNeeded() {
        guard box.id == nil else { return }
        let mySettings = routeSettings
        let id = NavigatorShort.addListener { from, to in
            handler(from, to)
            if let mySettings, from === mySettings {
                NavigatorShort.removeListener(id)
                box.id = nil
            }
        }
        box.id = id
    }

    private func unregisterIfRouteGone() {
        guard let id = box.id else { return }
        if let settings = routeSettings {
            guard !NavigatorShort.shared.pageRoutes.contains(where: { $0 === settings }) else { return }
        } else {
            guard NavigatorShort.shared.pageRoutes.isEmpty else { return }
        }
        NavigatorShort.removeListener(id)
        box.id = nil
    }
}

/// `@State` 可写的监听 token 盒子（便于在回调里置空）
private final class ListenerTokenBox {
    var id: RouteListenerID?
}
