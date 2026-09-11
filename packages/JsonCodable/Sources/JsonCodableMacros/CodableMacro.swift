import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CodableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: CodingKeyDiagnostic.onlyStructSupported
                )
            )
            return []
        }

        let properties = parseProperties(from: declaration, context: context)

        guard validate(properties, context: context) else {
            return []
        }

        let access = accessModifierPrefix(from: declaration)
        let decode = makeDecode(properties: properties, access: access)
        let encode = makeEncode(properties: properties, access: access)

        let extensionDecl = try ExtensionDeclSyntax(
            """
            extension \(type.trimmed): Codable {
            \(raw: decode)

            \(raw: encode)
            }
            """
        )

        return [extensionDecl]
    }
}

// MARK: - Model

private struct CodableProperty {
    let name: String
    let type: String
    let key: String
    let aliases: [String]
    /// Source expression for `defaultValue`, e.g. `"18"` or `"\"unknown\""`.
    let defaultValueExpression: String?
    let syntax: VariableDeclSyntax

    var allKeys: [String] { [key] + aliases }

    var isOptional: Bool {
        unwrapOptional(type).isOptional
    }

    var wrappedType: String {
        unwrapOptional(type).wrapped
    }

    var hasDefault: Bool {
        defaultValueExpression != nil
    }
}

private func unwrapOptional(_ type: String) -> (isOptional: Bool, wrapped: String) {
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

// MARK: - Parse

private extension CodableMacro {
    /// `public` / `package` 类型需生成同级可见的 Codable 见证方法。
    static func accessModifierPrefix(from declaration: some DeclGroupSyntax) -> String {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else { return "" }
        for modifier in structDecl.modifiers {
            switch modifier.name.text {
            case "public", "open":
                return "public "
            case "package":
                return "package "
            default:
                continue
            }
        }
        return ""
    }

    static func parseProperties(
        from declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) -> [CodableProperty] {
        var result: [CodableProperty] = []

        for member in declaration.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }

            if variable.modifiers.contains(where: {
                $0.name.text == "static" || $0.name.text == "class"
            }) {
                continue
            }

            if variable.bindings.count > 1 {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(variable),
                        message: CodingKeyDiagnostic.multipleBindingsNotSupported
                    )
                )
                continue
            }

            guard variable.bindings.count == 1, let binding = variable.bindings.first else {
                continue
            }

            // 计算属性（get/set）跳过；仅 willSet/didSet 的仍是存储属性，需参与编解码。
            if let accessorBlock = binding.accessorBlock, isComputedProperty(accessorBlock) {
                continue
            }

            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }

            let propertyName = identifier.identifier.text

            guard let typeAnnotation = binding.typeAnnotation else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(variable),
                        message: CodingKeyDiagnostic.propertyRequiresType(propertyName)
                    )
                )
                continue
            }

            let propertyType = typeAnnotation.type.trimmedDescription
            let codingKey = parseCodingKey(from: variable, propertyName: propertyName, context: context)

            result.append(
                CodableProperty(
                    name: propertyName,
                    type: propertyType,
                    key: codingKey.key,
                    aliases: codingKey.aliases,
                    defaultValueExpression: codingKey.defaultValueExpression,
                    syntax: variable
                )
            )
        }

        return result
    }

    /// `get`/`set`（含只读 `{ get }` / `=>`）视为计算属性；仅 `willSet`/`didSet` 则否。
    static func isComputedProperty(_ accessorBlock: AccessorBlockSyntax) -> Bool {
        switch accessorBlock.accessors {
        case .getter:
            return true
        case .accessors(let list):
            for accessor in list {
                switch accessor.accessorSpecifier.text {
                case "get", "set":
                    return true
                default:
                    continue
                }
            }
            return false
        }
    }

    static func parseCodingKey(
        from property: VariableDeclSyntax,
        propertyName: String,
        context: some MacroExpansionContext
    ) -> (key: String, aliases: [String], defaultValueExpression: String?) {
        guard let attribute = property.attributes
            .compactMap({ $0.as(AttributeSyntax.self) })
            .first(where: {
                $0.attributeName.trimmedDescription == "CodingKey"
                    || $0.attributeName.trimmedDescription.hasSuffix(".CodingKey")
            })
        else {
            return (key: propertyName, aliases: [], defaultValueExpression: nil)
        }

        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              let first = arguments.first
        else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(attribute),
                    message: CodingKeyDiagnostic.invalidCodingKey(propertyName)
                )
            )
            return (key: propertyName, aliases: [], defaultValueExpression: nil)
        }

        let key = parseStringLiteral(first.expression, context: context) ?? propertyName

        var aliases: [String] = []
        var defaultValueExpression: String?

        for argument in arguments.dropFirst() {
            switch argument.label?.text {
            case "alias":
                guard let array = argument.expression.as(ArrayExprSyntax.self) else {
                    context.diagnose(
                        Diagnostic(
                            node: Syntax(argument.expression),
                            message: CodingKeyDiagnostic.invalidAliases(propertyName)
                        )
                    )
                    continue
                }

                for element in array.elements {
                    if let alias = parseStringLiteral(element.expression, context: context) {
                        aliases.append(alias)
                    }
                }

            case "defaultValue":
                // Explicit `nil` is treated as “no default” for optionals;
                // for non-optionals it still emits `= nil` which won't compile —
                // leave that to the type checker on expanded code.
                if argument.expression.is(NilLiteralExprSyntax.self) {
                    defaultValueExpression = nil
                } else {
                    defaultValueExpression = argument.expression.trimmedDescription
                }

            default:
                continue
            }
        }

        return (key: key, aliases: aliases, defaultValueExpression: defaultValueExpression)
    }

    static func parseStringLiteral(
        _ expression: ExprSyntax,
        context: some MacroExpansionContext
    ) -> String? {
        guard let literal = expression.as(StringLiteralExprSyntax.self),
              literal.segments.count == 1,
              let segment = literal.segments.first?.as(StringSegmentSyntax.self)
        else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(expression),
                    message: CodingKeyDiagnostic.stringLiteralRequired
                )
            )
            return nil
        }
        return segment.content.text
    }
}

