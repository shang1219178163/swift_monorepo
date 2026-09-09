import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct JsonCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableMacro.self,
        CodingKeyMacro.self,
    ]
}
