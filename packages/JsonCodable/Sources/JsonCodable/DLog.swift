import Foundation

/// 包内调试日志（`package`：仅本包目标可见）。
///
/// 格式：`[日期时间 文件名.函数名 Line:行]: 日志内容`
package func dlog(
    _ items: Any...,
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
) {
    let message = items.map { String(describing: $0) }.joined(separator: " ")
    let fileName = file.split(separator: "/").last.map(String.init) ?? file
    let name = fileName.replacingOccurrences(of: ".swift", with: "")
    let timestamp = DLogDate.formatter().string(from: Date())
    print("[\(timestamp) \(name).\(function) Line:\(line)]: \(message)")
}

private enum DLogDate {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var cache: [String: DateFormatter] = [:]

    static func formatter(
        locale: Locale = .autoupdatingCurrent,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss.SSS"
    ) -> DateFormatter {
        let key = locale.identifier + "\0" + dateFormat
        lock.lock()
        defer { lock.unlock() }
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
