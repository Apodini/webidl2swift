
import Foundation

class ReadWritePropertyNode: PropertyNode, Equatable {

    let name: String
    let dataType: NodePointer
    let isOverride: Bool
    let isStatic: Bool

    internal init(name: String, dataType: NodePointer, isOverride: Bool, isStatic: Bool) {
        self.name = name
        self.dataType = dataType
        self.isOverride = isOverride
        self.isStatic = isStatic
    }

    var isProperty: Bool {
        return true
    }

    func initializationStatement(forContext context: MemberNodeContext) -> String? {

        guard case .classContext = context, !dataType.node!.isProtocol, !isStatic else {
            return nil
        }

        let dataTypeNode = dataType.node!

        if dataTypeNode.isClosure && dataTypeNode.numberOfClosureArguments == 1 {
            return """
            _\(name) = \(dataTypeNode.isOptional ? "OptionalClosureHandler" : "ClosureHandler")(objectRef: objectRef, name: "\(name)")
            """
        } else if !isOverride {
            return """
            _\(name) = ReadWriteAttribute(objectRef: objectRef, name: "\(name)")
            """
        } else {
            return nil
        }
    }

    private func _swiftDeclarations(inContext: MemberNodeContext) -> String {

        let declaration: String

        let dataTypeNode = dataType.node!

        switch (inContext, isStatic) {
        case (.classContext, false) where dataTypeNode.isProtocol:
            return "public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"

        case (.classContext, true) where dataTypeNode.isProtocol:
        return "public static var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"

        case (.classContext, false) where dataTypeNode.isClosure && dataTypeNode.isOptional && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @OptionalClosureHandler
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, true) where dataTypeNode.isClosure && dataTypeNode.isOptional && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @OptionalClosureHandler(objectRef: Self.classRef, name: "\(name)")
            public static var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, false) where dataTypeNode.isClosure && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @ClosureHandler
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, true) where dataTypeNode.isClosure && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @ClosureHandler(objectRef: Self.classRef, name: "\(name)")
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, false) where isOverride:
            declaration = """
            public override var \(escapedName(name)): \(dataTypeNode.swiftTypeName) {
                get {
                    return objectRef[dynamicMember: "\(name)"]
                }
                set {
                    objectRef[dynamicMember: "\(name)"] = newValue
                }
            }
            """

        case (.classContext, true) where isOverride:
            declaration = """
            public static override var \(escapedName(name)): \(dataTypeNode.swiftTypeName) {
                get {
                    return objectRef[dynamicMember: "\(name)"]
                }
                set {
                    objectRef[dynamicMember: "\(name)"] = newValue
                }
            }
            """

        case (.classContext, false):
            declaration = """
            @ReadWriteAttribute
            public var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, true):
            declaration = """
            @ReadWriteAttribute(objectRef: Self.classRef, name: "\(name)")
            public static var \(escapedName(name)): \(dataTypeNode.swiftTypeName)
            """

        case (.protocolContext, _), (.extensionContext, _), (.structContext, _):
            declaration = "var \(escapedName(name)): \(dataTypeNode.swiftTypeName)"

        case (.namespaceContext, _):
            fatalError("Not supported by Web IDL standard!")
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
        case .namespaceContext:
            fatalError("Not supported by Web IDL standard!")
        }
    }

    static func == (lhs: ReadWritePropertyNode, rhs: ReadWritePropertyNode) -> Bool {
        return lhs.name == rhs.name && lhs.dataType == rhs.dataType
    }
}
