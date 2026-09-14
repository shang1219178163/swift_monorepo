import Foundation
import JsonCodable

@JsonCodable
struct Tag: Equatable {
  let id: Int

  @CodingKey("tag_name", alias: ["name"])
  let name: String
}

@JsonCodable
struct Address: Equatable {
  @CodingKey("city_name", alias: ["city"])
  let city: String

  @CodingKey("zip_code", alias: ["zip"])
  let zip: String?

  let latitude: Double
  let longitude: Double
}

@JsonCodable
struct Profile: Equatable {
  let bio: String

  @CodingKey("is_verified", defaultValue: false)
  let isVerified: Bool

  @CodingKey("follower_count", defaultValue: 0)
  let followerCount: Int

  let address: Address
}

@JsonCodable
struct User: Equatable {
  let id: Int

  @CodingKey("username", alias: ["user_name", "name"])
  let name: String

  @CodingKey("avatar_url", alias: ["avatar", "avatarUrl"])
  let avatar: String?

  @CodingKey("age", defaultValue: 18)
  let age: Int?

  let score: Double
  let rating: Float
  let active: Bool

  @CodingKey("created_at", isTimestamp: true)
  let createdAt: Int

  let tags: [String]
  let levels: [Int]
  let ratios: [Double]

  let profile: Profile

  @CodingKey("favorite_tags", alias: ["tags_detail"])
  let favoriteTags: [Tag]

  @CodingKey("extra", defaultValue: [String: String]())
  let extra: [String: String]
}

do {
  let jsonURL = Bundle.module.url(forResource: "user", withExtension: "json")!
  let data = try Data(contentsOf: jsonURL)
  let user = try User.fromData(data)
  dlog("fromData:", user)

  let dictNew = try user.toJson()
  dlog("toJson:", dictNew)

  let userNew = try User.fromJson(dictNew)
  dlog("user == userNew:", user == userNew ? "true" : "false")
  dlog("name:", userNew.name)
  dlog("age:", userNew.age ?? "nil")
  dlog("createdAtStr:", userNew.createdAtStr ?? "nil")
} catch {
  dlog("error:", error)
  exit(1)
}
