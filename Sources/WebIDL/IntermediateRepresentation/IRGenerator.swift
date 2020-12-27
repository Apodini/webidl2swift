//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

// swiftlint:disable type_body_length file_length
/// `IRGenerator` creates an `IntermediateRepresentation` for a list of Web IDL definitions.
public class IRGenerator {

    // swiftlint:disable:next identifier_name
    var ir = IntermediateRepresentation()
    var useSimpleTypes: Bool = false

    /// Public initalizer
    public init() {}

    // swiftlint:disable cyclomatic_complexity

    /// Create an `IntermediateRepresentation` from a list of definitions
    /// - Parameter definitions: A list of parsed Web IDL definitons.
    /// - Returns: An `IntermediateRepresentation` instance containing all types generated for `definitions`.
    public func generateIR(for definitions: [Definition]) -> IntermediateRepresentation {

        // https://streams.spec.whatwg.org/#rs-class
        ir.registerBasicType(withTypeName: "ReadableStream")
        ir.registerBasicArrayType(withTypeName: "Float64Array", scalarType: "Double")
        ir.registerBasicArrayType(withTypeName: "Float32Array", scalarType: "Float")
        ir.registerBasicArrayType(withTypeName: "Uint32Array", scalarType: "UInt32")
        ir.registerBasicArrayType(withTypeName: "Uint16Array", scalarType: "UInt16")
        ir.registerBasicArrayType(withTypeName: "Uint8Array", scalarType: "UInt8")
        ir.registerBasicArrayType(withTypeName: "Uint8ClampedArray", scalarType: "UInt8")
        ir.registerBasicArrayType(withTypeName: "Int32Array", scalarType: "Int32")
        ir.registerBasicArrayType(withTypeName: "Int16Array", scalarType: "Int16")
        ir.registerBasicArrayType(withTypeName: "Int8Array", scalarType: "Int8")
        ir.registerBasicType(withTypeName: "ArrayBuffer")
        ir.registerBasicType(withTypeName: "DataView")

        for definition in definitions {
            if let interface = definition as? Interface {
                handleInterface(interface)
            } else if let typedef = definition as? Typedef {
                handleTypedef(typedef)
            } else if let dictionary = definition as? Dictionary {
                handleDictionary(dictionary)
            } else if let callbackInterface = definition as? CallbackInterface {
                handleCallbackInterface(callbackInterface)
            } else if let callback = definition as? Callback {
                handleCallback(callback)
            } else if let enumeration = definition as? Enum {
                handleEnum(enumeration)
            } else if let mixin = definition as? Mixin {
                handleMixin(mixin)
            } else if let partial = definition as? Partial {
                handlePartial(partial)
            } else if let includeStatement = definition as? IncludesStatement {
                handleIncludesStatement(includeStatement)
            } else if let namespace = definition as? Namespace {
                handleNamespace(namespace)
            }
        }

        // swiftlint:disable:next identifier_name
        let ir = self.ir
        self.ir = IntermediateRepresentation()
        return ir
    }
    // swiftlint:enable cyclomatic_complexity

    func handleNamespace(_ namespace: Namespace) {

        let members = namespace.namespaceMembers.map { member -> MemberNode in

            switch member {
            case .regularOperation(let regularOperation, _):
                return handleRegularOperation(regularOperation)
            case .readonlyAttribute(let attributeRest):
                let dataType = handleType(attributeRest.typeWithExtendedAttributes.type)
                let name = handleAttributeName(attributeRest.attributeName)
                return ReadonlyPropertyNode(name: name, dataType: dataType, isStatic: false)
            }
        }

        ir.registerNamespace(withTypeName: namespace.identifier, members: members)
    }

    func handlePartial(_ partial: Partial) {

        switch partial {
        case .interface(let interface, _):
            handleInterface(interface)
        case .mixin(let mixin, _):
            handleMixin(mixin)
        case .dictionary(let dictionary, _):
            handleDictionary(dictionary)
        case .namespace(let namespace, _):
            handleNamespace(namespace)
        }
    }

