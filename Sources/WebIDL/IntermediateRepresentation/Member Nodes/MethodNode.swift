//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class MethodNode: MemberNode, Equatable {

    let name: String
    let returnType: NodePointer
    let parameters: [ParameterNode]

    internal init(name: String, returnType: NodePointer, parameters: [ParameterNode]) {
        self.name = name
        self.returnType = returnType
        self.parameters = parameters
    }

    var isMethod: Bool {
        true
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func _swiftDeclaration(inContext context: MemberNodeContext, withImplementation: Bool) -> [String] {

        var declarations = [String]()
        var parameters = self.parameters

        var removedParameter = false
        repeat {
            removedParameter = false

            var declaration: String

            switch context {
            case .classContext:
            declaration = "public func \(name)"

            case .namespaceContext:
                declaration = "public static func \(name)"

            default:
                declaration = "func \(name)"
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

            declaration += " -> \(unwrapNode(returnType).swiftTypeName)"

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
                            returnValue = ""
                        } else {
                            returnValue = ".fromJSValue()!"
                        }

                        let argumentCount = closureNode.arguments.count
                        let closureArguments = (0 ..< argumentCount)
                            .map { "$0[\($0)].fromJSValue()!" }
                            .joined(separator: ", ")
                        return "JSClosure { \($0.label)(\(closureArguments))\(returnValue) }"
                    } else {
                        return $0.label + ".jsValue()"
                    }
                }

                if returnType.identifier == "Void" {
                    declaration += """
                     {
                    _ = objectRef.\(name)!(\(passedParameters.joined(separator: ", ")))
                    }
                    """
                } else if unwrapNode(returnType).isProtocol {
                    declaration += """
                     {
                    return objectRef.\(name)!(\(passedParameters.joined(separator: ", "))).fromJSValue()! as \(unwrapNode(returnType).typeErasedSwiftType)
                    }
                    """
                } else {
                    declaration += """
                     {
                        return objectRef.\(name)!(\(passedParameters.joined(separator: ", "))).fromJSValue()!
                    }
                    """
                }
            }

            declarations.append(declaration)

            if let index = parameters.lastIndex(where: { $0.isOmittable && $0.defaultValue == nil }) {
                parameters.removeSubrange( index ..< parameters.endIndex)
                removedParameter = true
            }
        } while removedParameter || parameters.contains(where: { $0.isOmittable && $0.defaultValue == nil })

        return declarations
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclaration(inContext: inContext, withImplementation: false)
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclaration(inContext: inContext, withImplementation: true)
    }

    static func == (lhs: MethodNode, rhs: MethodNode) -> Bool {
        lhs.name == rhs.name && lhs.returnType == rhs.returnType &&
            (lhs.parameters.count == rhs.parameters.count && zip(lhs.parameters, rhs.parameters).allSatisfy(equal))
    }
}
