import SwiftSyntax
import SwiftSyntaxMacros

/// Marker macro. `@Codable` reads `@CodingKey` attributes from properties.
public struct CodingKeyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
