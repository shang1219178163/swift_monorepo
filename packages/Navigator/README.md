# Navigator

**当前版本：1.0.0**（详见 [CHANGELOG.md](CHANGELOG.md)）

SwiftUI 具名路由引擎（无业务路由表）：多 Tab `NavigationPath`、async `pushNamed` / `pop(result:)`、GetX 风格门面。

本包位于 [swift_monorepo](https://github.com/shang1219178163/swift_monorepo) monorepo 的 `packages/Navigator`。

从 `SwiftUITemplet/Router` 抽出与业务无关的部分：`Navigator`、`Get`、`NavigationBarModifier`。业务侧自行维护路由表（如原 `AppRouter` / `AppTab`）并在启动时 `setup`。

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
Get.setup(
    tabCount: 3,
    initialTab: 0,
    containsRoute: { name in AppRouter.contains(name) },
    preventsDuplicate: { name in AppRouter.preventDuplicates(for: name) },
    titleProvider: { name in AppRouter.page(for: name).title },
    unknownRoute: "/unknown"
)

// 2. 根视图挂载
NavigationStack(path: navigator.pathBinding(for: tab)) {
    RootView()
        .navigatorDestination { settings in
            AppRouter.destination(settings)
        }
}
.environmentObject(Get.shared)

// 3. 跳转 / 返回（见下方「路由跳转方法」）
Task {
    let result = await Get.toNamed("/detail", args: ["id": 1])
}
Get.back(result: ["ok": true])
```

页面内用 `@Environment(\.routeSettings)` 取当前页参数。

**返回值约定：**

- 页面已打开：`async` 返回值 = 目标页 `pop(result:)` / `back(result:)`；侧滑或未带 result 时为 `nil`
- 目标路由不存在：跳转 `unknownRoute`（必填），并把原目标名写入 `args[NavigatorArgKey.intendedRoute]`，其余 args 原样保留；若 unknown 本身未注册进 `containsRoute`，则返回 `nil`
- 防重跳过：直接返回 `nil`（不抛错）

## 路由跳转方法

日常推荐用 `Get`（GetX 风格）；需要细粒度控制时用 `Get.shared`（即 `Navigator`）。须先 `setup`；`onRouteChange` / `navigationBarCustom` 依赖 `@EnvironmentObject` 中的同一引擎实例。

### 对照表

| Get | Navigator | 含义 |
| --- | --- | --- |
| `toNamed(_:args:)` | `pushNamed(_:args:)` | 压入新页，挂起直到该页 `pop`/`back` |
| `offNamed(_:args:result:)` | `pushReplacementNamed(_:args:result:)` | 先校验再 pop 当前页，再 push |
| `offAllNamed(_:args:result:)` | `pushNamedAndRemoveUntil(_: { _ in false }, …)` | 清空当前 Tab 栈后 push |
| — | `pushNamedAndRemoveUntil(_:_:args:result:)` | 先 `popUntil`，再 push |
| `until(_:result:)` | `popUntil(_:result:)` | 回退直到谓词为 true（该页保留） |
| `back(count:result:)` | `pop(count:result:)` | 弹出一层或多层 |

### Get

```swift
Get.setup(
    tabCount: 3,
    containsRoute: AppRouter.contains,
    unknownRoute: "/unknown"   // 不存在的路由 → 此页
)

let result = await Get.toNamed("/detail", args: ["id": 1])
// 不存在时：等价于 toNamed("/unknown", args: ["id": 1, "intendedRoute": "/nope"])

_ = await Get.offNamed("/home", result: ["replaced": true])
_ = await Get.offAllNamed("/login", result: ["cleared": true])
Get.until({ $0 == "/home" }, result: ["from": "settings"])
Get.back(count: 2, result: ["ok": true])
```

### Navigator（引擎）

```swift
let nav = Get.shared

_ = await nav.pushNamed("/detail", args: ["id": 1])

_ = await nav.pushReplacementNamed(
    "/other",
    args: [:],
    result: ["bye": true]
)

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
NavigationStack(path: Get.shared.pathBinding(for: tab)) {
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
| `route` / `routePre` | 焦点路由 / 切换前路由（切 Tab 会同步为该 Tab 栈顶） |
| `routeName` / `routeNamePre` | 同上的路由名 |
| `pageRouteNames` / `routes` | **当前选中 Tab** 路由名栈（自底向顶） |
| `canPop` | 当前 Tab 是否可 pop |
| `currentSettings` / `currentArgs` | 当前 Tab 栈顶（本页优先用 `@Environment(\.routeSettings)`） |
| `isStackEmpty(for:)` | 指定 Tab 栈是否为空 |
| `isLog` | 是否打印路由日志 |
| `unknownRoute` | 必填；目标不存在时的回退路由名（非空） |
| `NavigatorArgKey.intendedRoute` | 回退时写入 args 的原目标键 |
| `Get.reset()` | 清空引擎（测试 / Preview） |

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
