import SwiftUI
import JsonCodable

/// JsonCodable 编解码演示（中心 Tab / 路由页复用）。
struct JsonCodableDemoView: View {
    @State private var user: User?
    @State private var mode: Mode = .decode
    @State private var result: CodecResult = .idle

    private enum Mode {
        case encode
        case decode
    }

    private enum CodecResult: Equatable {
        case idle
        case success(title: String, text: String)
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Spacer(minLength: 0)
                codecButton("编码", active: mode == .encode, action: encode)
                codecButton("解码", active: mode == .decode, action: decode)
                Spacer(minLength: 0)
            }
            .padding(.horizontal)

            switch result {
            case .idle:
                Text("从 user.json 编码为模型，再解码为字典")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            case .success(let title, let text):
                Text(title)
                    .font(.subheadline.bold())
                    .padding(.horizontal)
                ScrollView {
                    Text(text)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
            case .failure(let message):
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            // 先编码拿到模型，再默认展示解码结果（解码按钮高亮）
            _ = encodeModel()
            decode()
        }
    }

    @ViewBuilder
    private func codecButton(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        if active {
            Button(title, action: action).buttonStyle(.borderedProminent)
        } else {
            Button(title, action: action).buttonStyle(.bordered)
        }
    }

    private func encode() {
        mode = .encode
        guard let encoded = encodeModel() else { return }
        result = .success(
            title: "编码结果 · \(String(describing: type(of: encoded)))",
            text: String(describing: encoded)
        )
    }

    private func decode() {
        mode = .decode
        if user == nil {
            _ = encodeModel()
        }
        guard let user else {
            result = .failure("请先编码")
            return
        }
        do {
            let dict = try user.toJson()
            result = .success(
                title: "解码结果 · \(String(describing: type(of: dict)))",
                text: String(describing: dict)
            )
        } catch {
            result = .failure("解码失败: \(error)")
        }
    }

    @discardableResult
    private func encodeModel() -> User? {
        do {
            let data = try loadUserData()
            let encoded = try User.fromData(data)
            user = encoded
            return encoded
        } catch {
            user = nil
            result = .failure("编码失败: \(error)")
            return nil
        }
    }

    private func loadUserData() throws -> Data {
        guard let url = Bundle.main.url(forResource: "user", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }
}

#Preview {
    JsonCodableDemoView()
}
