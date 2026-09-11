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

@Codable
private struct TimestampEvent {
    @CodingKey("created_at", isTimestamp: true)
    let createdAt: Int
}

/// 编码结果为 JSON 数组根节点，用于触发 `rootNotDictionary`。
private struct JSONArrayRoot: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(1)
    }
}

private func jsonInt(_ value: Any?) -> Int? {
    if let int = value as? Int { return int }
    if let number = value as? NSNumber { return number.intValue }
    return nil
}

final class JsonCodableTests: XCTestCase {
    func testFromJsonAliasAndDefaultValue() throws {
        let user = try RoundTripUser.fromJson([
            "id": 1,
            "username": "Alex",
        ])
        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.name, "Alex")
        XCTAssertEqual(user.age, 0)
    }

    func testToJsonRoundTrip() throws {
        let user = RoundTripUser(id: 2, name: "Bob", age: 18)
        let dict = try user.toJson()
        let encoded = try RoundTripUser.fromJson(dict)
        XCTAssertEqual(encoded.id, 2)
        XCTAssertEqual(encoded.name, "Bob")
        XCTAssertEqual(encoded.age, 18)
        XCTAssertEqual(jsonInt(dict["id"]), 2)
        XCTAssertEqual(dict["user_name"] as? String, "Bob")
        XCTAssertEqual(jsonInt(dict["age"]), 18)
    }

    func testFromDataAndRootNotDictionary() throws {
        let data = Data(#"{"id":3,"user_name":"Cara","age":21}"#.utf8)
        let user = try RoundTripUser.fromData(data)
        XCTAssertEqual(user.id, 3)
        XCTAssertEqual(user.name, "Cara")
        XCTAssertEqual(user.age, 21)

        XCTAssertThrowsError(try JSONArrayRoot().toJson()) { error in
            XCTAssertEqual(error as? JsonCodableError, .rootNotDictionary)
        }
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

    func testPublicAccessExpansion() throws {
        #if canImport(JsonCodableMacros)
        assertMacroExpansion(
            """
            @Codable
            public struct User {
                public let id: Int
            }
            """,
            expandedSource: """
            public struct User {
                public let id: Int
            }

            extension User: Codable {
                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: AnyCodingKey.self)
                    self.id = try container.decode(
                        Int.self,
                        forKey: AnyCodingKey(stringValue: "id")
                    )
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyCodingKey.self)
                    try container.encode(
                        id,
                        forKey: AnyCodingKey(stringValue: "id")
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

    func testPropertyObserversIncludedInExpansion() throws {
        #if canImport(JsonCodableMacros)
        assertMacroExpansion(
            """
            @Codable
            struct Counter {
                var count: Int {
                    didSet {}
                }
            }
            """,
            expandedSource: """
            struct Counter {
                var count: Int {
                    didSet {}
                }
            }

            extension Counter: Codable {
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: AnyCodingKey.self)
                    self.count = try container.decode(
                        Int.self,
                        forKey: AnyCodingKey(stringValue: "count")
                    )
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyCodingKey.self)
                    try container.encode(
                        count,
                        forKey: AnyCodingKey(stringValue: "count")
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

    func testTimestampShadowPropertyExpansion() throws {
        #if canImport(JsonCodableMacros)
        assertMacroExpansion(
            """
            @Codable
            struct Event {
                @CodingKey("created_at", isTimestamp: true)
                let createdAt: Int
                @CodingKey("updated_at", isTimestamp: true)
                let updatedAt: Int?
            }
            """,
            expandedSource: """
            struct Event {
                let createdAt: Int

                var createdAtStr: String? {
                    let __timestamp = createdAt
                    guard __timestamp != 0 else {
                        return nil
                    }
                    let __v = Int64(__timestamp)
                    let __seconds: TimeInterval
                    if String(Swift.abs(__v)).count == 13 {
                        __seconds = TimeInterval(__v) / 1000
                    } else {
                        __seconds = TimeInterval(__v)
                    }
                    return String(String(describing: Date(timeIntervalSince1970: __seconds)).prefix(19))
                }
                let updatedAt: Int?

                var updatedAtStr: String? {
                    guard let __timestamp = updatedAt, __timestamp != 0 else {
                        return nil
                    }
                    let __v = Int64(__timestamp)
                    let __seconds: TimeInterval
                    if String(Swift.abs(__v)).count == 13 {
                        __seconds = TimeInterval(__v) / 1000
                    } else {
                        __seconds = TimeInterval(__v)
                    }
                    return String(String(describing: Date(timeIntervalSince1970: __seconds)).prefix(19))
                }
            }

            extension Event: Codable {
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: AnyCodingKey.self)
                    self.createdAt = try container.decode(
                        Int.self,
                        forKey: AnyCodingKey(stringValue: "created_at")
                    )
                    self.updatedAt = try container.decodeIfPresent(
                        Int.self,
                        forKey: AnyCodingKey(stringValue: "updated_at")
                    )
                }

                func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: AnyCodingKey.self)
                    try container.encode(
                        createdAt,
                        forKey: AnyCodingKey(stringValue: "created_at")
                    )
                    try container.encodeIfPresent(
                        updatedAt,
                        forKey: AnyCodingKey(stringValue: "updated_at")
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

    func testTimestampShadowRuntimeValue() throws {
        let seconds = try TimestampEvent.fromJson(["created_at": 1_725_772_800])
        XCTAssertEqual(seconds.createdAtStr?.count, 19)
        XCTAssertEqual(
            seconds.createdAtStr,
            JsonTimestamp.string(fromTimestamp: 1_725_772_800)
        )

        let zero = try TimestampEvent.fromJson(["created_at": 0])
        XCTAssertNil(zero.createdAtStr)

        let millis = 1_725_772_800_000
        XCTAssertEqual(
            JsonTimestamp.string(fromTimestamp: millis),
            JsonTimestamp.string(fromTimestamp: 1_725_772_800)
        )
        XCTAssertTrue(JsonTimestamp.isTimestampValue(1_725_772_800))
        XCTAssertTrue(JsonTimestamp.isTimestampValue(millis))
        XCTAssertFalse(JsonTimestamp.isTimestampValue(42))
    }
}
