import Foundation

/// JSON 编解码辅助过程中的错误。
public enum JsonCodableError: Error, Sendable, Equatable {
  /// JSON 根节点不是对象，无法转为 `[String: Any]`。
  case rootNotDictionary
}

extension Decodable {

  /// 将 JSON `Data` 转为模型。
  ///
  /// - Parameters:
  ///   - data: UTF-8 JSON 数据。
  ///   - coder: 可选自定义 `JSONDecoder`；为 `nil` 时使用默认解码器。
  /// - Returns: 解码后的模型。
  public static func fromData(
    _ data: Data,
    coder: JSONDecoder? = nil
  ) throws -> Self {
    let decoder = coder ?? JSONDecoder()
    return try decoder.decode(Self.self, from: data)
  }

  /// 将字典转为模型。
  ///
  /// - Parameters:
  ///   - dict: JSON 对象字典。
  ///   - coder: 可选自定义 `JSONDecoder`；为 `nil` 时使用默认解码器。
  /// - Returns: 解码后的模型。
  public static func fromJson(
    _ dict: [String: Any],
    coder: JSONDecoder? = nil
  ) throws -> Self {
    let data = try JSONSerialization.data(withJSONObject: dict)
    return try fromData(data, coder: coder)
  }
}

extension Encodable {
  /// 将模型转为字典。
  ///
  /// - Parameter coder: 可选自定义 `JSONEncoder`；为 `nil` 时使用默认编码器。
  /// - Returns: `[String: Any]` 表示。
  public func toJson(
    coder: JSONEncoder? = nil
  ) throws -> [String: Any] {
    let encoder = coder ?? JSONEncoder()
    let data = try encoder.encode(self)
    let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    guard let dict = object as? [String: Any] else {
      throw JsonCodableError.rootNotDictionary
    }
    return dict
  }
}
