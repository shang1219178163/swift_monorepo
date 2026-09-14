/// A type-erased `CodingKey` used by `@JsonCodable` expansions for alias lookup.
public struct AnyCodingKey: Swift.CodingKey, Hashable, Sendable {
  public let stringValue: String
  public let intValue: Int?

  public init(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  public init(intValue: Int) {
    self.stringValue = String(intValue)
    self.intValue = intValue
  }
}

/// Generates `Codable` conformance for a struct.
///
/// Use `@CodingKey` on properties to customize JSON keys and alias.
///
/// ```swift
/// @JsonCodable
/// struct User {
///     let id: Int
///
///     @CodingKey("user_name", alias: ["username", "name"])
///     let name: String
///
///     @CodingKey("avatar_url")
///     let avatarURL: String?
/// }
/// ```
@attached(extension, conformances: Codable, names: named(init(from:)), named(encode(to:)))
public macro JsonCodable() = #externalMacro(module: "JsonCodableMacros", type: "CodableMacro")

/// Marks a stored property with a canonical coding key and optional decode alias.
///
/// - Parameters:
///   - key: Canonical key used for encoding and as the first decode candidate.
///   - alias: Fallback keys tried in order when the canonical key is absent.
///   - defaultValue: When set, the key (or an alias) must be present; JSON `null` uses this
///     value. A missing key throws `DecodingError.keyNotFound`. Omit to require a non-null value
///     (optionals may still decode as `nil`).
///   - isTimestamp: When `true` on an `Int`（族）属性，生成只读影子属性 `{name}Str: String?`。
///     原值为 `nil` 或 `0` 时返回 `nil`；否则按 10 位秒 / 13 位毫秒转换，取 `Date` 描述前 19 个字符。
@attached(peer, names: arbitrary)
public macro CodingKey(
  _ key: String,
  alias: [String] = [],
  defaultValue: Any? = nil,
  isTimestamp: Bool = false
) = #externalMacro(module: "JsonCodableMacros", type: "CodingKeyMacro")
