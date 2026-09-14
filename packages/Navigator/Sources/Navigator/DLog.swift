import Foundation

/// 包内调试日志，受 `Navigator.debug` / `Get.debug` 控制。
///
/// 格式：`[日期时间 文件名.函数名 Line:行]: 日志内容`
@MainActor
package func dlog(
    _ items: Any...,
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
) {
    guard Navigator.debug else { return }
    let message = items.map { String(describing: $0) }.joined(separator: " ")
    let fileName = file.split(separator: "/").last.map(String.init) ?? file
    let name = fileName.replacingOccurrences(of: ".swift", with: "")
    let timestamp = DLogDate.formatter().string(from: Date())
    print("[\(timestamp) \(name).\(function) Line:\(line)]: \(message)")
}

@MainActor
private enum DLogDate {
    private static var cache: [String: DateFormatter] = [:]

    static func formatter(
        locale: Locale = .autoupdatingCurrent,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss.SSS"
    ) -> DateFormatter {
        let key = locale.identifier + "\0" + dateFormat
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
