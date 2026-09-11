import Foundation
import JsonCodable

@Codable
struct Tag {
    let id: Int

    @CodingKey("tag_name", alias: ["name"])
    let name: String
}

@Codable
struct Address {
    @CodingKey("city_name", alias: ["city"])
    let city: String

    @CodingKey("zip_code", alias: ["zip"])
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

    @CodingKey("username", alias: ["user_name", "name"])
    let name: String

    @CodingKey("avatar_url", alias: ["avatar", "avatarUrl"])
    let avatar: String?

    @CodingKey("age", defaultValue: 0)
    let age: Int

    let score: Double
    let rating: Float
    let active: Bool

    @CodingKey("created_at", isTimestamp: true)
    let createdAt: Int
    
    @CodingKey("update_at", isTimestamp: true)
    let updateAt: Int?
    
    let tags: [String]
    let levels: [Int]
    let ratios: [Double]

    let profile: Profile

    @CodingKey("favorite_tags", alias: ["tags_detail"])
    let favoriteTags: [Tag]

    @CodingKey("extra", defaultValue: [String: String]())
    let extra: [String: String]
}
