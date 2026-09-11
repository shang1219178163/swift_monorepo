import Foundation
import JsonCodable

@Codable
struct Tag {
  let id: Int

  @CodingKey("tag_name", aliases: ["name"])
  let name: String
}

@Codable
struct Address {
  @CodingKey("city_name", aliases: ["city"])
  let city: String

  @CodingKey("zip_code", aliases: ["zip"])
  let zip: String?

  let latitude: Double
  let longitude: Double
}

@Codable
struct Profile {
  let bio: String

  @CodingKey("is_verified", defaultValue: false)
  let isVerified: Bool

  @CodingKey("follower_count", defaultValue: 0)
  let followerCount: Int

  let address: Address
}

@Codable
struct User {
  let id: Int

  @CodingKey("username", aliases: ["user_name", "name"])
  let name: String

  @CodingKey("avatar_url", aliases: ["avatar", "avatarUrl"])
  let avatar: String?

  @CodingKey("age", defaultValue: 0)
  let age: Int

  let score: Double
  let rating: Float
  let active: Bool

  @CodingKey("created_at", isTimestamp: true)
  let createdAt: Int

  let tags: [String]
  let levels: [Int]
  let ratios: [Double]

  let profile: Profile

  @CodingKey("favorite_tags", aliases: ["tags_detail"])
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

  let again = try User.fromJson(dictNew)
  dlog("fromJson:", again.name)
  dlog("createdAtStr:", again.createdAtStr)
} catch {
  dlog("error:", error)
  exit(1)
}
