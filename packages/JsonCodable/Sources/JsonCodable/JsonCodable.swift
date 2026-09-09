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
@attached(peer)
public macro CodingKey(
    _ key: String,
    aliases: [String] = [],
    defaultValue: Any? = nil
) = #externalMacro(module: "JsonCodableMacros", type: "CodingKeyMacro")