    func handleDictionary(_ dictionary: Dictionary) {

        let inheritsFrom = dictionary.inheritance.map { ir.registerIdentifier(withTypeName: $0.identifier) }

        let memberIdentifiers = dictionary.members.map { $0.identifier }
        _ = ir.registerDictionaryNode(withTypeName: dictionary.identifier, inheritsFrom: inheritsFrom, members: memberIdentifiers)
    }

    func handleIncludesStatement(_ includeStatment: IncludesStatement) {

        let mixinNodePointer = ir.registerIdentifier(withTypeName: includeStatment.parent)
        ir.registerClass(withTypeName: includeStatment.child, inheritsFrom: [mixinNodePointer], members: [])
    }

    func handleMixin(_ mixin: Mixin) {

        let members: [MemberNode] = mixin.members.compactMap { member in

            switch member {
            case .const(let const, _):
                return handleConst(const)

            case .regularOperation(let regularOperation, _):
                return handleRegularOperation(regularOperation)
            case .stringifier:
                return nil

            case .readOnlyAttributeRest(false, let attributeRest, _):
                let type = handleType(attributeRest.typeWithExtendedAttributes.type)
                let name = handleAttributeName(attributeRest.attributeName)
                return ReadWritePropertyNode(name: name, dataType: type, isOverride: false, isStatic: false)

            case .readOnlyAttributeRest(true, let attributeRest, _):
                let type = handleType(attributeRest.typeWithExtendedAttributes.type)
                let name = handleAttributeName(attributeRest.attributeName)
                return ReadonlyPropertyNode(name: name, dataType: type, isStatic: false)
            }
        }

        ir.registerProtocol(withTypeName: mixin.identifier, inheritsFrom: [], requiredMembers: [], defaultImplementations: members, kind: .mixin)
    }

    func handleEnum(_ enumeration: Enum) {

        ir.registerEnumeration(withTypeName: enumeration.identifier, cases: enumeration.enumValues.map { $0.string })
    }

    func handleCallback(_ callback: Callback) {

        let returnType = handleType(callback.returnType)

        let arguments: [NodePointer] = callback.argumentList.map {
            switch $0.rest {
            case .optional(let typeWithExtendedAttributes, _, _):
                return handleType(typeWithExtendedAttributes.type)
            case .nonOptional(let dataType, _, _):
                return handleType(dataType)
            }
        }

        let closureNode = ClosureNode(arguments: arguments, returnType: returnType)
        _ = ir.registerAliasNode(withTypeName: callback.identifier, aliasing: closureNode)
    }

    func handleInterface(_ interface: Interface) {

        let members: [MemberNode] = interface.members.compactMap { member in

            switch member {
            case .constructor(let arguments, _):
                return ConstructorNode(className: interface.identifier, parameters: handleArgumentList(arguments))

            case .const(let const, _):
                return handleConst(const)

            case .operation(let operation, _):
                return handleOperation(operation)

            case .readWriteAttribute(let readWriteAttribute, _):
                return handleReadWriteAttribute(readWriteAttribute)

            case .readOnlyMember(let readOnlyMember, _):
                return handleReadOnlyMember(readOnlyMember)

            case .stringifier:
                // Not required: JSBridgedClass conforms to CustomStringConvertible
                return nil

            case .staticMember(let staticMember, _):
                return handleStaticMember(staticMember)

            case .iterable(let iterable, _):
                return handleIterable(iterable)

            case .asyncIterable,
                 .readWriteMaplike,
                 .readWriteSetlike:
                fatalError("Member type \(member) not yet implemented")
            }
        }

        let inheritsFrom: Set<NodePointer> = interface.inheritance.map { Set([ir.registerIdentifier(withTypeName: $0.identifier)]) } ?? []

        ir.registerClass(withTypeName: interface.identifier, inheritsFrom: inheritsFrom, members: members)
    }

