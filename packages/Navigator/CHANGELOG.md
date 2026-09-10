# Changelog

本文件记录 Navigator 的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.0.0] - 2026-09-09

### Added

- `Navigator` 多 Tab 具名路由引擎（`pushNamed` / `pop` / 监听器）
- `Get` GetX 风格门面与 `setup` 注入
- `navigationBarCustom`（iOS / Mac Catalyst）
- 包内 `dlog` 调试日志（`Navigator.isLog` 开关；外部不可见）
- `setup(unknownRoute:)`：未知目标回退路由（`String`，不可为空）；原目标写入 `args[intendedRoute]`

### Fixed

- `RouteSettings`：`complete` 早于 `waitForResult` 时缓冲结果，避免 await 挂死
- 破坏性跳转（replacement / removeUntil）先校验路由存在再改栈
- 切 Tab 时同步 `route` / `routeName` 为当前 Tab 栈顶
- `onRouteChange` 改为依赖 `@EnvironmentObject Navigator`，不再绑死 Short 单例
- unknown 回退保留业务 args；原目标不同时允许再 push 以刷新参数展示

### Changed

- 路由 API 不再 `throws`：未知路由回退 `unknownRoute`；unknown 未注册或防重跳过时返回 `nil`
- `preventDuplicates` 下沉到 `Navigator.preventsDuplicate`（Short / 引擎共用）
- `offAllNamed` 增加可选 `result:`；新增 `Get.reset()`
- `initialTab` 范围 precondition；DEBUG 下 path 非 API 增长会 assert
