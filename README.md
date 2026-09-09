# swift_monorepo

**当前版本：1.0.0**（详见 [CHANGELOG.md](CHANGELOG.md)）

Swift 宏与通用 SwiftUI 组件的 monorepo。每个可发布库放在 `packages/<Name>/`，自带独立 `Package.swift`；仓库根目录的伞形 `Package.swift` 聚合产品，供远程 SPM 依赖与统一 `swift test`。

```text
swift_monorepo/
├── Package.swift                 # 伞形包（对外产品入口）
├── packages/
│   ├── JsonCodable/              # @Codable / @CodingKey 与 JSON 辅助 API
│   └── Navigator/                # SwiftUI 具名路由引擎（无业务表）
├── third_party/
│   └── SFSafeSymbols/            # 示例 App 本地 vendored（GitHub 拉取不稳时用）
├── app/
│   └── example/                  # iOS 示例（JsonCodable / Navigator / SFSafeSymbols）
└── README.md
```

## 要求

- Swift 6.1+
- 平台随各子包声明（JsonCodable 独立包：macOS 10.15+ / iOS 13+；伞形包与 Navigator：iOS 16+ / macOS 13+）

## 安装（远程）

在应用的 `Package.swift` 中：

```swift
dependencies: [
    .package(url: "https://github.com/shang1219178163/swift_monorepo.git", from: "1.0.0")
]
```

目标依赖：

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "JsonCodable", package: "swift_monorepo"),
        .product(name: "Navigator", package: "swift_monorepo"),
    ]
)
```

## 本地开发

```bash
# 仅某个包
cd packages/JsonCodable && swift build && swift test
cd packages/Navigator && swift build && swift test

# 根目录（伞形包，跑全部已聚合测试）
swift build
swift test
```

本地路径依赖：

```swift
.package(path: "../swift_monorepo/packages/JsonCodable")
.package(path: "../swift_monorepo/packages/Navigator")
```

iOS 示例：用 Xcode 打开 `app/example/example.xcodeproj`（已本地引用 `../../packages/JsonCodable`）。修改包源码后重新编译 App 即可同步。

## 包一览

| 包 | 说明 |
| --- | --- |
| [JsonCodable](packages/JsonCodable) | `@Codable` / `@CodingKey`；`fromData` / `fromJson` / `toJson` |
| [Navigator](packages/Navigator) | 多 Tab 具名路由；`NavigatorShort` / `navigationBarCustom` |

### JsonCodable 速览

| API | 方向 |
| --- | --- |
| `Type.fromData(_:)` | `Data` → 模型 |
| `Type.fromJson(_:)` | 字典 → 模型 |
| `value.toJson()` | 模型 → 字典 |

### Navigator 速览

业务侧保留路由表（如 `AppRouter` / `AppTab`），启动时注入：

```swift
NavigatorShort.setup(
    tabCount: AppTab.count,
    containsRoute: AppRouter.contains,
    preventsDuplicate: AppRouter.preventDuplicates,
    titleProvider: { AppRouter.page(for: $0).title }
)
```

#### NavigatorShort 路由跳转

| 方法 | 含义 |
| --- | --- |
| `toNamed(_:args:)` | push；`await` 返回值 = 目标页 `back`/`pop` 的 `result` |
| `offNamed(_:args:result:)` | 替换当前页（先 pop 再 push） |
| `offAllNamed(_:args:)` | 清空当前 Tab 栈后再 push |
| `until(_:result:)` | 回退直到谓词为 true（该页保留） |
| `back(count:result:)` | 弹出一层或多层 |

```swift
let result = await NavigatorShort.toNamed("/detail", args: ["id": 1])
_ = await NavigatorShort.offNamed("/home", result: ["replaced": true])
_ = await NavigatorShort.offAllNamed("/login")
NavigatorShort.until({ $0 == "/home" })
NavigatorShort.back(count: 1, result: ["ok": true])
```

详情见 [packages/Navigator/README.md](packages/Navigator/README.md)。

## 添加新包

1. 在 `packages/<Name>/` 创建独立 SPM 包（`Package.swift`、`Sources/`、`Tests/`）。
2. 在根 `Package.swift` 增加对应 `products` / `targets`（`path` 指向该包源码目录）。
3. 更新本 README 的包列表。

## License

[MIT](LICENSE)
