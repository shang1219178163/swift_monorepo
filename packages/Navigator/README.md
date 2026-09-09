# Navigator

SwiftUI 具名路由引擎（无业务路由表）：多 Tab `NavigationPath`、async `pushNamed` / `pop(result:)`、GetX 风格门面。

本包位于 [swift_monorepo](https://github.com/shang1219178163/swift_monorepo) monorepo 的 `packages/Navigator`。

从 `SwiftUITemplet/Router` 抽出与业务无关的部分：`Navigator`、`NavigatorShort`、`NavigationBarModifier`。业务侧自行维护路由表（如原 `AppRouter` / `AppTab`）并在启动时 `setup`。

## 要求

- iOS 16+ / Mac Catalyst 16+
- Swift 6.1+

## 安装

### 远程（伞形包）

```swift
dependencies: [
    .package(url: "https://github.com/shang1219178163/swift_monorepo.git", from: "1.0.0")
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
.package(path: "../swift_monorepo/packages/Navigator")
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

// 3. 跳转 / 返回（见下方「路由跳转方法」）
Task {
    let result = await NavigatorShort.toNamed("/detail", args: ["id": 1])
}
NavigatorShort.back(result: ["ok": true])
```

页面内用 `@Environment(\.routeSettings)` 取当前页参数；`async` 跳转的返回值 = 目标页 `pop(result:)` / `back(result:)` 传入的字典（侧滑返回则为 `nil`）。

## 路由跳转方法

日常推荐用 `NavigatorShort`（GetX 风格）；需要细粒度控制时用 `NavigatorShort.shared`（即 `Navigator`）。

### 对照表

| NavigatorShort | Navigator | 含义 |
| --- | --- | --- |
| `toNamed(_:args:)` | `pushNamed(_:args:)` | 压入新页，挂起直到该页 `pop`/`back` |
| `offNamed(_:args:result:)` | `pushReplacementNamed(_:args:result:)` | 先 pop 当前页，再 push 新页 |
| `offAllNamed(_:args:)` | `pushNamedAndRemoveUntil(_: { _ in false }, args:)` | 清空当前 Tab 栈后 push |
| — | `pushNamedAndRemoveUntil(_:_:args:result:)` | 先 `popUntil`，再 push |
| `until(_:result:)` | `popUntil(_:result:)` | 回退直到谓词为 true（该页保留） |
| `back(count:result:)` | `pop(count:result:)` | 弹出一层或多层 |

### NavigatorShort

```swift
// push，并可拿到目标页返回值
let result = await NavigatorShort.toNamed("/detail", args: ["id": 1])

// 替换当前页（result 交给被替换页的 await）
let next = await NavigatorShort.offNamed(
    "/home",
    args: [:],
    result: ["replaced": true]
)

// 清栈再进新页
_ = await NavigatorShort.offAllNamed("/login")

// 回退到栈中第一个满足条件的路由（该路由保留）
NavigatorShort.until({ $0 == "/home" }, result: ["from": "settings"])

// 返回上一页（可多级）；result 交给栈顶被移除页的 await
NavigatorShort.back()
NavigatorShort.back(count: 2, result: ["ok": true])
```

### Navigator（引擎）

```swift
let nav = NavigatorShort.shared

_ = await nav.pushNamed("/detail", args: ["id": 1])

_ = await nav.pushReplacementNamed(
    "/other",
    args: [:],
    result: ["bye": true]   // → 被替换页
)

// 保留谓词为 true 的页，再 push
_ = await nav.pushNamedAndRemoveUntil(
    "/checkout",
    { $0 == "/cart" },
    args: ["sku": "A1"],
    result: ["cleared": true]
)

nav.popUntil({ $0.hasPrefix("/tab") }, result: nil)
nav.pop(count: 1, result: ["ok": true])
```

### 挂载与监听（配合跳转）

| API | 说明 |
| --- | --- |
| `navigatorDestination(destination:)` | 在 `NavigationStack` 上挂载 `RouteSettings` destination |
| `onRouteChange(_:)` | 本页级路由变化监听（出栈后自动注销） |
| `addListener` / `removeListener` | 全局监听；返回 `RouteListenerID` |
| `pathBinding(for:)` | 某 Tab 的 `NavigationPath` 绑定 |

```swift
NavigationStack(path: NavigatorShort.shared.pathBinding(for: tab)) {
    RootView()
        .navigatorDestination { AppRouter.destination($0) }
        .onRouteChange { from, to in
            print("\(from?.name ?? "root") → \(to?.name ?? "root")")
        }
}
```

### 状态只读（跳转后可查）

| API | 说明 |
| --- | --- |
| `route` / `routePre` | 当前 / 上一路由 `RouteSettings` |
| `routeName` / `routeNamePre` | 当前 / 上一路由名 |
| `pageRouteNames` / `routes` | 当前 Tab 路由名栈（自底向顶） |
| `canPop` | 当前 Tab 是否可 pop |
| `currentSettings` / `currentArgs` | 栈顶设置 / 参数（本页优先用 `@Environment(\.routeSettings)`） |
| `isStackEmpty(for:)` | 指定 Tab 栈是否为空 |
| `isLog` | 是否打印路由日志 |

## 其它类型

| 类型 / API | 说明 |
| --- | --- |
| `RouteSettings` | `name` + `args`；`waitForResult` / `complete` |
| `AppPage` | 具名路由 + `@ViewBuilder` 页面（`preventDuplicates`） |
| `navigationBarCustom` | 自定义导航栏（标题可回落 `titleProvider`） |

## 开发

```bash
cd packages/Navigator
swift build
swift test
```

## License

[MIT](../../LICENSE)
