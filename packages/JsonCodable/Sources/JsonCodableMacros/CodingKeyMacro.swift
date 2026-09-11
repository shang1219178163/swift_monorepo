import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Marker + optional timestamp shadow peer.
/// `@Codable` reads `@CodingKey` for coding keys; when `isTimestamp: true`, emits `{name}Str`.
public struct CodingKeyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            return []
        }

        guard isTimestamp(from: node) else {
            return []
        }

        guard variable.bindings.count == 1,
              let binding = variable.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return []
        }

        let propertyName = identifier.identifier.text

        guard let typeAnnotation = binding.typeAnnotation else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(variable),
                    message: TimestampDiagnostic.propertyRequiresType(propertyName)
                )
            )
            return []
        }

        let typeDescription = typeAnnotation.type.trimmedDescription
        let (isOptional, wrapped) = unwrapOptionalType(typeDescription)

        guard isIntType(wrapped) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(variable),
                    message: TimestampDiagnostic.requiresInt(propertyName)
                )
            )
            return []
        }

        let access = accessModifierPrefix(from: variable)
        let shadowName = "\(propertyName)Str"
        // 一律 `String?`：原值为 nil 或 0 → nil；否则 10 位秒 / 13 位毫秒 → Date 描述前 19 字。
        let unwrap: String
        if isOptional {
            unwrap = """
                    guard let __timestamp = \(propertyName), __timestamp != 0 else { return nil }
                """
        } else {
            unwrap = """
                    let __timestamp = \(propertyName)
                    guard __timestamp != 0 else { return nil }
                """
        }

        let body = """
            \(access)var \(shadowName): String? {
            \(unwrap)
                let __v = Int64(__timestamp)
                let __seconds: TimeInterval
                if String(Swift.abs(__v)).count == 13 {
                    __seconds = TimeInterval(__v) / 1000
                } else {
                    __seconds = TimeInterval(__v)
                }
                return String(String(describing: Date(timeIntervalSince1970: __seconds)).prefix(19))
            }
            """

        return [DeclSyntax(stringLiteral: body)]
    }

    private static func isTimestamp(from node: AttributeSyntax) -> Bool {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return false
        }
        for argument in arguments {
            guard argument.label?.text == "isTimestamp" else { continue }
            if let bool = argument.expression.as(BooleanLiteralExprSyntax.self) {
                return bool.literal.tokenKind == .keyword(.true)
            }
        }
        return false
    }

    private static func accessModifierPrefix(from variable: VariableDeclSyntax) -> String {
        for modifier in variable.modifiers {
            switch modifier.name.text {
            case "public", "open":
                return "public "
            case "package":
                return "package "
            case "fileprivate":
                return "fileprivate "
            case "private":
                return "private "
            default:
                continue
            }
        }
        return ""
    }

    private static func unwrapOptionalType(_ type: String) -> (isOptional: Bool, wrapped: String) {
        let trimmed = type.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix("?") {
            let wrapped = String(trimmed.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
            return (true, wrapped)
        }
        if trimmed.hasPrefix("Optional<"), trimmed.hasSuffix(">") {
            let start = trimmed.index(trimmed.startIndex, offsetBy: 9)
            let end = trimmed.index(before: trimmed.endIndex)
            return (true, String(trimmed[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return (false, trimmed)
    }

    private static func isIntType(_ type: String) -> Bool {
        switch type {
        case "Int", "Int64", "Int32", "UInt", "UInt64", "UInt32":
            return true
        default:
            return false
        }
    }
}

private enum TimestampDiagnostic: DiagnosticMessage {
    case requiresInt(String)
    case propertyRequiresType(String)

    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .requiresInt(let name):
            return "@CodingKey(isTimestamp: true) on '\(name)' requires an Int-family type."
        case .propertyRequiresType(let name):
            return "Property '\(name)' requires an explicit type."
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .requiresInt:
            return MessageID(domain: "JsonCodableMacros", id: "timestampRequiresInt")
        case .propertyRequiresType:
            return MessageID(domain: "JsonCodableMacros", id: "timestampPropertyRequiresType")
        }
    }
}
