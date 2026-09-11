/// A type-erased `CodingKey` used by `@Codable` expansions for alias lookup.
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
/// Use `@CodingKey` on properties to customize JSON keys and aliases.
///
/// ```swift
/// @Codable
/// struct User {
///     let id: Int
///
///     @CodingKey("user_name", aliases: ["username", "name"])
///     let name: String
///
///     @CodingKey("avatar_url")
///     let avatarURL: String?
/// }
/// ```
@attached(extension, conformances: Codable, names: named(init(from:)), named(encode(to:)))
public macro Codable() = #externalMacro(module: "JsonCodableMacros", type: "CodableMacro")

/// Marks a stored property with a canonical coding key and optional decode aliases.
///
/// - Parameters:
///   - key: Canonical key used for encoding and as the first decode candidate.
///   - aliases: Fallback keys tried in order when the canonical key is absent.
///   - defaultValue: Value used when none of the keys are present. Omit to require the key
///     (or `nil` for optionals).
///   - isTimestamp: When `true` on an `Int`（族）属性，生成只读影子属性 `{name}Str: String?`。
///     原值为 `nil` 或 `0` 时返回 `nil`；否则按 10 位秒 / 13 位毫秒转换，取 `Date` 描述前 19 个字符。
@attached(peer, names: arbitrary)
public macro CodingKey(
    _ key: String,
    aliases: [String] = [],
    defaultValue: Any? = nil,
    isTimestamp: Bool = false
) = #externalMacro(module: "JsonCodableMacros", type: "CodingKeyMacro")
