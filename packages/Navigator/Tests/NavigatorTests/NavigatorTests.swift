import XCTest
@testable import Navigator

@MainActor
final class NavigatorTests: XCTestCase {
    func testInitialState() {
        let navigator = Navigator(tabCount: 2, initialTab: 1, containsRoute: { _ in true })
        XCTAssertEqual(navigator.selectedTab, 1)
        XCTAssertFalse(navigator.canPop)
        XCTAssertTrue(navigator.isStackEmpty(for: 0))
        XCTAssertNil(navigator.routeName)
    }

    func testUnknownRouteReturnsNil() async {
        let navigator = Navigator(tabCount: 1, containsRoute: { $0 == "/home" })
        let result = await navigator.pushNamed("/missing")
        XCTAssertNil(result)
        XCTAssertFalse(navigator.canPop)
        XCTAssertTrue(navigator.routes.isEmpty)
    }

    func testNavigatorShortSetup() {
        NavigatorShort.setup(
            tabCount: 2,
            initialTab: 0,
            containsRoute: { $0.hasPrefix("/") },
            preventsDuplicate: { _ in true },
            titleProvider: { name in name == "/a" ? "A" : nil }
        )
        XCTAssertEqual(NavigatorShort.titleProvider?("/a"), "A")
        XCTAssertNil(NavigatorShort.titleProvider?("/b"))
        XCTAssertEqual(NavigatorShort.shared.pathTabs.count, 2)
    }
}
