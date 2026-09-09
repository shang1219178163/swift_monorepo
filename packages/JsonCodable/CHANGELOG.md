# Changelog

本文件记录 JsonCodable 的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.0.0] - 2026-09-09

### Changed

- JSON 辅助 API 重命名并调整语义：
  - `fromData(_:coder:)`：`Data` → 模型
  - `fromJson(_:coder:)`：字典 → 模型
  - `toJson(coder:)`：模型 → 字典
- 配置参数由闭包 `configure` 改为可选 `coder: JSONDecoder?` / `JSONEncoder?`
- 移除旧版 `encode` / `decode` / `toDict` 以及 `JsonCodableError.invalidUTF8`

### Added

- `JsonCodableClient` 使用 `user.json` 资源演示 `fromData` / `toJson`
- monorepo 示例 App `app/example` 本地依赖本包做编解码演示

## [0.1.0] - 2026-09-09

### Added

- `@Codable` / `@CodingKey` 宏，支持 JSON key、别名与解码默认值
- `Encodable` / `Decodable` 扩展：初始 `encode` / `decode` / `toDict` API
- 示例可执行目标 `JsonCodableClient` 与基础宏展开测试
- `JsonCodableError`；`swift-syntax` 依赖下限 `from: "600.0.0"`
