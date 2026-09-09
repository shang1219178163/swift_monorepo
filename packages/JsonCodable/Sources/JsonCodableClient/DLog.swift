import Foundation

/// 示例日志（始终输出，便于 Debug / Release 启动配置验证）。
///
/// 格式：`[日期时间 类名.函数名 Line:行]: 日志内容`
func dlog(
    _ items: Any...,
    file: String = #fileID,
    function: String = #function,
    line: Int = #line
) {
    let message = items.map { String(describing: $0) }.joined(separator: " ")
    let fileName = file.split(separator: "/").last.map(String.init) ?? file
    let className = fileName.replacingOccurrences(of: ".swift", with: "")
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let timestamp = formatter.string(from: Date())
    print("[\(timestamp) \(className).\(function) Line:\(line)]: \(message)")
}
