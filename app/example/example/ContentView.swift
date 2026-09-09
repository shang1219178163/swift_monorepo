//
//  ContentView.swift
//  example
//
//  Created by Bin Shang on 2026/9/9.
//

import SwiftUI
import JsonCodable

private enum CodecResult: Equatable {
    case idle
    case success(title: String, text: String)
    case failure(String)
}

struct ContentView: View {
    @State private var user: User?
    @State private var result: CodecResult = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Spacer(minLength: 0)
                Button("编码", action: encode)
                    .buttonStyle(.borderedProminent)
                Button("解码", action: decode)
                    .buttonStyle(.bordered)
                Spacer(minLength: 0)
            }

            switch result {
            case .idle:
                EmptyView()
            case .success(let title, let text):
                Text(title).font(.headline)
                ScrollView {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            case .failure(let message):
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

    /// Data → 模型
    private func encode() {
        do {
            let data = try loadUserData()
            let encoded = try User.fromData(data)
            user = encoded
            result = .success(
                title: "编码结果 · \(String(describing: type(of: encoded)))",
                text: String(describing: encoded)
            )
        } catch {
            user = nil
            result = .failure("编码失败: \(error)")
        }
    }

    /// 模型 → 字典
    private func decode() {
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

    private func loadUserData() throws -> Data {
        guard let url = Bundle.main.url(forResource: "user", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }
}

#Preview {
    ContentView()
}
