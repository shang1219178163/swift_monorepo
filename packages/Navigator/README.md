# Navigator

SwiftUI 具名路由引擎（无业务路由表）：多 Tab `NavigationPath`、async `pushNamed` / `pop(result:)`、GetX 风格门面。

本包位于 [swift_macro](https://github.com/shang1219178163/swift_macro) monorepo 的 `packages/Navigator`。

从 `SwiftUITemplet/Router` 抽出与业务无关的部分：`Navigator`、`NavigatorShort`、`NavigationBarModifier`。业务侧自行维护路由表（如原 `AppRouter` / `AppTab`）并在启动时 `setup`。

## 要求

- iOS 16+ / Mac Catalyst 16+
- Swift 6.1+

## 安装

### 远程（伞形包）

```swift
dependencies: [
    .package(url: "https://github.com/shang1219178163/swift_macro.git", from: "0.1.0")
]

.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Navigator", package: "swift_monorepo")
    ]
)
```

### 本地路径

```swift
.package(path: "../swift_macro/packages/Navigator")
```

## 用法

```swift
import Navigator
import SwiftUI

// 1. 启动时注入（业务路由表）
NavigatorShort.setup(
    tabCount: 3,
    initialTab: 0,
    containsRoute: { name in AppRouter.contains(name) },
    preventsDuplicate: { name in AppRouter.preventDuplicates(for: name) },
    titleProvider: { name in AppRouter.page(for: name).title }
)

// 2. 根视图挂载
NavigationStack(path: navigator.pathBinding(for: tab)) {
    RootView()
        .navigatorDestination { settings in
            AppRouter.destination(settings)
        }
}
.environmentObject(NavigatorShort.shared)

// 3. 跳转 / 返回
Task {
    let result = await NavigatorShort.toNamed("/detail", args: ["id": 1])
}
NavigatorShort.back(result: ["ok": true])
```

页面内可用 `@Environment(\.routeSettings)` 取当前页参数；`navigationBarCustom(...)` 自定义导航栏。

## API 概览

| 类型 / API | 说明 |
| --- | --- |
| `Navigator` | 多 Tab 路由引擎 |
| `NavigatorShort` | 静态门面（`toNamed` / `offNamed` / `back` …） |
| `RouteSettings` / `AppPage` | 路由设置与页面注册单元 |
| `navigationBarCustom` | 自定义导航栏（标题可回落 `titleProvider`） |

## 开发

```bash
cd packages/Navigator
swift build
swift test
```

## License

[MIT](../../LICENSE)
