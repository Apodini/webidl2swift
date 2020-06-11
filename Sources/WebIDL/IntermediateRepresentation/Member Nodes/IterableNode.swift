//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

class ValueIterableNode: MemberNode, Equatable {

    let dataType: NodePointer

    internal init(dataType: NodePointer) {
        self.dataType = dataType
    }

    var isMethod: Bool { true }

    var adoptedProtocols: [String] {
        ["Sequence"]
    }
    var typealiases: [String] {
        ["public typealias Element = \(unwrapNode(dataType).swiftTypeName)"]
    }

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclarations(inContext: inContext, withImplementation: false)
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclarations(inContext: inContext, withImplementation: true)
    }

    private func _swiftDeclarations(inContext: MemberNodeContext, withImplementation: Bool) -> [String] {

        switch inContext {
        case .classContext(let name):
            var declaration = "public func makeIterator() -> ValueIterableIterator<\(name)>"
            if withImplementation {
                declaration += " { return ValueIterableIterator(sequence: self) }"
            }
            return [declaration]

        default:
            fatalError("Not supported by Web IDL standard!")
        }
    }

    static func == (lhs: ValueIterableNode, rhs: ValueIterableNode) -> Bool {
        lhs.dataType == rhs.dataType
    }
}

class PairIterableNode: MemberNode, Equatable {

    let dataType: NodePointer

    internal init(dataType: NodePointer) {
        self.dataType = dataType
    }

    var isMethod: Bool { true }

    var adoptedProtocols: [String] {
        ["KeyValueSequence"]
    }
    var typealiases: [String] {
        ["public typealias Value = \(unwrapNode(dataType).swiftTypeName)"]
    }

    func swiftDeclarations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclarations(inContext: inContext, withImplementation: false)
    }

    func swiftImplementations(inContext: MemberNodeContext) -> [String] {

        _swiftDeclarations(inContext: inContext, withImplementation: true)
    }

    private func _swiftDeclarations(inContext: MemberNodeContext, withImplementation: Bool) -> [String] {

        switch inContext {
        case .classContext(let name):
            var declaration = "public func makeIterator() -> PairIterableIterator<\(name)>"
            if withImplementation {
                declaration += " { return PairIterableIterator(sequence: self) }"
            }
            return [declaration]

        default:
            fatalError("Not supported by Web IDL standard!")
        }
    }

    static func == (lhs: PairIterableNode, rhs: PairIterableNode) -> Bool {
        lhs.dataType == rhs.dataType
    }
}
