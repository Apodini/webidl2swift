//
//  Created by Manuel Burghard on 19.04.20.
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
        return true
    }

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

                let dataTypeNode = parameter.dataType.node!
                let type: String
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
                parameterDeclarations.append("\(parameter.label): \(type)")
            }

            if !typeConstraints.isEmpty {

                declaration += "<\(typeConstraints.joined(separator: ", "))>"
            }

            declaration += "(\(parameterDeclarations.joined(separator: ", ")))"

            if withImplementation {

                let passedParameters: [String] = parameters.map {
                    let dataTypeNode = $0.dataType.node!
                    if dataTypeNode.isClosure {

                        let closureNode: ClosureNode
                        if let cNode = dataTypeNode as? ClosureNode {
                             closureNode = cNode
                        } else if let aliasNode = dataTypeNode as? AliasNode, let cNode = aliasNode.aliased as? ClosureNode {
                            closureNode = cNode
                        } else if let aliasNode = dataTypeNode as? AliasNode, let optionalNode = aliasNode.aliased as? OptionalNode, let cNode = optionalNode.wrapped.node as? ClosureNode {
                            closureNode = cNode
                        } else {
                            fatalError()
                        }

                        let rt: String
                        if closureNode.returnType.identifier == "Void" {
                            rt = "; return .undefined"
                        } else {
                            rt = ".fromJSValue()"
                        }

                        let argumentCount = closureNode.arguments.count
                        let closureArguments = (0 ..< argumentCount).map {
                            "$0[\($0)].fromJSValue()"
                        }.joined(separator: ", ")
                        return "JSFunctionRef.from({ \($0.label)(\(closureArguments))\(rt) })"
                    } else {
                        return $0.label + ".jsValue()"
                    }
                }
                declaration += """
                 {
                    self.init(objectRef: JSObjectRef.global.\(className).function!.new(\(passedParameters.joined(separator: ", "))))
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

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        return _swiftDeclaration(inContext: inContext, withImplementation: false)
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        return _swiftDeclaration(inContext: inContext, withImplementation: true)
    }

    static func == (lhs: ConstructorNode, rhs: ConstructorNode) -> Bool {
        return lhs.className == rhs.className && (lhs.parameters.count == rhs.parameters.count && zip(lhs.parameters, rhs.parameters).allSatisfy(equal))
    }
}
