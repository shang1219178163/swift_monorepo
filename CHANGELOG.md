# Changelog

本文件记录 swift_monorepo 伞形包的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026-09-09

### Added

- 伞形 SPM 聚合产品：`JsonCodable`、`JsonCodableClient`、`Navigator`
- `JsonCodable`：`@Codable` / `@CodingKey` 宏；`fromData` / `fromJson` / `toJson` JSON 辅助 API
- `Navigator`：多 Tab 具名路由引擎、`NavigatorShort` 门面、`navigationBarCustom`
- iOS 示例 `app/example`：本地依赖 JsonCodable / Navigator，并 vendored `SFSafeSymbols` 6.2.0
- 根目录 `LICENSE`（MIT）与包级文档；Navigator / 根 README 列出全部 `NavigatorShort` 跳转 API

### Changed

- JsonCodable JSON 辅助 API 由早期 `encode` / `decode` / `toDict` 调整为 `fromData` / `fromJson` / `toJson`
- JsonCodable / Navigator 调试日志统一为包内 `package func dlog`（外部不可见；Navigator 仍受 `isLog` 控制）
