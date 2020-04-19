//
//  Created by Manuel Burghard on 19.04.20.
//

import Foundation

protocol MemberNode: class {

    var isConstructor: Bool { get }
    var isMethod: Bool { get }
    var isSubscript: Bool { get }
    var isProperty: Bool { get }
    var needsInitialization: Bool { get }

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

    case classContext
    case protocolContext
    case extensionContext
    case structContext
}

extension MemberNode {

    var isConstructor: Bool { false }
    var isMethod: Bool { false }
    var isSubscript: Bool { false }
    var isProperty: Bool { false }
    var needsInitialization: Bool { false }
}
