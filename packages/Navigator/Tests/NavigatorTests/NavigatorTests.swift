import XCTest
@testable import Navigator

/// 测试里承接 push 结果（`[String: Any]?` 非 Sendable）。
@MainActor
private final class AwaitBox {
    var result: [String: Any]?
    var finished = false
}

@MainActor
final class NavigatorTests: XCTestCase {
    override func tearDown() {
        MainActor.assumeIsolated {
            NavigatorShort.reset()
            Navigator.isLog = false
        }
        super.tearDown()
    }

    private func waitUntil(_ predicate: () -> Bool, file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<200 {
            if predicate() { return }
            await Task.yield()
        }
        XCTFail("condition not met in time", file: file, line: line)
    }

    private func startPush(
        _ navigator: Navigator,
        _ name: String,
        args: [String: Any] = [:]
    ) -> AwaitBox {
        let box = AwaitBox()
        Task { @MainActor in
            box.result = await navigator.pushNamed(name, args: args)
            box.finished = true
        }
        return box
    }

    private func awaitFinish(_ box: AwaitBox) async -> [String: Any]? {
        await waitUntil { box.finished }
        return box.result
    }

    func testInitialState() {
        let navigator = Navigator(
            tabCount: 2,
            initialTab: 1,
            containsRoute: { _ in true },
            unknownRoute: "/unknown"
        )
        XCTAssertEqual(navigator.selectedTab, 1)
        XCTAssertFalse(navigator.canPop)
        XCTAssertTrue(navigator.isStackEmpty(for: 0))
        XCTAssertNil(navigator.routeName)
    }

    /// unknownRoute 未注册进 containsRoute 时，无法回退，返回 nil
    func testUnknownRouteNotRegisteredReturnsNil() async {
        let navigator = Navigator(
            tabCount: 1,
            containsRoute: { $0 == "/home" },
            unknownRoute: "/unknown"
        )
        let result = await navigator.pushNamed("/missing")
        XCTAssertNil(result)
        XCTAssertFalse(navigator.canPop)
        XCTAssertTrue(navigator.routes.isEmpty)
    }

    func testUnknownRouteFallsBackAndPassesArgs() async {
        let nav = Navigator(
            tabCount: 1,
            containsRoute: { $0 == "/home" || $0 == "/unknown" },
            unknownRoute: "/unknown"
        )
        let box = startPush(nav, "/missing", args: ["id": 9])
        await waitUntil { nav.canPop }
        XCTAssertEqual(nav.routes, ["/unknown"])
        XCTAssertEqual(nav.currentArgs?[NavigatorArgKey.intendedRoute] as? String, "/missing")
        XCTAssertEqual(nav.currentArgs?["id"] as? Int, 9)
        nav.pop(result: ["ok": true])
        let result = await awaitFinish(box)
        XCTAssertEqual(result?["ok"] as? Bool, true)
    }

    func testPushPopResultRoundTrip() async {
        let navigator = Navigator(
            tabCount: 1,
            containsRoute: { _ in true },
            unknownRoute: "/unknown"
        )
        let box = startPush(navigator, "/detail", args: ["id": 1])
        await waitUntil { navigator.currentSettings?.name == "/detail" }
        XCTAssertEqual(navigator.currentArgs?["id"] as? Int, 1)
        navigator.pop(result: ["ok": true])
        let result = await awaitFinish(box)
        XCTAssertEqual(result?["ok"] as? Bool, true)
        XCTAssertTrue(navigator.routes.isEmpty)
    }

    func testCompleteBeforeWaitDoesNotHang() async {
        let navigator = Navigator(
            tabCount: 1,
            containsRoute: { _ in true },
            unknownRoute: "/unknown"
        )
        _ = navigator.addListener { _, to in
            if to?.name == "/fast" {
                navigator.pop(result: ["early": true])
            }
        }
        let result = await navigator.pushNamed("/fast")
        XCTAssertEqual(result?["early"] as? Bool, true)
        XCTAssertTrue(navigator.routes.isEmpty)
    }

    func testPreventDuplicatesReturnsNil() async {
        let navigator = Navigator(
            tabCount: 1,
            containsRoute: { _ in true },
            preventsDuplicate: { _ in true },
            unknownRoute: "/unknown"
        )
        let box = startPush(navigator, "/a")
        await waitUntil { navigator.canPop }
        let skipped = await navigator.pushNamed("/a")
        XCTAssertNil(skipped)
        XCTAssertEqual(navigator.routes, ["/a"])
        navigator.pop(result: ["done": true])
        let finished = await awaitFinish(box)
        XCTAssertEqual(finished?["done"] as? Bool, true)
    }