    func handleCallbackInterface(_ callbackInterface: CallbackInterface) {

        var requiredMembers = [MemberNode]()
        var defaultImplementations = [MemberNode]()

        for member in callbackInterface.callbackInterfaceMembers {
            switch member {

            case .const(let const, _):
                let type = handleConstType(const.constType)
                defaultImplementations.append(ConstantPropertyNode(name: const.identifier, dataType: type, value: handleConstValue(const.constValue)))

            case .regularOperation(let regularOperation, _):
                requiredMembers.append(handleRegularOperation(regularOperation))
            }
        }

        ir.registerProtocol(withTypeName: callbackInterface.identifer, inheritsFrom: [], requiredMembers: requiredMembers, defaultImplementations: defaultImplementations, kind: .callback)
    }

    func handleTypedef(_ typedef: Typedef) {

        let dataType = handleType(typedef.type)
        _ = ir.registerAliasNode(withTypeName: typedef.identifier, aliasing: unwrapNode(dataType))
    }

    func handleUnionMemberTypes(_ members: [UnionMemberType]) -> NodePointer {

        var visitedTypes = [NodePointer]()
        let typeName: String = members
            .map {
                let type: NodePointer
                switch $0 {
                case .distinguishableType(_, let distinguishableType):
                    type = handleDistinguishableType(distinguishableType)

                case .nullableUnionType(let members, true):
                    type = insertOptional(for: handleUnionMemberTypes(members))

                case .nullableUnionType(let members, false):
                    type = handleUnionMemberTypes(members)
                }
                visitedTypes.append(type)
                return type.identifier
            }
            .joined(separator: "Or")

        let nodePointer = ir.registerEnumerationWithAssociatedValues(withTypeName: typeName, cases: visitedTypes)
        
        return nodePointer
    }

    func handleStringType(_ stringType: StringType) -> NodePointer {

        ir.registerBasicType(withTypeName: "String")
    }

    func handleType(_ type: Type) -> NodePointer {

        switch type {
        case .single(let singleType):
            return handleSingleType(singleType)

        case .union(let members, let isNullable):
            let nodePointer = handleUnionMemberTypes(members)
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer
        }
    }

