# Changelog

本文件记录 JsonCodable 的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.0.0] - 2026-09-10

### Fixed

- `@Codable` 对 `public` / `package` 类型生成同级访问修饰的 `init(from:)` / `encode(to:)`
- 带 `willSet` / `didSet` 的存储属性纳入编解码；多绑定属性声明给出诊断
- `@CodingKey` 非字面量 key 改为定位诊断（不再 throw）
- 测试改用 `fromJson` / `toJson` / `fromData`，并覆盖 `rootNotDictionary`、public 展开与属性观察器

### Changed

- JSON 辅助 API 重命名并调整语义：
  - `fromData(_:coder:)`：`Data` → 模型
  - `fromJson(_:coder:)`：字典 → 模型
  - `toJson(coder:)`：模型 → 字典（非 JSON 字符串；数值等可能为 `NSNumber` 桥接）
- 配置参数由闭包 `configure` 改为可选 `coder: JSONDecoder?` / `JSONEncoder?`
- 移除旧版 `encode` / `decode` / `toDict` 以及 `JsonCodableError.invalidUTF8`
- `dlog` 复用静态 `DateFormatter`；README 澄清 `defaultValue` 不覆盖 JSON `null`、`@CodingKey` 需配合 `@Codable`

### Added

- `JsonCodableClient` 使用 `user.json` 资源演示 `fromData` / `toJson`
- monorepo 示例 App `app/example` 本地依赖本包做编解码演示
- 包内 `package func dlog`（仅本包目标可见）

## [0.1.0] - 2026-09-09

### Added

- `@Codable` / `@CodingKey` 宏，支持 JSON key、别名与解码默认值
- `Encodable` / `Decodable` 扩展：初始 `encode` / `decode` / `toDict` API
- 示例可执行目标 `JsonCodableClient` 与基础宏展开测试
- `JsonCodableError`；`swift-syntax` 依赖下限 `from: "600.0.0"`
