import Foundation
import os

extension DateFormatter {
    /// 默认格式：`yyyy-MM-dd HH:mm:ss`
    static let defaultDateFormat = "yyyy-MM-dd HH:mm:ss"

    // MARK: - Int ↔ Date

    /// 时间戳 → `Date`。绝对值 ≥ 1e12 视为毫秒，否则为秒。
    static func date(fromTimestamp timestamp: Int) -> Date {
        let seconds: TimeInterval
        if abs(timestamp) >= 1_000_000_000_000 {
            seconds = TimeInterval(timestamp) / 1000
        } else {
            seconds = TimeInterval(timestamp)
        }
        return Date(timeIntervalSince1970: seconds)
    }

    /// `Date` → 时间戳（默认秒；`milliseconds: true` 为毫秒）。
    static func timestamp(from date: Date, milliseconds: Bool = false) -> Int {
        let interval = date.timeIntervalSince1970
        if milliseconds {
            return Int((interval * 1000).rounded())
        }
        return Int(interval.rounded())
    }

    // MARK: - Date ↔ String

    static func string(
        from date: Date,
        format: String = defaultDateFormat,
        timeZone: TimeZone = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        shared(format: format, timeZone: timeZone, locale: locale)
            .string(from: date)
    }

    static func date(
        from string: String,
        format: String = defaultDateFormat,
        timeZone: TimeZone = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return shared(format: format, timeZone: timeZone, locale: locale)
            .date(from: trimmed)
    }

    // MARK: - Int ↔ String

    static func string(
        fromTimestamp timestamp: Int,
        format: String = defaultDateFormat,
        timeZone: TimeZone = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        string(
            from: date(fromTimestamp: timestamp),
            format: format,
            timeZone: timeZone,
            locale: locale
        )
    }

    static func timestamp(
        from string: String,
        format: String = defaultDateFormat,
        milliseconds: Bool = false,
        timeZone: TimeZone = .current,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> Int? {
        guard let date = date(
            from: string,
            format: format,
            timeZone: timeZone,
            locale: locale
        ) else { return nil }
        return timestamp(from: date, milliseconds: milliseconds)
    }

    // MARK: - Shared formatter (Swift 6)

    /// `DateFormatter` 非 Sendable，用 `uncheckedState` 缓存（iOS 16+）。
    private static let cache = OSAllocatedUnfairLock(
        uncheckedState: [String: DateFormatter]()
    )

    private static func shared(
        format: String,
        timeZone: TimeZone,
        locale: Locale
    ) -> DateFormatter {
        let key = "\(format)|\(timeZone.identifier)|\(locale.identifier)"
        return cache.withLock { storage in
            if let cached = storage[key] { return cached }
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = timeZone
            formatter.dateFormat = format
            storage[key] = formatter
            return formatter
        }
    }
}