    func handleSingleType(_ singleType: SingleType) -> NodePointer {

        switch singleType {
        case .distinguishableType(let  distinguishableType):
            return handleDistinguishableType(distinguishableType)

        case .any:
            return ir.registerBasicType(withTypeName: "JSValue")

        case .promiseType(let promise):
            let returnType = handleType(promise.returnType)
            return ir.registerBasicType(withTypeName: "Promise<\(returnType.identifier)>")
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func handleDistinguishableType(_ distinguishableType: DistinguishableType) -> NodePointer {

        func handleBufferRelated(_ name: String, _ isNullable: Bool) -> NodePointer {

            let basicNodePointer = ir.registerBasicType(withTypeName: name)
            if isNullable {
                return insertOptional(for: basicNodePointer)
            }
            return basicNodePointer
        }

        func handleBufferRelatedWithScalarType(_ name: String, _ scalarType: String, _ isNullable: Bool) -> NodePointer {

            let basicNodePointer = ir.registerBasicArrayType(withTypeName: name, scalarType: scalarType)
            if isNullable {
                return insertOptional(for: basicNodePointer)
            }
            return basicNodePointer
        }

        switch distinguishableType {
        case .primitive(let primitive, let isNullable):
            let nodePointer = handlePrimitiveType(primitive)
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .string(let stringType, let isNullable):
            let nodePointer = handleStringType(stringType)
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .identifier(let identifier, let isNullable):
            let nodePointer = handleIdentifier(identifier)
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .sequence(let typeWithExtendedAttributes, let isNullable):
            let type = handleType(typeWithExtendedAttributes.type)
            let arrayNode = ir.registerArrayNode(withTypeName: "\(type.identifier)Sequence", element: type)

            if isNullable {
                return insertOptional(for: arrayNode)
            }
            return arrayNode

        case .object(let isNullable):
            let nodePointer = ir.registerBasicType(withTypeName: "JSValue")
            if isNullable {
                return insertOptional(for: nodePointer)
            }
            return nodePointer

        case .symbol:
            fatalError("Unsupported symbole type")

        case .bufferRelated(.DataView, let isNullable):
            return handleBufferRelated("DataView", isNullable)

        case .bufferRelated(.ArrayBuffer, let isNullable):
            return handleBufferRelated("ArrayBuffer", isNullable)

        case .bufferRelated(.Int8Array, let isNullable):
            return handleBufferRelatedWithScalarType("Int8Array", "Int8", isNullable)
        case .bufferRelated(.Int16Array, let isNullable):
            return handleBufferRelatedWithScalarType("Int16Array", "Int16", isNullable)
        case .bufferRelated(.Int32Array, let isNullable):
            return handleBufferRelatedWithScalarType("Int32Array", "Int32", isNullable)
        case .bufferRelated(.Uint8Array, let isNullable):
            return handleBufferRelatedWithScalarType("Uint8Array", "UInt8", isNullable)
        case .bufferRelated(.Uint16Array, let isNullable):
            return handleBufferRelatedWithScalarType("Uint16Array", "UInt16", isNullable)
        case .bufferRelated(.Uint32Array, let isNullable):
            return handleBufferRelatedWithScalarType("Uint32Array", "UInt32", isNullable)
        case .bufferRelated(.Uint8ClampedArray, let isNullable):
            return handleBufferRelatedWithScalarType("Uint8ClampedArray", "UInt8", isNullable)
        case .bufferRelated(.Float32Array, let isNullable):
            return handleBufferRelatedWithScalarType("Float32Array", "Float", isNullable)
        case .bufferRelated(.Float64Array, let isNullable):
            return handleBufferRelatedWithScalarType("Float64Array", "Double", isNullable)
        case .frozenArray(let typeWithExtendedAttributes, let isNullable):
            let type = handleType(typeWithExtendedAttributes.type)
            let name = "\(type.identifier)Array"
            let arrayNode = ArrayNode(element: type)
            let aliasPointer = ir.registerAliasNode(withTypeName: name, aliasing: arrayNode)
            if isNullable {
                return insertOptional(for: aliasPointer)
            }
            return aliasPointer

        case .record(let record, _):
            return handleRecordType(record)
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    func handleRecordType(_ recordType: RecordType) -> NodePointer {

        let valueType = handleType(recordType.typeWithExtendedAttributes.type)
        let name = "\(valueType.identifier)Record"
        let recordNode = RecordNode(value: valueType)
        let aliasPointer = ir.registerAliasNode(withTypeName: name, aliasing: recordNode)
        return aliasPointer
    }

    func handlePrimitiveType(_ primitive: PrimitiveType) -> NodePointer {

        switch primitive {
        case .UnsignedIntegerType(let integerType):
            return handleUnsignedIntegerType(integerType)
        case .UnrestrictedFloatType(let floatType):
            return handleUnrestrictedFloatType(floatType)
        case .boolean:
            return ir.registerBasicType(withTypeName: "Bool")
        case .byte:
            return ir.registerBasicType(withTypeName: "Int8")
        case .octet:
            return ir.registerBasicType(withTypeName: "UInt8")
        case .undefined:
            return ir.registerBasicType(withTypeName: "Void")
        }
    }

    func handleIdentifier(_ identifier: String) -> NodePointer {

        ir.registerIdentifier(withTypeName: identifier)
    }

    func handleReadOnlyMember(_ readOnlyMember: ReadOnlyMember) -> ReadonlyPropertyNode {

        switch readOnlyMember {
        case .attribute(let attribute):
            let name = handleAttributeName(attribute.attributeName)
            let type = handleType(attribute.typeWithExtendedAttributes.type)

            return ReadonlyPropertyNode(name: name, dataType: type, isStatic: false)

        case .maplike:
            fatalError("Not implemented yet.")
        case .setlike:
            fatalError("Not implemented yet.")
        }
    }

    func handleConst(_ const: Const) -> ConstantPropertyNode {

        ConstantPropertyNode(name: const.identifier, dataType: handleConstType(const.constType), value: handleConstValue(const.constValue))
    }

    func handleConstType(_ constType: ConstType) -> NodePointer {

        switch constType {
        case .identifier(let identifier):
            return handleIdentifier(identifier)
        case .primitiveType(let primitiveType):
            return handlePrimitiveType(primitiveType)
        }
    }

    func handleConstValue(_ constValue: ConstValue) -> String {

        switch constValue {
        case .booleanLiteral(true):
            return "true"
        case .booleanLiteral(false):
            return "false"
        case .floatLiteral(.decimal(let value)):
            return String(value)
        case .floatLiteral(.infinity):
            return "Double.infinity"
        case .floatLiteral(.negativeInfinity):
            return "-Double.infinity"
        case .floatLiteral(.notANumber):
            return "Double.nan"
        case .integer(let value):
            return String(value)
        }
    }

    func handleDefaultValue(_ defaultValue: DefaultValue) -> String {

        switch defaultValue {
        case .constValue(let constValue):
            return handleConstValue(constValue)
        case .string(let string):
            return "\"\(string)\""
        case .emptyList:
            return "[]"
        case .emptyDictionary:
            return "[:]"
        case .null:
            return "nil"
        }
    }

    func handleOperation(_ operation: Operation) -> MemberNode {

        switch operation {
        case .regular(let regularOperation):
            return handleRegularOperation(regularOperation)
        case .special(let special, let regularOperation):

            let returnType = handleType(regularOperation.returnType)
            let parameters = handleArgumentList(regularOperation.argumentList)
            switch special {
            case .getter:
                return SubscriptNode(returnType: returnType, kind: .getter, nameParameter: parameters[0], valueParameter: nil)

            case .setter:
                return SubscriptNode(returnType: returnType, kind: .setter, nameParameter: parameters[0], valueParameter: parameters[1])

            case .deleter:
                return SubscriptNode(returnType: returnType, kind: .deleter, nameParameter: parameters[0], valueParameter: nil)
            }
        }
    }

    func handleArgumentList(_ argumentList: [Argument]) -> [ParameterNode] {

        argumentList.map { argument -> ParameterNode in

            switch argument.rest {
            case .optional(let typeWithExtendedAttributes, let label, .some(let defaultValue)):
                let dataType = handleType(typeWithExtendedAttributes.type)
                return ParameterNode(label: handleArgumentName(label),
                                     dataType: dataType,
                                     isVariadic: false,
                                     isOmittable: true,
                                     defaultValue: DefaultValueNode(dataType: dataType, value: handleDefaultValue(defaultValue)))

            case .optional(let typeWithExtendedAttributes, let label, .none):
                return ParameterNode(label: handleArgumentName(label),
                                     dataType: handleType(typeWithExtendedAttributes.type),
                                     isVariadic: false,
                                     isOmittable: true,
                                     defaultValue: nil)

            case .nonOptional(let dataType, let ellipsis, let label):
                return ParameterNode(label: handleArgumentName(label),
                                     dataType: handleType(dataType),
                                     isVariadic: ellipsis,
                                     isOmittable: ellipsis,
                                     defaultValue: nil)
            }
        }
    }

    func handleRegularOperation(_ regularOperation: RegularOperation) -> MemberNode {

        if let operationName = regularOperation.operationName {
            let name = handleOperationName(operationName)
            let returnType = handleType(regularOperation.returnType)

            return MethodNode(name: name, returnType: returnType, parameters: handleArgumentList(regularOperation.argumentList))
        } else {
            fatalError("Regular Operations without name are not supported.")
        }
    }

    func handleOperationName(_ operationName: OperationName) -> String {

        switch operationName {
        case .identifier(let identifier):
            return identifier

        case .includes:
            fatalError("includes OperationName not supported.")
        }
    }

    func handleUnsignedIntegerType(_ integerType: UnsignedIntegerType) -> NodePointer {

        guard !useSimpleTypes else {
            return ir.registerBasicType(withTypeName: "Int32")
        }

        switch integerType {
        case .unsigned(.short):
            return ir.registerBasicType(withTypeName: "UInt16")

        case .unsigned(.long):
            return ir.registerBasicType(withTypeName: "UInt32")

        case .unsigned(.longLong):
            return ir.registerBasicType(withTypeName: "UInt64")

        case .signed(.short):
            return ir.registerBasicType(withTypeName: "Int16")

        case .signed(.long):
            return ir.registerBasicType(withTypeName: "Int32")

        case .signed(.longLong):
            return ir.registerBasicType(withTypeName: "Int64")
        }
    }

    func handleUnrestrictedFloatType(_ unrestrictedFloatType: UnrestrictedFloatType) -> NodePointer {

        // No unrestricted handling
        switch unrestrictedFloatType {
        case .unrestricted(let floatType), .restricted(let floatType):
            return handleFloatType(floatType)
        }
    }

    func handleFloatType(_ floatType: FloatType) -> NodePointer {

        guard !useSimpleTypes else {
            return ir.registerBasicType(withTypeName: "Double")
        }

        switch floatType {
        case .double:
            return ir.registerBasicType(withTypeName: "Double")

        case .float:
            return ir.registerBasicType(withTypeName: "Float")
        }
    }

    func handleReadWriteAttribute(_ readWriteAttribute: ReadWriteAttribute) -> ReadWritePropertyNode {

        switch readWriteAttribute {
        case .inherit(let attributeRest):
            let type = handleType(attributeRest.typeWithExtendedAttributes.type)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadWritePropertyNode(name: name, dataType: type, isOverride: true, isStatic: false)

        case .notInherit(let attributeRest):
            let type = handleType(attributeRest.typeWithExtendedAttributes.type)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadWritePropertyNode(name: name, dataType: type, isOverride: false, isStatic: false)
        }
    }

    func handleAttributeName(_ attributeName: AttributeName) -> String {

        switch attributeName {
        case .attributeNameKeyword(let keyword):
            return keyword.rawValue
        case .identifier(let identifier):
            return identifier
        }
    }

    func insertOptional(for nodePointer: NodePointer) -> NodePointer {

        let aliasPointer = ir.registerOptional(for: nodePointer)
        return aliasPointer
    }

    func handleIterable(_ iterable: Iterable) -> MemberNode {

        switch (iterable.typeWithExtendedAttributes0.type, iterable.typeWithExtendedAttributes1?.type) {
        case (_, let second?):
            return PairIterableNode(dataType: handleType(second))

        case (let first, nil):
            return ValueIterableNode(dataType: handleType(first))
        }
    }

    func handleStaticMember(_ staticMember: StaticMember) -> MemberNode? {

        switch staticMember {
        case .readOnlyAttributeRest(false, let attributeRest):
            let type = handleType(attributeRest.typeWithExtendedAttributes.type)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadWritePropertyNode(name: name, dataType: type, isOverride: false, isStatic: true)

        case .readOnlyAttributeRest(true, let attributeRest):
            let type = handleType(attributeRest.typeWithExtendedAttributes.type)
            let name = handleAttributeName(attributeRest.attributeName)

            return ReadonlyPropertyNode(name: name, dataType: type, isStatic: true)
            
        case .regularOperation:
            // Not supported. Cannot be looked up
            return nil
        }
    }

    func handleArgumentName(_ argumentName: ArgumentName) -> String {

        switch argumentName {
        case .identifier(let identifier):
            return swiftKeyWords[identifier] ?? identifier
        case .argumentNameKeyword(let keyword):
            return keyword.rawValue
        }
    }
}
// swiftlint:enable type_body_length file_length
