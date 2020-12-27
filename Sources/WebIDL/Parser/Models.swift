//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

public enum ExtendedAttribute: Equatable {

    case single(String)
    case argumentList(String, [Argument])
    case namedArgumentList(String, String, [Argument])
    case identifier(String, String)
    case identifierList(String, [String])
}

///
public typealias ExtendedAttributeList = [ExtendedAttribute]

///
public protocol Definition {}

public struct Callback: Definition, Equatable {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let returnType: Type
    public let argumentList: [Argument]
}

public struct CallbackInterface: Definition, Equatable {
    public let identifer: String
    public let extendedAttributeList: ExtendedAttributeList
    public let callbackInterfaceMembers: [CallbackInterfaceMember]
}

public enum CallbackInterfaceMember: Equatable {

    case const(Const, ExtendedAttributeList)
    case regularOperation(RegularOperation, ExtendedAttributeList)
}

public struct Const: Equatable {
    public let identifier: String
    public let constType: ConstType
    public let constValue: ConstValue
}

public struct Interface: Definition, Equatable {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let inheritance: Inheritance?
    public let members: [InterfaceMember]
}

public struct Mixin: Definition, Equatable {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let members: [MixinMember]
}

public enum MixinMember: Equatable {

    case const(Const, ExtendedAttributeList)
    case regularOperation(RegularOperation, ExtendedAttributeList)
    case stringifier(Stringifier, ExtendedAttributeList)
    case readOnlyAttributeRest(Bool, AttributeRest, ExtendedAttributeList)
}

public struct Inheritance: Equatable {
    public let identifier: String
}

public enum InterfaceMember: Equatable {

    case constructor([Argument], ExtendedAttributeList)
    case const(Const, ExtendedAttributeList)
    case operation(Operation, ExtendedAttributeList)
    case stringifier(Stringifier, ExtendedAttributeList)
    case staticMember(StaticMember, ExtendedAttributeList)
    case iterable(Iterable, ExtendedAttributeList)
    case asyncIterable(AsyncIterable, ExtendedAttributeList)
    case readOnlyMember(ReadOnlyMember, ExtendedAttributeList)
    case readWriteAttribute(ReadWriteAttribute, ExtendedAttributeList)
    case readWriteMaplike(ReadWriteMaplike, ExtendedAttributeList)
    case readWriteSetlike(ReadWriteSetlike, ExtendedAttributeList)
}

public enum StaticMember: Equatable {
    case readOnlyAttributeRest(Bool, AttributeRest)
    case regularOperation(RegularOperation)
}

public struct ReadWriteMaplike: Equatable {
    public let maplike: MaplikeRest
}

public struct ReadWriteSetlike: Equatable {
    public let setlike: SetlikeRest
}

public struct Dictionary: Definition, Equatable {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let inheritance: Inheritance?
    public let members: [DictionaryMember]
}

public struct DictionaryMember: Equatable {

    public let identifier: String
    public let isRequired: Bool
    public let extendedAttributeList: ExtendedAttributeList

    public let type: Type
    public let extendedAttributesOfDataType: ExtendedAttributeList?
    public let defaultValue: DefaultValue?
}

public enum Partial: Definition, Equatable {

    case interface(Interface, ExtendedAttributeList)
    case mixin(Mixin, ExtendedAttributeList)
    case dictionary(Dictionary, ExtendedAttributeList)
    case namespace(Namespace, ExtendedAttributeList)
}

public struct Namespace: Definition, Equatable {
    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let namespaceMembers: [NamespaceMember]
}

public enum NamespaceMember: Equatable {

    case regularOperation(RegularOperation, ExtendedAttributeList)
    case readonlyAttribute(AttributeRest)
}

public struct Enum: Definition, Equatable {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let enumValues: [EnumValue]
}

public struct EnumValue: Equatable {

    public let string: String
}

public enum ReadOnlyMember: Equatable {
    case attribute(AttributeRest)
    case maplike(MaplikeRest)
    case setlike(SetlikeRest)
}

public enum Operation: Equatable {
    case regular(RegularOperation)
    case special(Special, RegularOperation)
}

public struct RegularOperation: Equatable {

    public let returnType: Type
    public let operationName: OperationName?
    public let argumentList: [Argument]
}

public enum OperationName: Equatable {
    case identifier(String)
    case includes
}

public struct OperationRest: Equatable {
    public let optioalOperationName: OperationName?
    public let argumentList: [Argument]
}

public enum Special: String, Equatable, Hashable {

    case getter
    case setter
    case deleter
}

public struct Argument: Equatable {

    public let rest: ArgumentRest
    public let extendedAttributeList: ExtendedAttributeList
}

public indirect enum ArgumentRest: Equatable {
    case optional(TypeWithExtendedAttributes, ArgumentName, DefaultValue?)
    case nonOptional(Type, _ ellipsis: Bool, ArgumentName)
}

public enum ArgumentName: Equatable {
    case identifier(String)
    case argumentNameKeyword(ArgumentNameKeyword)
}

