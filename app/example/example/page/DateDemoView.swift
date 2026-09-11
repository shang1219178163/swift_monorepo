import Navigator
import SwiftUI

/// Int 时间戳 / Date / 字符串 互转演示。
struct DateDemoView: View {
    @State private var format = DateFormatter.defaultDateFormat
    @State private var useMilliseconds = false

    @State private var timestampText = ""
    @State private var stringText = ""
    @State private var dateText = ""

    @State private var message: String?
    @State private var isError = false

    var body: some View {
        List {
            Section("格式") {
                TextField("日期格式", text: $format)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Toggle("时间戳用毫秒", isOn: $useMilliseconds)
            }

            Section("时间戳 (Int)") {
                TextField(useMilliseconds ? "毫秒时间戳" : "秒时间戳", text: $timestampText)
                    .keyboardType(.numbersAndPunctuation)
                    .font(.system(.body, design: .monospaced))
                HStack {
                    Button("→ Date") { timestampToDate() }
                    Button("→ 字符串") { timestampToString() }
                    Button("填现在") { fillNowTimestamp() }
                }
                .buttonStyle(.bordered)
            }

            Section("Date") {
                TextField("Date 描述 / 由转换填入", text: $dateText)
                    .font(.system(.body, design: .monospaced))
                    .disabled(true)
                HStack {
                    Button("→ 时间戳") { dateToTimestamp() }
                    Button("→ 字符串") { dateToString() }
                }
                .buttonStyle(.bordered)
            }

            Section("字符串") {
                TextField("yyyy-MM-dd HH:mm:ss", text: $stringText)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                HStack {
                    Button("→ Date") { stringToDate() }
                    Button("→ 时间戳") { stringToTimestamp() }
                }
                .buttonStyle(.bordered)
            }

            if let message {
                Section("结果") {
                    Text(message)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(isError ? .red : .primary)
                        .textSelection(.enabled)
                }
            }
            
            Button("当前时间") {
                let timeStamp = Date().timeIntervalSince1970;
                let dateStr = String(describing: Date(timeIntervalSince1970:timeStamp))
                dlog(dateStr)
            }
            
        }
        .onAppear {
            if timestampText.isEmpty {
                fillNowTimestamp()
                timestampToDate()
                timestampToString()
            }
        }
    }

    // MARK: - Actions

    private func fillNowTimestamp() {
        let ts = DateFormatter.timestamp(from: Date(), milliseconds: useMilliseconds)
        timestampText = String(ts)
        showOK("已填入当前时间戳: \(ts)")
    }

    private func timestampToDate() {
        guard let ts = parseTimestamp() else { return }
        let date = DateFormatter.date(fromTimestamp: ts)
        dateText = String(describing: date)
        showOK("timestamp → Date\n\(dateText)")
    }

    private func timestampToString() {
        guard let ts = parseTimestamp() else { return }
        let text = DateFormatter.string(fromTimestamp: ts, format: format)
        stringText = text
        dateText = String(describing: DateFormatter.date(fromTimestamp: ts))
        showOK("timestamp → String\n\(text)")
    }

    private func dateToTimestamp() {
        guard let date = resolveCurrentDate() else {
            showError("请先由时间戳或字符串得到 Date")
            return
        }
        let ts = DateFormatter.timestamp(from: date, milliseconds: useMilliseconds)
        timestampText = String(ts)
        showOK("Date → timestamp\n\(ts)")
    }

    private func dateToString() {
        guard let date = resolveCurrentDate() else {
            showError("请先由时间戳或字符串得到 Date")
            return
        }
        let text = DateFormatter.string(from: date, format: format)
        stringText = text
        showOK("Date → String\n\(text)")
    }

    private func stringToDate() {
        guard let date = DateFormatter.date(from: stringText, format: format) else {
            showError("字符串无法按「\(format)」解析")
            return
        }
        dateText = String(describing: date)
        showOK("String → Date\n\(dateText)")
    }

    private func stringToTimestamp() {
        guard let ts = DateFormatter.timestamp(
            from: stringText,
            format: format,
            milliseconds: useMilliseconds
        ) else {
            showError("字符串无法按「\(format)」解析")
            return
        }
        timestampText = String(ts)
        if let date = DateFormatter.date(from: stringText, format: format) {
            dateText = String(describing: date)
        }
        showOK("String → timestamp\n\(ts)")
    }

    // MARK: - Helpers

    private func parseTimestamp() -> Int? {
        let trimmed = timestampText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ts = Int(trimmed) else {
            showError("时间戳必须是整数")
            return nil
        }
        return ts
    }

    /// 优先用当前时间戳字段还原 Date；否则用字符串。
    private func resolveCurrentDate() -> Date? {
        if let ts = Int(timestampText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return DateFormatter.date(fromTimestamp: ts)
        }
        return DateFormatter.date(from: stringText, format: format)
    }

    private func showOK(_ text: String) {
        isError = false
        message = text
    }

    private func showError(_ text: String) {
        isError = true
        message = text
    }
}

#Preview {
    NavigationStack {
        DateDemoView()
            .navigationBarCustom(title: "日期互转")
    }
}
