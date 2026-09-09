# swift_macro

Swift 宏相关库的 monorepo。每个可发布库放在 `packages/<Name>/`，自带独立 `Package.swift`；仓库根目录的伞形 `Package.swift` 聚合产品，供远程 SPM 依赖与统一 `swift test`。

```text
swift_macro/
├── Package.swift                 # 伞形包（对外产品入口）
├── packages/
│   └── JsonCodable/              # @Codable / @CodingKey 与 JSON 辅助 API
├── app/
│   └── example/                  # iOS 示例（本地依赖 JsonCodable）
└── README.md
```

## 要求

- Swift 6.1+
- 平台随各子包声明（JsonCodable：macOS 10.15+ / iOS 13+ 等）

## 安装（远程）

在应用的 `Package.swift` 中：

```swift
dependencies: [
    .package(url: "https://github.com/shang1219178163/swift_macro.git", from: "0.1.0")
]
```

目标依赖：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "JsonCodable", package: "swift-macro")
    ]
)
```

## 本地开发

```bash
# 仅某个包
cd packages/JsonCodable
swift build
swift test
swift run JsonCodableClient

# 根目录（伞形包，跑全部已聚合测试）
swift build
swift test
```

本地路径依赖某个包：

```swift
.package(path: "../swift_macro/packages/JsonCodable")
```

iOS 示例：用 Xcode 打开 `app/example/example.xcodeproj`（已本地引用 `../../packages/JsonCodable`）。修改包源码后重新编译 App 即可同步。

## JsonCodable 速览

| API | 方向 |
| --- | --- |
| `Type.fromData(_:)` | `Data` → 模型 |
| `Type.fromJson(_:)` | 字典 → 模型 |
| `value.toJson()` | 模型 → 字典 |

详情见 [packages/JsonCodable/README.md](packages/JsonCodable/README.md)。

## 添加新包

1. 在 `packages/<Name>/` 创建独立 SPM 包（`Package.swift`、`Sources/`、`Tests/`）。
2. 在根 `Package.swift` 增加对应 `products` / `targets`（`path` 指向该包源码目录）。
3. 更新本 README 的包列表。

## 包一览

| 包 | 说明 |
| --- | --- |
| [JsonCodable](packages/JsonCodable) | `@Codable` / `@CodingKey` 宏；`fromData` / `fromJson` / `toJson` |

## License

[MIT](LICENSE)
