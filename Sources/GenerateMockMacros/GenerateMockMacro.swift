import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct GenerateMockMacro: MemberMacro {
    private struct Closure {
        let attributes: AttributeListSyntax?
        let identifier: TokenSyntax
        let functionType: FunctionTypeSyntax
        let isPublic: Bool

        struct Argument {
            let name: String
            let argValuesName: String?
            let type: String
            let hasTrailingComma: Bool
        }

        var arguments: [Argument] {
            functionType.parameters.enumerated().map { index, parameter in
                Argument(
                    name: parameter.secondName?.description ?? "arg\(index)",
                    argValuesName: (functionType.parameters.count >= 2) ? parameter.secondName?.description : nil,
                    type: "\(parameter.type)",
                    hasTrailingComma: (index < functionType.parameters.count - 1)
                )
            }
        }

        var returnStmt: String {
            var result = "return"
            result += (functionType.effectSpecifiers?.throwsSpecifier != nil) ? " try" : ""
            result += (functionType.effectSpecifiers?.asyncSpecifier != nil) ? " await" : ""
            return result
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw CustomError.message("macro can only be applied to structs")
        }

        let isPublicStruct = structDecl.modifiers.contains(where: { $0.name.text == "public" })

        let closures = structDecl.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .compactMap { variable -> Closure? in
                guard let binding = variable.bindings.first,
                      let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self)
                else { return nil }

                let isPublic = variable.modifiers.contains(where: { $0.name.text == "public" })

                if let functionType = binding.typeAnnotation?.type.as(FunctionTypeSyntax.self) {
                    return Closure(
                        attributes: nil,
                        identifier: identifierPattern.identifier,
                        functionType: functionType,
                        isPublic: isPublic
                    )
                }

                if let attributedType = binding.typeAnnotation?.type.as(AttributedTypeSyntax.self),
                   let functionType = attributedType.baseType.as(FunctionTypeSyntax.self)
                {
                    return Closure(
                        attributes: attributedType.attributes,
                        identifier: identifierPattern.identifier,
                        functionType: functionType,
                        isPublic: isPublic
                    )
                }

                return nil
            }

        return [
            DeclSyntax(
                FunctionDeclSyntax(
                    modifiers: DeclModifierListSyntax(
                        (isPublicStruct ? [DeclModifierSyntax(name: "public")] : []) +
                        [DeclModifierSyntax(name: "static")]
                    ),
                    name: "mock",
                    signature: FunctionSignatureSyntax(
                        parameterClause: FunctionParameterClauseSyntax(
                            parameters: FunctionParameterListSyntax([
                                FunctionParameterSyntax(stringLiteral: "_ mock: Mock")
                            ])
                        ),
                        returnClause: ReturnClauseSyntax(
                            type: IdentifierTypeSyntax(name: "Self")
                        )
                    ),
                    body: CodeBlockSyntax(
                        statements: CodeBlockItemListSyntax([
                            CodeBlockItemSyntax(stringLiteral: "Self(\(closures.map(\.identifier).map { "\($0): mock.\($0)" }.joined(separator: ", ")))")
                        ])
                    )
                )
            ),
            DeclSyntax(
                ClassDeclSyntax(
                    modifiers: DeclModifierListSyntax([DeclModifierSyntax(name: "open")]),
                    name: "Mock",
                    memberBlock: MemberBlockSyntax(
                        members: MemberBlockItemListSyntax(
                            [
                                MemberBlockItemSyntax(
                                    decl: InitializerDeclSyntax(
                                        modifiers: DeclModifierListSyntax(isPublicStruct ? [DeclModifierSyntax(name: "public")] : []),
                                        signature: FunctionSignatureSyntax(
                                            parameterClause: FunctionParameterClauseSyntax(
                                                parameters: FunctionParameterListSyntax(closures.enumerated().map { index, closure in
                                                    FunctionParameterSyntax(
                                                        firstName: TokenSyntax(stringLiteral: "\(closure.identifier)Handler"),
                                                        type: AttributedTypeSyntax(
                                                            attributes: AttributeListSyntax([
                                                                .attribute(
                                                                    AttributeSyntax(
                                                                        attributeName: TypeSyntax(stringLiteral: "escaping"),
                                                                        trailingTrivia: .space
                                                                    )
                                                                )
                                                            ]),
                                                            baseType: closure.functionType
                                                        ),
                                                        defaultValue: InitializerClauseSyntax(
                                                            value: FunctionCallExprSyntax(
                                                                calledExpression: ExprSyntax(stringLiteral: "unimplemented"),
                                                                leftParen: .leftParenToken(),
                                                                arguments: LabeledExprListSyntax([
                                                                    LabeledExprSyntax(
                                                                        expression: StringLiteralExprSyntax(
                                                                            content: "\(structDecl.name.trimmedDescription).Mock.\(closure.identifier)Handler"
                                                                        )
                                                                    )
                                                                ]),
                                                                rightParen: .rightParenToken()
                                                            )
                                                        ),
                                                        trailingComma: (index < closures.count - 1) ? .commaToken() : nil
                                                    )
                                                })
                                            )
                                        ),
                                        body: CodeBlockSyntax(
                                            statements: CodeBlockItemListSyntax(closures.map { closure in
                                                CodeBlockItemSyntax(
                                                    stringLiteral: "self.\(closure.identifier)Handler = \(closure.identifier)Handler"
                                                )
                                            })
                                        )
                                    )
                                )
                            ] + closures.flatMap { closure in
                                [
                                    MemberBlockItemSyntax(
                                        decl: VariableDeclSyntax(
                                            modifiers: DeclModifierListSyntax(
                                                (closure.isPublic ? [DeclModifierSyntax(name: "public")] : []) +
                                                [DeclModifierSyntax(name: "private", detail: DeclModifierDetailSyntax(detail: "set"))]
                                            ),
                                            .var,
                                            name: "\(closure.identifier)CallCount",
                                            initializer: InitializerClauseSyntax(
                                                value: IntegerLiteralExprSyntax(0)
                                            )
                                        )
                                    ),
                                    MemberBlockItemSyntax(
                                        decl: VariableDeclSyntax(
                                            modifiers: DeclModifierListSyntax(
                                                (closure.isPublic ? [DeclModifierSyntax(name: "public")] : []) +
                                                [DeclModifierSyntax(name: "private", detail: DeclModifierDetailSyntax(detail: "set"))]
                                            ),
                                            .var,
                                            name: "\(closure.identifier)ArgValues",
                                            type: TypeAnnotationSyntax(
                                                type: ArrayTypeSyntax(
                                                    element: TupleTypeSyntax(
                                                        elements: TupleTypeElementListSyntax(
                                                            closure.arguments.map { argument in
                                                                TupleTypeElementSyntax(
                                                                    firstName: argument.argValuesName.map(TokenSyntax.init(stringLiteral:)),
                                                                    colon: argument.argValuesName.map { _ in .colonToken() },
                                                                    type: IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: argument.type)),
                                                                    trailingComma: argument.hasTrailingComma ? .commaToken() : nil
                                                                )
                                                            }
                                                        )
                                                    )
                                                )
                                            ),
                                            initializer: InitializerClauseSyntax(
                                                value: ArrayExprSyntax(elements: [])
                                            )
                                        )
                                    ),
                                    MemberBlockItemSyntax(
                                        decl: VariableDeclSyntax(
                                            modifiers: closure.isPublic ? [DeclModifierSyntax(name: "public")] : [],
                                            .var,
                                            name: "\(closure.identifier)Handler",
                                            type: TypeAnnotationSyntax(type: closure.functionType)
                                        )
                                    ),
                                    MemberBlockItemSyntax(
                                        decl: FunctionDeclSyntax(
                                            attributes: closure.attributes ?? AttributeListSyntax(),
                                            modifiers: DeclModifierListSyntax([
                                                DeclModifierSyntax(name: "fileprivate")
                                            ]),
                                            name: closure.identifier,
                                            signature: FunctionSignatureSyntax(
                                                parameterClause: FunctionParameterClauseSyntax(
                                                    parameters: FunctionParameterListSyntax(
                                                        closure.arguments.map { argument in
                                                            FunctionParameterSyntax(
                                                                firstName: .wildcardToken(),
                                                                secondName: .identifier(argument.name),
                                                                type: IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: argument.type)),
                                                                trailingComma: argument.hasTrailingComma ? .commaToken() : nil
                                                            )
                                                        }
                                                    )
                                                ),
                                                effectSpecifiers: FunctionEffectSpecifiersSyntax(
                                                    asyncSpecifier: closure.functionType.effectSpecifiers?.asyncSpecifier,
                                                    throwsSpecifier: closure.functionType.effectSpecifiers?.throwsSpecifier
                                                ),
                                                returnClause: ReturnClauseSyntax(type: IdentifierTypeSyntax(name: "\(closure.functionType.returnClause.type)"))
                                            ),
                                            body: CodeBlockSyntax(
                                                statements: CodeBlockItemListSyntax([
                                                    CodeBlockItemSyntax(stringLiteral: "\(closure.identifier)CallCount += 1"),
                                                    CodeBlockItemSyntax(stringLiteral: "\(closure.identifier)ArgValues.append((\(closure.arguments.map(\.name).joined(separator: ", "))))"),
                                                    CodeBlockItemSyntax(stringLiteral: "\(closure.returnStmt) \(closure.identifier)Handler(\(closure.arguments.map(\.name).joined(separator: ", ")))")
                                                ])
                                            )
                                        )
                                    )
                                ]
                            }
                        )
                    )
                )
            )
        ]
    }
}

@main
struct GenerateMockPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GenerateMockMacro.self,
    ]
}

enum CustomError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let text):
            return text
        }
    }
}
