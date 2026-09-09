# JsonCodable

Swift 宏驱动的 `Codable` 增强库：用 `@Codable` / `@CodingKey` 生成编解码实现，支持 JSON key 别名、缺省默认值，并提供 `Data` / 字典 ⇄ 模型互转。

本包位于 [swift_monorepo](https://github.com/shang1219178163/swift_monorepo) monorepo 的 `packages/JsonCodable`。

## 特性

- `@Codable`：为结构体自动生成 `Codable` 实现
- `@CodingKey`：自定义编码 key、解码别名、缺省默认值
- `fromData` / `fromJson` / `toJson`：`Data`、字典与模型互转（可传入自定义 `JSONDecoder` / `JSONEncoder`）
- `JsonCodableError`：根节点非对象等明确错误

## 要求

- Swift 6.1+
- 平台：macOS 10.15+ / iOS 13+ / tvOS 13+ / watchOS 6+ / Mac Catalyst 13+

## 安装

### 远程（推荐：依赖 monorepo 伞形包）

```swift
dependencies: [
    .package(url: "https://github.com/shang1219178163/swift_monorepo.git", from: "0.1.0")
]

.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "JsonCodable", package: "swift_monorepo")
    ]
)
```

Xcode：`File` → `Add Package Dependencies…`，填入仓库 URL，选择产品 `JsonCodable`。

### 本地路径（只依赖本包）

```swift
dependencies: [
    .package(path: "../swift_monorepo/packages/JsonCodable")
]

.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "JsonCodable", package: "JsonCodable")
    ]
)
```

Xcode 工程也可添加本地包：`File` → `Add Package Dependencies…` → `Add Local…`，选择 `packages/JsonCodable`（示例 App 见仓库 `app/example`）。

## 用法

```swift
import JsonCodable

@Codable
struct User {
    let id: Int

    @CodingKey("user_name", aliases: ["username", "name"])
    let name: String

    @CodingKey("avatar_url")
    let avatarURL: String?

    @CodingKey("age", defaultValue: 0)
    let age: Int
}

let data = Data("""
{"id":1,"username":"Alex","avatar_url":"https://example.com/a.png"}
""".utf8)

// Data → 模型
let user = try User.fromData(data)

// 字典 → 模型
let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let user2 = try User.fromJson(dict)

// 模型 → 字典
let jsonObject = try user.toJson()
```

### `@CodingKey` 参数

| 参数 | 说明 |
| --- | --- |
| `key` | 编码使用的规范 key，也是解码时优先匹配的 key |
| `aliases` | 规范 key 不存在时，按顺序尝试的备用解码 key |
| `defaultValue` | 所有 key 都缺失时使用的默认值；省略则必填（可选类型可为 `nil`） |

### JSON 辅助 API

| API | 签名要点 | 说明 |
| --- | --- | --- |
| `fromData(_:coder:)` | `(Data) throws -> Self` | JSON `Data` → 模型 |
| `fromJson(_:coder:)` | `([String: Any]) throws -> Self` | 字典 → 模型（内部转 `Data` 后走 `fromData`） |
| `toJson(coder:)` | `throws -> [String: Any]` | 模型 → 字典；根节点非对象抛 `rootNotDictionary` |

`coder` 为可选参数；传入 `nil`（默认）时使用 `JSONDecoder()` / `JSONEncoder()`。

```swift
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let user = try User.fromData(data, coder: decoder)

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970
let dict = try user.toJson(coder: encoder)
```

> 已在 `@CodingKey` 中写明 snake_case 等 key 时，不要再设 `keyDecodingStrategy = .convertFromSnakeCase`，否则键名会被二次转换导致解码失败。

### 错误类型

```swift
public enum JsonCodableError: Error, Sendable, Equatable {
    case rootNotDictionary
}
```

## 示例

### 命令行：`JsonCodableClient`

```bash
# 在本包目录
cd packages/JsonCodable
swift run JsonCodableClient

# 或在 monorepo 根目录
swift run JsonCodableClient
```

VS Code / Cursor：使用根目录 `.vscode/launch.json` 中的 `Debug/Release JsonCodableClient`（或带 `packages/JsonCodable` 后缀的配置）。

### iOS 示例 App

仓库 `app/example` 通过本地 SPM 依赖本包，演示编码（`fromData`）与解码（`toJson`）。用 Xcode 打开 `app/example/example.xcodeproj` 运行即可。修改 `packages/JsonCodable` 后需重新编译 `example` 才会带上最新代码。

## 开发

```bash
# 仅本包
cd packages/JsonCodable
swift build
swift test

# monorepo 根（伞形包，聚合测试）
cd ../..
swift build
swift test
```

变更记录见 [CHANGELOG.md](CHANGELOG.md)。

## License

[MIT](LICENSE)
