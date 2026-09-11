import Foundation

/// Int 时间戳 → 展示字符串（供 `@CodingKey(isTimestamp:)` 影子属性使用）。
///
/// 位数约定：
/// - **10 位**：秒（`timeIntervalSince1970`）
/// - **13 位**：毫秒（先 `/ 1000` 再转 `Date`）
public enum JsonTimestamp: Sendable {
    /// `String(describing: Date(...))` 的前 19 个字符，形如 `2024-09-08 00:00:00`。
    public static func string(fromTimestamp timestamp: some BinaryInteger) -> String {
        let seconds = timeInterval(fromTimestamp: timestamp)
        return String(String(describing: Date(timeIntervalSince1970: seconds)).prefix(19))
    }

    /// 按位数得到秒级 `TimeInterval`。
    public static func timeInterval(fromTimestamp timestamp: some BinaryInteger) -> TimeInterval {
        let value = Int64(timestamp)
        let digits = decimalDigitCount(of: abs(value))
        if digits == 13 {
            return TimeInterval(value) / 1000
        }
        // 10 位及其它：按秒
        return TimeInterval(value)
    }

    /// 是否符合常见时间戳位数（10 位秒或 13 位毫秒）。
    public static func isTimestampValue(_ timestamp: some BinaryInteger) -> Bool {
        let digits = decimalDigitCount(of: abs(Int64(timestamp)))
        return digits == 10 || digits == 13
    }

    private static func decimalDigitCount(of value: Int64) -> Int {
        if value == 0 { return 1 }
        var n = value
        var count = 0
        while n > 0 {
            n /= 10
            count += 1
        }
        return count
    }
}
