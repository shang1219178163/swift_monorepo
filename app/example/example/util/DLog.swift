import Foundation

/// 示例 App 调试日志。
///
/// 格式：`[日期时间 类名.函数名 Line:行]: 日志内容`
@MainActor
func dlog(
    _ items: Any...,
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
) {
    let message = items.map { String(describing: $0) }.joined(separator: " ")
    let fileName = file.split(separator: "/").last.map(String.init) ?? file
    let className = fileName.replacingOccurrences(of: ".swift", with: "")
    let timestamp = DLogDate.formatter.string(from: Date())
    print("[\(timestamp) \(className).\(function) Line:\(line)]: \(message)")
}

@MainActor
private enum DLogDate {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