    func testReplacementKeepsStackWhenCannotResolve() async {
        let navigator = Navigator(
            tabCount: 1,
            containsRoute: { $0 == "/a" },
            unknownRoute: "/unknown"
        )
        let box = startPush(navigator, "/a")
        await waitUntil { navigator.canPop }
        let result = await navigator.pushReplacementNamed("/missing")
        XCTAssertNil(result)
        XCTAssertEqual(navigator.routes, ["/a"])
        navigator.pop()
        _ = await awaitFinish(box)
    }

    func testReplacementFallsBackToUnknown() async {
        let navigator = Navigator(
            tabCount: 1,
            containsRoute: { $0 == "/a" || $0 == "/unknown" },
            unknownRoute: "/unknown"
        )
        let box = startPush(navigator, "/a")
        await waitUntil { navigator.canPop }
        let pending = startPushReplacement(navigator, "/gone", args: ["x": 1])
        await waitUntil { navigator.routes.last == "/unknown" }
        XCTAssertEqual(navigator.currentArgs?[NavigatorArgKey.intendedRoute] as? String, "/gone")
        XCTAssertEqual(navigator.currentArgs?["x"] as? Int, 1)
        navigator.pop()
        _ = await awaitFinish(box)
        _ = await awaitFinish(pending)
    }

    private func startPushReplacement(
        _ navigator: Navigator,
        _ name: String,
        args: [String: Any] = [:]
    ) -> AwaitBox {
        let box = AwaitBox()
        Task { @MainActor in
            box.result = await navigator.pushReplacementNamed(name, args: args)
            box.finished = true
        }
        return box
    }

    func testSelectedTabSyncsRoute() async {
        let navigator = Navigator(
            tabCount: 2,
            containsRoute: { _ in true },
            unknownRoute: "/unknown"
        )

        let b0 = startPush(navigator, "/tab0")
        await waitUntil { navigator.routeName == "/tab0" }

        navigator.selectedTab = 1
        let b1 = startPush(navigator, "/tab1")
        await waitUntil { navigator.routes == ["/tab1"] }
        XCTAssertEqual(navigator.routeName, "/tab1")

        navigator.selectedTab = 0
        XCTAssertEqual(navigator.routeName, "/tab0")
        XCTAssertEqual(navigator.pageRouteNames, ["/tab0"])

        navigator.pop()
        navigator.selectedTab = 1
        navigator.pop()
        _ = await awaitFinish(b0)
        _ = await awaitFinish(b1)
    }

    func testPopUntil() async {
        let navigator = Navigator(
            tabCount: 1,
            containsRoute: { _ in true },
            unknownRoute: "/unknown"
        )
        let b1 = startPush(navigator, "/a")
        await waitUntil { navigator.routes.count == 1 }
        let b2 = startPush(navigator, "/b")
        await waitUntil { navigator.routes.count == 2 }
        let b3 = startPush(navigator, "/c")
        await waitUntil { navigator.routes.count == 3 }

        navigator.popUntil({ $0 == "/a" }, result: ["x": 1])
        XCTAssertEqual(navigator.routes, ["/a"])

        let r3 = await awaitFinish(b3)
        let r2 = await awaitFinish(b2)
        XCTAssertEqual(r3?["x"] as? Int, 1)
        XCTAssertNil(r2)
        navigator.pop()
        _ = await awaitFinish(b1)
    }

    func testNavigatorShortSetupRequiresUnknownRoute() {
        NavigatorShort.setup(
            tabCount: 2,
            containsRoute: { $0.hasPrefix("/") },
            unknownRoute: "/unknown"
        )
        XCTAssertEqual(NavigatorShort.shared.unknownRoute, "/unknown")
        NavigatorShort.reset()
    }

    func testSwipeSyncCompletesWithNil() async {
        let navigator = Navigator(
            tabCount: 1,
            containsRoute: { _ in true },
            unknownRoute: "/unknown"
        )
        let box = startPush(navigator, "/detail")
        await waitUntil { navigator.canPop }
        var path = navigator.path
        path.removeLast()
        navigator.pathBinding(for: 0).wrappedValue = path
        let result = await awaitFinish(box)
        XCTAssertNil(result)
        XCTAssertTrue(navigator.routes.isEmpty)
    }
}
