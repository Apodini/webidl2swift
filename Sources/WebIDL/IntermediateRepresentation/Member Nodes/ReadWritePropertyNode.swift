//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

class ReadWritePropertyNode: PropertyNode, Equatable {

    let name: String
    let dataType: NodePointer

    internal init(name: String, dataType: NodePointer) {
        self.name = name
        self.dataType = dataType
    }

    var isProperty: Bool {
        return true
    }

    func initializationStatement(forContext context: MemberNodeContext) -> String? {

        guard context == .classContext, !dataType.node!.isProtocol else {
            return nil
        }

        let dataTypeNode = dataType.node!

        if dataTypeNode.isClosure && dataTypeNode.numberOfClosureArguments == 1 {
            return """
            _\(name) = \(dataTypeNode.isOptional ? "OptionalClosureHandler" : "ClosureHandler")(objectRef: objectRef, name: "\(name)")
            """
        } else {
            return """
            _\(name) = ReadWriteAttribute(objectRef: objectRef, name: "\(name)")
            """
        }
    }

    private func _swiftDeclarations(inContext: MemberNodeContext) -> String {

        let declaration: String

        let dataTypeNode = dataType.node!

        switch inContext {
        case .classContext where dataTypeNode.isProtocol:
            return "public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"

        case .classContext where dataTypeNode.isClosure && dataTypeNode.isOptional && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @OptionalClosureHandler
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case .classContext where dataTypeNode.isClosure && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @ClosureHandler
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case .classContext:
            declaration = """
            @ReadWriteAttribute
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case .protocolContext, .extensionContext, .structContext:
            declaration = "var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"
        }

        return declaration
    }

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        return [_swiftDeclarations(inContext: inContext)]
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        let dataTypeNode = dataType.node!
        switch inContext {
        case .classContext where dataTypeNode.isProtocol,
             .protocolContext where dataTypeNode.isProtocol,
             .extensionContext where dataTypeNode.isProtocol,
             .structContext where dataTypeNode.isProtocol:
            return [
                _swiftDeclarations(inContext: inContext) + """
                 {
                    get {
                        return objectRef.\(name).fromJSValue() as \(dataTypeNode.typeErasedSwiftType)
                    }
                    set {
                        objectRef.\(name) = newValue.jsValue()
                    }
                }
                """
        ]

        case .classContext where dataTypeNode.numberOfClosureArguments <= 1:
            return [_swiftDeclarations(inContext: inContext)]

        case .protocolContext where dataTypeNode.isOptional && dataTypeNode.isClosure,
             .extensionContext where dataTypeNode.isOptional && dataTypeNode.isClosure,
             .structContext where dataTypeNode.isOptional && dataTypeNode.isClosure,
             .classContext where dataTypeNode.isOptional && dataTypeNode.isClosure:
            let getterArguments = (0 ..< dataTypeNode.numberOfClosureArguments).map({ "arg\($0)" }).joined(separator: ", ")
            let setterArguments = (0 ..< dataTypeNode.numberOfClosureArguments).map({ "arguments[\($0)].fromJSValue()" }).joined(separator: ", ")
            return [
                _swiftDeclarations(inContext: inContext) + """
                 {
                    get {
                        guard let function = objectRef[dynamicMember: "\(name)"] as JSFunctionRef? else {
                            return nil
                        }
                        return { (\(getterArguments)) in function.dynamicallyCall(withArguments: [\(getterArguments)]).fromJSValue() }
                    }
                    set {
                        if let newValue = newValue {
                            objectRef[dynamicMember: "\(name)"] = JSFunctionRef.from({ arguments in
                                return newValue(\(setterArguments)).jsValue()
                            }).jsValue()
                        } else {
                            objectRef[dynamicMember: "\(name)"] = .null
                        }
                    }
                }
                """
            ]

        case .protocolContext where dataTypeNode.isClosure,
             .extensionContext where dataTypeNode.isClosure,
             .structContext where dataTypeNode.isClosure,
             .classContext:
            let getterArguments = (0 ..< dataTypeNode.numberOfClosureArguments).map({ "arg\($0)" }).joined(separator: ", ")
            let setterArguments = (0 ..< dataTypeNode.numberOfClosureArguments).map({ "arguments[\($0)].fromJSValue()" }).joined(separator: ", ")
            return [
                 _swiftDeclarations(inContext: inContext) + """
                  {
                    get {
                         let function = objectRef[dynamicMember: "\(name)"] as JSFunctionRef
                         return { (\(getterArguments)) in function.dynamicallyCall(withArguments: [\(getterArguments)]).fromJSValue() }
                     }
                     set {
                         objectRef[dynamicMember: "\(name)"] = JSFunctionRef.from({ arguments in
                             return newValue(\(setterArguments)).jsValue()
                         }).jsValue()
                     }
                 }
                 """
             ]

        case .protocolContext,
             .extensionContext,
             .structContext:
             return [
                 _swiftDeclarations(inContext: inContext) + """
                  {
                     get {
                         return objectRef.\(name).fromJSValue()
                     }
                     set {
                         objectRef.\(name) = newValue.jsValue()
                     }
                 }
                 """
             ]
        }
    }

    static func == (lhs: ReadWritePropertyNode, rhs: ReadWritePropertyNode) -> Bool {
        return lhs.name == rhs.name && lhs.dataType == rhs.dataType
    }
}
