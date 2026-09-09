import JsonCodable
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(JsonCodableMacros)
import JsonCodableMacros

let testMacros: [String: Macro.Type] = [
    "Codable": CodableMacro.self,
    "CodingKey": CodingKeyMacro.self,
]
#endif

@Codable
private struct RoundTripUser {
    let id: Int

    @CodingKey("user_name", aliases: ["username", "name"])
    let name: String

    @CodingKey("age", defaultValue: 0)
    let age: Int
}

final class JsonCodableTests: XCTestCase {
    func testDecodeAliasAndDefaultValue() throws {
        let user = try RoundTripUser.encode([
            "id": 1,
            "username": "Alex",
        ])
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.name, "Alex")
        XCTAssertEqual(user.age, 0)
    }

    func testEncodeRoundTrip() throws {
        let user = RoundTripUser(id: 2, name: "Bob", age: 18)
        let dict = try user.decode()
        let encoded = try RoundTripUser.encode(dict)
        XCTAssertEqual(encoded.id, 2)
        XCTAssertEqual(encoded.name, "Bob")
        XCTAssertEqual(encoded.age, 18)
        XCTAssertEqual(dict["id"] as? Int, 2)
        XCTAssertEqual(dict["user_name"] as? String, "Bob")
        XCTAssertEqual(dict["age"] as? Int, 18)
    }

    func testBasicCodingKeyExpansion() throws {
        #if canImport(JsonCodableMacros)
        assertMacroExpansion(
            """
            @Codable
            struct User {
                let id: Int
                @CodingKey("user_name", aliases: ["username", "name"])
                let name: String
                @CodingKey("avatar_url")
                let avatarURL: String?
            }
            """,
            expandedSource: """
            struct User {
                let id: Int
                let name: String
                let avatarURL: String?
            }

            extension User: Codable {
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: AnyCodingKey.self)
                    self.id = try container.decode(
                        Int.self,
                        forKey: AnyCodingKey(stringValue: "id")
                    )
                    if container.contains(AnyCodingKey(stringValue: "user_name")) {
                        self.name = try container.decode(
                            String.self,
                            forKey: AnyCodingKey(stringValue: "user_name")
                        )
                    }
                    else if container.contains(AnyCodingKey(stringValue: "username")) {
                        self.name = try container.decode(
                            String.self,
                            forKey: AnyCodingKey(stringValue: "username")
                        )
                    }
                    else {
                        self.name = try container.decode(
                            String.self,
                            forKey: AnyCodingKey(stringValue: "name")
                        )
                    }
                    self.avatarURL = try container.decodeIfPresent(
                        String.self,
                        forKey: AnyCodingKey(stringValue: "avatar_url")
                    )
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyCodingKey.self)
                    try container.encode(
                        id,
                        forKey: AnyCodingKey(stringValue: "id")
                    )
                    try container.encode(
                        name,
                        forKey: AnyCodingKey(stringValue: "user_name")
                    )
                    try container.encodeIfPresent(
                        avatarURL,
                        forKey: AnyCodingKey(stringValue: "avatar_url")
                    )
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDefaultKeyUsesPropertyName() throws {
        #if canImport(JsonCodableMacros)
        assertMacroExpansion(
            """
            @Codable
            struct Point {
                let x: Int
                let y: Int
            }
            """,
            expandedSource: """
            struct Point {
                let x: Int
                let y: Int
            }

            extension Point: Codable {
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: AnyCodingKey.self)
                    self.x = try container.decode(
                        Int.self,
                        forKey: AnyCodingKey(stringValue: "x")
                    )
                    self.y = try container.decode(
                        Int.self,
                        forKey: AnyCodingKey(stringValue: "y")
                    )
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyCodingKey.self)
                    try container.encode(
                        x,
                        forKey: AnyCodingKey(stringValue: "x")
                    )
                    try container.encode(
                        y,
                        forKey: AnyCodingKey(stringValue: "y")
                    )
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDefaultValueExpansion() throws {
        #if canImport(JsonCodableMacros)
        assertMacroExpansion(
            """
            @Codable
            struct User {
                @CodingKey("user_name", defaultValue: "guest")
                let name: String
                @CodingKey("age", defaultValue: 0)
                let age: Int
            }
            """,
            expandedSource: """
            struct User {
                let name: String
                let age: Int
            }

            extension User: Codable {
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: AnyCodingKey.self)
                    if container.contains(AnyCodingKey(stringValue: "user_name")) {
                        self.name = try container.decode(
                            String.self,
                            forKey: AnyCodingKey(stringValue: "user_name")
                        )
                    } else {
                        self.name = "guest"
                    }
                    if container.contains(AnyCodingKey(stringValue: "age")) {
                        self.age = try container.decode(
                            Int.self,
                            forKey: AnyCodingKey(stringValue: "age")
                        )
                    } else {
                        self.age = 0
                    }
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyCodingKey.self)
                    try container.encode(
                        name,
                        forKey: AnyCodingKey(stringValue: "user_name")
                    )
                    try container.encode(
                        age,
                        forKey: AnyCodingKey(stringValue: "age")
                    )
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
