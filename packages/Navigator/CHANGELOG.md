# Changelog

本文件记录 Navigator 的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.0.0] - 2026-09-14

### Added

- `Navigator` 多 Tab 具名路由引擎（`pushNamed` / `pop` / 监听器）
- `Get` GetX 风格门面与 `setup` 注入（由 `NavigatorShort` 重命名）
- `navigationBarCustom`（iOS / Mac Catalyst）
- 包内 `dlog` 由 `Navigator.debug` / `Get.debug` 控制（默认 `false`）
- `setup(unknownRoute:)`：未知目标回退路由（`String`，不可为空）；原目标写入 `args[intendedRoute]`
- `addTabListener` / `onTabChanged`：Tab 切换回调（`from` / `to` 为下标；`removeListener` 同时注销路由与 Tab）

### Fixed

- `RouteSettings`：`complete` 早于 `waitForResult` 时缓冲结果，避免 await 挂死
- 破坏性跳转（replacement / removeUntil）先校验路由存在再改栈
- 切 Tab 时同步 `route` / `routeName` 为当前 Tab 栈顶
- `onRouteChange` 改为依赖 `@EnvironmentObject Navigator`，不再绑死门面单例
- unknown 回退保留业务 args；原目标不同时允许再 push 以刷新参数展示
- `Get.reset()` / 按 `tabCount` 重建引擎前先 `finishPendingWaits()`，避免未决 `await` 泄漏 continuation
- `Get.setup` 再次调用会覆盖 `containsRoute` / `titleProvider`（不再只改 unknown 与防重）
- `navigationBarCustom` 标题回落改为读环境中的 `Navigator.titleProvider`

### Changed

- 路由 API 不再 `throws`：未知路由回退 `unknownRoute`；unknown 未注册或防重跳过时返回 `nil`
- `preventDuplicates` 下沉到 `Navigator.preventsDuplicate`（`Get` / 引擎共用）
- `offAllNamed` 增加可选 `result:`；新增 `Get.reset()`
- `initialTab` 范围 precondition；DEBUG 下 path 非 API 增长会 assert
- 本页环境值 `@Environment(\.routeSettings)` 重命名为 `@Environment(\.currentRoute)`
- 包内日志开关 `isLog` 重命名为 `debug`（默认 `false`；`Get.debug` 同步）
- `dlog` 按 locale + format 缓存 `DateFormatter`，locale 用 `autoupdatingCurrent`