// MARK: - Validate

private extension CodableMacro {
    static func validate(
        _ properties: [CodableProperty],
        context: some MacroExpansionContext
    ) -> Bool {
        var seen: [String: VariableDeclSyntax] = [:]
        var ok = true

        for property in properties {
            for key in property.allKeys {
                if let previous = seen[key] {
                    context.diagnose(
                        Diagnostic(
                            node: Syntax(property.syntax),
                            message: CodingKeyDiagnostic.duplicateKey(key)
                        )
                    )
                    context.diagnose(
                        Diagnostic(
                            node: Syntax(previous),
                            message: CodingKeyDiagnostic.duplicateKey(key)
                        )
                    )
                    ok = false
                } else {
                    seen[key] = property.syntax
                }
            }
        }

        return ok
    }
}

// MARK: - Codegen

private extension CodableMacro {
    static func makeDecode(properties: [CodableProperty], access: String) -> String {
        let statements = properties.map(makeDecodeStatement(property:))
        let body = ([
            "let container = try decoder.container(keyedBy: AnyCodingKey.self)"
        ] + statements)
            .map { indent($0, by: 8) }
            .joined(separator: "\n")

        return """
            \(access)init(from decoder: Decoder) throws {
        \(body)
            }
        """
    }

    static func makeEncode(properties: [CodableProperty], access: String) -> String {
        let encodeStatements = properties.map { property -> String in
            let method = property.isOptional ? "encodeIfPresent" : "encode"
            return """
            try container.\(method)(
                \(property.name),
                forKey: AnyCodingKey(stringValue: "\(escape(property.key))")
            )
            """
        }

        let body = ([
            "var container = encoder.container(keyedBy: AnyCodingKey.self)"
        ] + encodeStatements)
            .map { indent($0, by: 8) }
            .joined(separator: "\n")

        return """
            \(access)func encode(to encoder: Encoder) throws {
        \(body)
            }
        """
    }

