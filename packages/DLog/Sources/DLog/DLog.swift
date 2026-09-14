// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation

/// 调试日志。
///
/// 格式：`[日期时间 类名.函数名 Line:行]: 日志内容`
@MainActor
package func dlog(
    _ items: Any...,
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
) {
    let message = items.map { String(describing: $0) }.joined(separator: " ")
    let fileName = file.split(separator: "/").last.map(String.init) ?? file
    let className = fileName.replacingOccurrences(of: ".swift", with: "")
    let timestamp = DLogDate.formatter().string(from: Date())
    print("[\(timestamp) \(className).\(function) Line:\(line)]: \(message)")
}

@MainActor
package enum DLogDate {
    private struct Key: Hashable {
        let localeID: String
        let dateFormat: String
    }

    private static var cache: [Key: DateFormatter] = [:]

    package static func formatter(
        locale: Locale = .autoupdatingCurrent,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss.SSS"
    ) -> DateFormatter {
        let key = Key(localeID: locale.identifier, dateFormat: dateFormat)
        if let cached = cache[key] {
            return cached
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = dateFormat
        cache[key] = formatter
        return formatter
    }
}