public struct AttributeRest: Equatable {

    public let typeWithExtendedAttributes: TypeWithExtendedAttributes
    public let attributeName: AttributeName
}

public enum AttributeName: Equatable {
    case attributeNameKeyword(AttributeNameKeyword)
    case identifier(String)
}

public enum AttributeNameKeyword: String, Equatable {
    case async
    case required
}

public struct MaplikeRest: Equatable {

    public let keyType: TypeWithExtendedAttributes
    public let valueType: TypeWithExtendedAttributes
}

public struct SetlikeRest: Equatable {
    public let elementType: TypeWithExtendedAttributes
}

public enum DefaultValue: Equatable {
    case constValue(ConstValue)
    case string(String)
    case emptyList
    case emptyDictionary
    case null
}

public enum ConstType: Equatable {

    case identifier(String)
    case primitiveType(PrimitiveType)
}

public enum ConstValue: Equatable {
    case booleanLiteral(Bool)
    case floatLiteral(FloatLiteral)
    case integer(Int)
}

public enum FloatLiteral: Equatable {

    case decimal(Double)
    case negativeInfinity
    case infinity
    case notANumber
}

public struct IncludesStatement: Definition, Equatable {

    public let child: String
    public let parent: String
    public let extendedAttributeList: ExtendedAttributeList
}

public struct Typedef: Definition, Equatable {

    public let identifier: String
    public let type: Type
    public let extendedAttributeList: ExtendedAttributeList
}

public struct TypeWithExtendedAttributes: Equatable {

    public let type: Type
    public let extendedAttributeList: ExtendedAttributeList
}

public indirect enum Type: Equatable {
    case single(SingleType)
    case union([UnionMemberType], Bool)
}

public indirect enum SingleType: Equatable {

    case distinguishableType(DistinguishableType)
    case any
    case promiseType(Promise)
}

public enum UnionMemberType: Equatable {

    case distinguishableType(ExtendedAttributeList, DistinguishableType)
    case nullableUnionType([UnionMemberType], Bool)
}

@frozen
public enum DistinguishableType: Equatable {

    case primitive(PrimitiveType, Bool)
    case string(StringType, Bool)
    case identifier(String, Bool)
    case sequence(TypeWithExtendedAttributes, Bool)
    case object(Bool)
    case symbol(Bool)
    case bufferRelated(BufferRelatedType, Bool)
    case frozenArray(TypeWithExtendedAttributes, Bool)
    case record(RecordType, Bool)
}


public struct Iterable: Equatable {

    public let typeWithExtendedAttributes0: TypeWithExtendedAttributes
    public let typeWithExtendedAttributes1: TypeWithExtendedAttributes?
}

public struct AsyncIterable: Equatable {

    public let typeWithExtendedAttributes0: TypeWithExtendedAttributes
    public let typeWithExtendedAttributes1: TypeWithExtendedAttributes?
    public let argumentList: [Argument]?
}

public enum ReadWriteAttribute: Equatable {
    case inherit(AttributeRest)
    case notInherit(AttributeRest)
}

public struct Promise: Equatable {

    public let returnType: Type
}

// swiftlint:disable identifier_name
public enum BufferRelatedType: String, Equatable, Hashable {
    case ArrayBuffer
    case DataView
    case Int8Array
    case Int16Array
    case Int32Array
    case Uint8Array
    case Uint16Array
    case Uint32Array
    case Uint8ClampedArray
    case Float32Array
    case Float64Array
}

public enum StringType: String, Equatable, Hashable {

    case ByteString
    case DOMString
    case USVString
}

public enum PrimitiveType: Equatable {
    case UnsignedIntegerType(UnsignedIntegerType)
    case UnrestrictedFloatType(UnrestrictedFloatType)
    case undefined
    case boolean
    case byte
    case octet
}
// swiftlint:enable identifier_name

public struct RecordType: Equatable {

    public let stringType: StringType
    public let typeWithExtendedAttributes: TypeWithExtendedAttributes
}


public enum UnrestrictedFloatType: Equatable {
    case unrestricted(FloatType)
    case restricted(FloatType)
}

public enum FloatType: String, Equatable, Hashable {
    case float
    case double
}

public enum UnsignedIntegerType: Equatable {
    case unsigned(IntegerType)
    case signed(IntegerType)
}

public enum IntegerType: String, Equatable, Hashable {
    case short
    case long
    case longLong
}

public enum ArgumentNameKeyword: String, Equatable, Hashable {
    case async
    case attribute
    case callback
    case const
    case constructor
    case deleter
    case dictionary
    case `enum`
    case getter
    case includes
    case inherit
    case interface
    case iterable
    case maplike
    case mixin
    case namespace
    case partial
    case readonly
    case required
    case setlike
    case setter
    case `static`
    case stringifier
    case typedef
    case unrestricted
}

public enum Stringifier: Equatable {
    case readOnlyAttributeRest(Bool, TypeWithExtendedAttributes, AttributeName)
    case regular(RegularOperation)
    case empty
}
