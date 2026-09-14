import XCTest

@testable import DLog

@MainActor
final class DLogTests: XCTestCase {
    func testFormatterCacheReusesSameLocaleAndFormat() {
        let locale = Locale(identifier: "en_US")
        let format = "yyyy-MM-dd HH:mm:ss.SSS"
        let first = DLogDate.formatter(locale: locale, dateFormat: format)
        let second = DLogDate.formatter(locale: locale, dateFormat: format)
        XCTAssertTrue(first === second)
    }

    func testFormatterCacheDiffersByLocale() {
        let format = "yyyy-MM-dd"
        let en = DLogDate.formatter(locale: Locale(identifier: "en_US"), dateFormat: format)
        let zh = DLogDate.formatter(locale: Locale(identifier: "zh_CN"), dateFormat: format)
        XCTAssertFalse(en === zh)
    }

    func testFormatterCacheDiffersByDateFormat() {
        let locale = Locale(identifier: "en_US")
        let a = DLogDate.formatter(locale: locale, dateFormat: "yyyy-MM-dd")
        let b = DLogDate.formatter(locale: locale, dateFormat: "HH:mm:ss")
        XCTAssertFalse(a === b)
    }

    func testFormatterAppliesDateFormat() {
        let formatter = DLogDate.formatter(
            locale: Locale(identifier: "en_US"),
            dateFormat: "'fixed'"
        )
        XCTAssertEqual(formatter.string(from: Date()), "fixed")
    }

    func testDlogDoesNotThrow() {
        dlog("DLogTests")
    }
}