    static func makeDecodeStatement(property: CodableProperty) -> String {
        let keys = property.allKeys
        let decodeMethod = property.isOptional ? "decodeIfPresent" : "decode"
        let valueType = property.wrappedType

        if keys.count == 1 {
            let key = keys[0]
            if property.hasDefault {
                return """
                if container.contains(AnyCodingKey(stringValue: "\(escape(key))")) {
                    self.\(property.name) = try container.\(decodeMethod)(
                        \(valueType).self,
                        forKey: AnyCodingKey(stringValue: "\(escape(key))")
                    )
                } else {
                    self.\(property.name) = \(property.defaultValueExpression!)
                }
                """
            }

            return """
            self.\(property.name) = try container.\(decodeMethod)(
                \(valueType).self,
                forKey: AnyCodingKey(stringValue: "\(escape(key))")
            )
            """
        }

        return makeAliasDecode(property: property, keys: keys)
    }

    static func makeAliasDecode(property: CodableProperty, keys: [String]) -> String {
        let decodeMethod = property.isOptional ? "decodeIfPresent" : "decode"
        let valueType = property.wrappedType

        func decodeAssignment(_ key: String) -> String {
            """
            try container.\(decodeMethod)(
                    \(valueType).self,
                    forKey: AnyCodingKey(stringValue: "\(escape(key))")
                )
            """
        }

        var parts: [String] = []
        for (index, key) in keys.dropLast().enumerated() {
            let keyword = index == 0 ? "if" : "else if"
            parts.append(
                """
                \(keyword) container.contains(AnyCodingKey(stringValue: "\(escape(key))")) {
                    self.\(property.name) = \(decodeAssignment(key))
                }
                """
            )
        }

        let last = keys.last!
        if property.hasDefault {
            parts.append(
                """
                else if container.contains(AnyCodingKey(stringValue: "\(escape(last))")) {
                    self.\(property.name) = \(decodeAssignment(last))
                } else {
                    self.\(property.name) = \(property.defaultValueExpression!)
                }
                """
            )
        } else if property.isOptional {
            parts.append(
                """
                else if container.contains(AnyCodingKey(stringValue: "\(escape(last))")) {
                    self.\(property.name) = \(decodeAssignment(last))
                } else {
                    self.\(property.name) = nil
                }
                """
            )
        } else {
            parts.append(
                """
                else {
                    self.\(property.name) = \(decodeAssignment(last))
                }
                """
            )
        }

        return parts.joined(separator: "\n")
    }

    static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    static func indent(_ text: String, by spaces: Int) -> String {
        let pad = String(repeating: " ", count: spaces)
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { pad + $0 }
            .joined(separator: "\n")
    }
}

// MARK: - Diagnostics

private enum CodingKeyDiagnostic: DiagnosticMessage {
    case onlyStructSupported
    case propertyRequiresType(String)
    case invalidCodingKey(String)
    case invalidAliases(String)
    case duplicateKey(String)
    case multipleBindingsNotSupported
    case stringLiteralRequired

    var severity: DiagnosticSeverity { .error }

    var message: String {
        switch self {
        case .onlyStructSupported:
            return "@Codable can only be attached to a struct."
        case .propertyRequiresType(let name):
            return "Property '\(name)' requires an explicit type."
        case .invalidCodingKey(let name):
            return "Invalid @CodingKey on '\(name)'."
        case .invalidAliases(let name):
            return "Invalid alias on '\(name)'."
        case .duplicateKey(let key):
            return "Duplicate CodingKey '\(key)'."
        case .multipleBindingsNotSupported:
            return "@Codable does not support multiple bindings in one declaration; split into separate properties."
        case .stringLiteralRequired:
            return "@CodingKey requires a string literal."
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .onlyStructSupported:
            return MessageID(domain: "JsonCodableMacros", id: "onlyStructSupported")
        case .propertyRequiresType:
            return MessageID(domain: "JsonCodableMacros", id: "propertyRequiresType")
        case .invalidCodingKey:
            return MessageID(domain: "JsonCodableMacros", id: "invalidCodingKey")
        case .invalidAliases:
            return MessageID(domain: "JsonCodableMacros", id: "invalidAliases")
        case .duplicateKey:
            return MessageID(domain: "JsonCodableMacros", id: "duplicateKey")
        case .multipleBindingsNotSupported:
            return MessageID(domain: "JsonCodableMacros", id: "multipleBindingsNotSupported")
        case .stringLiteralRequired:
            return MessageID(domain: "JsonCodableMacros", id: "stringLiteralRequired")
        }
    }
}
