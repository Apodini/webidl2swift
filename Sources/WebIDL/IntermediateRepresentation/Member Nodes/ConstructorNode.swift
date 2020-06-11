//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class ConstructorNode: MemberNode, Equatable {

    let className: String
    let parameters: [ParameterNode]

    internal init(className: String, parameters: [ParameterNode]) {
        self.className = className
        self.parameters = parameters
    }

    var isConstructor: Bool {
        true
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    private func _swiftDeclaration(inContext: MemberNodeContext, withImplementation: Bool) -> [String] {

        var declarations = [String]()
        var parameters = self.parameters

        var removedParameter = false
        repeat {
            removedParameter = false

            var declaration: String

            if case .classContext = inContext {
                declaration = "public convenience init"
            } else {
                declaration = "convenience init"
            }

            var typeConstraints = [String]()
            var parameterDeclarations = [String]()

            for parameter in parameters {

                let dataTypeNode = unwrapNode(parameter.dataType)
                var type: String
                if dataTypeNode.isProtocol {
                    if dataTypeNode.isOptional {
                        type = "\(dataTypeNode.nonOptionalTypeName)Type?"
                        typeConstraints.append("\(dataTypeNode.nonOptionalTypeName)Type: \(dataTypeNode.nonOptionalTypeName)")
                    } else {
                        type = "\(dataTypeNode.swiftTypeName)Type"
                        typeConstraints.append("\(type): \(dataTypeNode.swiftTypeName)")
                    }
                } else if dataTypeNode.isClosure {
                    type = "@escaping \(dataTypeNode.swiftTypeName)"
                } else {
                    type = dataTypeNode.swiftTypeName
                }

                if parameter.isVariadic {
                    type += "..."
                }

                if let defaultValue = parameter.defaultValue {
                    let value: String
                    if let enumNode = defaultValue.dataType.node as? EnumerationWithRawValueNode {
                        let trimmedDefaultValue = defaultValue.value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        if enumNode.cases.contains(trimmedDefaultValue) {
                            // swiftlint:disable:next force_unwrapping
                            value = "." + String(trimmedDefaultValue.first!.lowercased() + trimmedDefaultValue.dropFirst())
                        } else {
                            fatalError("Invalid default value \(trimmedDefaultValue) for enum \(defaultValue.dataType.identifier)")
                        }
                    } else {
                        value = defaultValue.value
                    }

                    parameterDeclarations.append("\(parameter.label): \(type) = \(value)")
                } else {
                    parameterDeclarations.append("\(parameter.label): \(type)")
                }
            }

            if !typeConstraints.isEmpty {

                declaration += "<\(typeConstraints.joined(separator: ", "))>"
            }

            declaration += "(\(parameterDeclarations.joined(separator: ", ")))"

            if withImplementation {

                let passedParameters: [String] = parameters.map {
                    let dataTypeNode = unwrapNode($0.dataType)
                    if dataTypeNode.isClosure {

                        let closureNode: ClosureNode
                        if let cNode = dataTypeNode as? ClosureNode {
                             closureNode = cNode
                        } else if let aliasNode = dataTypeNode as? AliasNode, let cNode = aliasNode.aliased as? ClosureNode {
                            closureNode = cNode
                        } else if let aliasNode = dataTypeNode as? AliasNode, let optionalNode = aliasNode.aliased as? OptionalNode, let cNode = optionalNode.wrapped.node as? ClosureNode {
                            closureNode = cNode
                        } else {
                            fatalError("Unknown closure type.")
                        }

                        let returnValue: String
                        if closureNode.returnType.identifier == "Void" {
                            returnValue = "; return .undefined"
                        } else {
                            returnValue = ".fromJSValue()"
                        }

                        let argumentCount = closureNode.arguments.count
                        let closureArguments = (0 ..< argumentCount)
                            .map { "$0[\($0)].fromJSValue()" }
                            .joined(separator: ", ")
                        return "JSFunctionRef.from({ \($0.label)(\(closureArguments))\(returnValue) })"
                    } else {
                        return $0.label + ".jsValue()"
                    }
                }
                declaration += """
                 {
                    self.init(objectRef: \(className).classRef.new(\(passedParameters.joined(separator: ", "))))
                }
                """
            }

            declarations.append(declaration)

            if let index = parameters.lastIndex(where: { $0.isOmittable && $0.defaultValue == nil }) {
                parameters.removeSubrange( index ..< parameters.endIndex)
                removedParameter = true
            }
        } while removedParameter || parameters.contains(where: { $0.isOmittable && $0.defaultValue == nil })

        return declarations
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclaration(inContext: inContext, withImplementation: false)
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclaration(inContext: inContext, withImplementation: true)
    }

    static func == (lhs: ConstructorNode, rhs: ConstructorNode) -> Bool {
        lhs.className == rhs.className && (lhs.parameters.count == rhs.parameters.count && zip(lhs.parameters, rhs.parameters).allSatisfy(equal))
    }
}
