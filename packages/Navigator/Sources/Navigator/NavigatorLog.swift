import Foundation

/// Navigator 调试日志（受 `Navigator.isLog` 控制）。
///
/// 格式：`[日期时间 类名.函数名 Line:行]: 日志内容`
@MainActor
enum NavigatorLog {
    static func debug(
        _ items: Any...,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        guard Navigator.isLog else { return }
        let message = items.map { String(describing: $0) }.joined(separator: " ")
        let fileName = file.split(separator: "/").last.map(String.init) ?? file
        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        print("[\(timestamp) \(className).\(function) Line:\(line)]: \(message)")
    }
}
