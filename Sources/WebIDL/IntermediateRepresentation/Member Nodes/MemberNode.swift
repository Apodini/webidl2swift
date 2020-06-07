
import Foundation

protocol MemberNode: class {

    var isConstructor: Bool { get }
    var isMethod: Bool { get }
    var isSubscript: Bool { get }
    var isProperty: Bool { get }
    var needsInitialization: Bool { get }
    var isStatic: Bool { get }

    var adoptedProtocols: [String] { get }
    var typealiases: [String] { get }

    func swiftDeclarations(inContext: MemberNodeContext) -> [String]
    func swiftImplementations(inContext: MemberNodeContext) -> [String]
}

protocol PropertyNode: MemberNode  {

    func initializationStatement(forContext: MemberNodeContext) -> String?
}

extension PropertyNode {

    var isProperty: Bool { true }
}

enum MemberNodeContext {

    case classContext(String)
    case protocolContext(String)
    case extensionContext(String)
    case structContext(String)
    case namespaceContext(String)
}

extension MemberNode {

    var isConstructor: Bool { false }
    var isMethod: Bool { false }
    var isSubscript: Bool { false }
    var isProperty: Bool { false }
    var needsInitialization: Bool { false }
    var isStatic: Bool { false }
    var adoptedProtocols: [String] { [] }
    var typealiases: [String] { [] }
}
