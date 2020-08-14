//
//  Created by Manuel Burghard. Licensed unter MIT.
//

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
        true
    }

    func initializationStatement(forContext context: MemberNodeContext) -> String? {

        guard case .classContext = context, !unwrapNode(dataType).isProtocol, !isStatic else {
            return nil
        }

        let dataTypeNode = unwrapNode(dataType)

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

    // swiftlint:disable function_body_length cyclomatic_complexity
    private func _swiftDeclarations(inContext: MemberNodeContext) -> String {

        let declaration: String

        let dataTypeNode = unwrapNode(dataType)
        let escaped = escapedName(name)

        switch (inContext, isStatic) {
        case (.classContext, false) where dataTypeNode.isProtocol:
            return "public var \(escaped): \(dataTypeNode.swiftTypeName)"

        case (.classContext, true) where dataTypeNode.isProtocol:
        return "public static var \(escaped): \(dataTypeNode.swiftTypeName)"

        case (.classContext, false) where dataTypeNode.isClosure && dataTypeNode.isOptional && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @OptionalClosureHandler
            public var \(escaped): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, true) where dataTypeNode.isClosure && dataTypeNode.isOptional && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @OptionalClosureHandler(objectRef: Self.classRef, name: "\(name)")
            public static var \(escaped): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, false) where dataTypeNode.isClosure && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @ClosureHandler
            public var \(escaped): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, true) where dataTypeNode.isClosure && dataTypeNode.numberOfClosureArguments == 1:
            declaration = """
            @ClosureHandler(objectRef: Self.classRef, name: "\(name)")
            public var \(escaped): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, false) where isOverride:
            declaration = """
            public override var \(escaped): \(dataTypeNode.swiftTypeName) {
                get {
                    return objectRef.\(escaped)
                }
                set {
                    objectRef.\(escaped) = newValue
                }
            }
            """

        case (.classContext, true) where isOverride:
            declaration = """
            public static override var \(escaped): \(dataTypeNode.swiftTypeName) {
                get {
                    return objectRef.\(escaped)
                }
                set {
                    objectRef\(escaped) = newValue
                }
            }
            """

        case (.classContext, false):
            declaration = """
            @ReadWriteAttribute
            public var \(escaped): \(dataTypeNode.swiftTypeName)
            """

        case (.classContext, true):
            declaration = """
            @ReadWriteAttribute(objectRef: Self.classRef, name: "\(name)")
            public static var \(escaped): \(dataTypeNode.swiftTypeName)
            """

        case (.protocolContext, _), (.extensionContext, _), (.structContext, _):
            declaration = "var \(escaped): \(dataTypeNode.swiftTypeName)"

        case (.namespaceContext, _):
            fatalError("Not supported by Web IDL standard!")
        }

        return declaration
    }
    // swiftlint:enable function_body_length cyclomatic_complexity

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        [_swiftDeclarations(inContext: inContext)]
    }

    // swiftlint:disable function_body_length
    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        let dataTypeNode = unwrapNode(dataType)
        let escaped = escapedName(name)
        switch inContext {
        case .classContext where dataTypeNode.isProtocol,
             .protocolContext where dataTypeNode.isProtocol,
             .extensionContext where dataTypeNode.isProtocol,
             .structContext where dataTypeNode.isProtocol:
            return [
                _swiftDeclarations(inContext: inContext) + """
                {
                    get {
                        return objectRef.\(escaped).fromJSValue()! as \(dataTypeNode.typeErasedSwiftType)
                    }
                    set {
                        objectRef.\(escaped) = newValue.jsValue()!
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
            let setterArguments = (0 ..< dataTypeNode.numberOfClosureArguments).map({ "arguments[\($0)].fromJSValue()!" }).joined(separator: ", ")
            return [
                _swiftDeclarations(inContext: inContext) + """
                 {
                    get {
                        guard let function = objectRef.\(escaped).function else {
                            return nil
                        }
                        return { (\(getterArguments)) in function(\(getterArguments)).fromJSValue()! }
                    }
                    set {
                        if let newValue = newValue {
                            objectRef.\(escaped) = JSClosure { arguments in
                                return newValue(\(setterArguments)).jsValue()
                            }.jsValue()
                        } else {
                            objectRef.\(escaped) = .null
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
            let setterArguments = (0 ..< dataTypeNode.numberOfClosureArguments).map({ "arguments[\($0)].fromJSValue()!" }).joined(separator: ", ")
            return [
                _swiftDeclarations(inContext: inContext) + """
                {
                    get {
                        let function = objectRef.\(escaped).function!
                        return { (\(getterArguments)) in function(\(getterArguments)).fromJSValue()! }
                    }
                    set {
                        objectRef.\(escaped) = JSClosure { arguments in
                            return newValue(\(setterArguments)).jsValue()
                        }.jsValue()
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
                         return objectRef.\(escaped).fromJSValue()!
                     }
                     set {
                         objectRef.\(escaped) = newValue.jsValue()
                     }
                 }
                 """
             ]
        case .namespaceContext:
            fatalError("Not supported by Web IDL standard!")
        }
    }
    // swiftlint:enable function_body_length

    static func == (lhs: ReadWritePropertyNode, rhs: ReadWritePropertyNode) -> Bool {
        lhs.name == rhs.name && lhs.dataType == rhs.dataType
    }
}
