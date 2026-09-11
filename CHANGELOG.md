# Changelog

本文件记录 swift_monorepo 伞形包的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026-09-11

### Added

- 伞形 SPM 聚合产品：`JsonCodable`、`JsonCodableClient`、`Navigator`
- `JsonCodable`：`@Codable` / `@CodingKey` 宏；`fromData` / `fromJson` / `toJson`；`isTimestamp` 影子属性 `{name}Str`
- `Navigator`：多 Tab 具名路由引擎、`Get` 门面、`navigationBarCustom`、必填 `unknownRoute` 回退
- iOS 示例 `app/example`：JsonCodable / Navigator / 日期互转 demo；Swift 6.1；vendored `SFSafeSymbols` 6.2.0
- 根目录 `LICENSE`（MIT）与包级文档

### Fixed

- JsonCodable：`public`/`package` 宏展开访问级、属性观察器编解码、测试与 `fromJson`/`toJson` 对齐
- Navigator：`complete` 缓冲、破坏性跳转先校验、Tab 切换同步栈顶、unknown 回退保留参数
- 示例：推入页补 `navigationBarCustom`，避免系统默认返回键

### Changed

- JsonCodable：`aliases` → `alias`；JSON 辅助 API 为 `fromData` / `fromJson` / `toJson`
- JsonCodable / Navigator 调试日志为包内 `package func dlog`
- Navigator 路由 API 不再 `throws`；门面 `NavigatorShort` → `Get`
