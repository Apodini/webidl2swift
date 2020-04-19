
import Foundation

public enum ExtendedAttribute {

    case single(String)
    case argumentList(String, [Argument])
    case namedArgumentList(String, String, [Argument])
    case identifier(String, String)
    case identifierList(String, [String])
}

public typealias ExtendedAttributeList = [ExtendedAttribute]

public protocol Definition {}

public struct Callback: Definition {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let returnType: ReturnType
    public let argumentList: [Argument]
}

public struct CallbackInterface: Definition {
    public let identifer: String
    public let extendedAttributeList: ExtendedAttributeList
    public let callbackInterfaceMembers: [CallbackInterfaceMember]
}

public enum CallbackInterfaceMember {

    case const(Const, ExtendedAttributeList)
    case regularOperation(RegularOperation, ExtendedAttributeList)
}

public struct Const {
    public let identifier: String
    public let constType: ConstType
    public let constValue: ConstValue
}

public struct Interface: Definition {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let inheritance: Inheritance?
    public let members: [InterfaceMember]
}

public struct Mixin: Definition {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let members: [MixinMember]
}

public enum MixinMember {

    case const(Const, ExtendedAttributeList)
    case regularOperation(RegularOperation, ExtendedAttributeList)
    case stringifier(Stringifier, ExtendedAttributeList)
    case readOnlyAttributeRest(Bool, AttributeRest, ExtendedAttributeList)
}

public struct Inheritance {
    public let identifier: String
}

public enum InterfaceMember {

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

public enum StaticMember {
    case readOnlyAttributeRest(Bool, AttributeRest)
    case regularOperation(RegularOperation)
}

public struct ReadWriteMaplike {
    public let maplike: MaplikeRest
}

public struct ReadWriteSetlike {
    public let setlike: SetlikeRest
}

public struct Dictionary: Definition {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let inheritance: Inheritance?
    public let members: [DictionaryMember]
}

public struct DictionaryMember {

    public let identifier: String
    public let isRequired: Bool
    public let extendedAttributeList: ExtendedAttributeList

    public let dataType: DataType
    public let extendedAttributesOfDataType: ExtendedAttributeList?
    public let defaultValue: DefaultValue?
}

public enum Partial: Definition {

    case interface(Interface, ExtendedAttributeList)
    case mixin(Mixin, ExtendedAttributeList)
    case dictionary(Dictionary, ExtendedAttributeList)
    case namespace(Namespace, ExtendedAttributeList)
}

public struct Namespace: Definition {
    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let namespaceMembers: [NamespaceMember]
}

public enum NamespaceMember {

    case regularOperation(RegularOperation, ExtendedAttributeList)
    case readonlyAttribute(AttributeRest)
}

public struct Enum: Definition {

    public let identifier: String
    public let extendedAttributeList: ExtendedAttributeList
    public let enumValues: [EnumValue]
}

public struct EnumValue {

    public let string: String
}

public enum ReadOnlyMember {
    case attribute(AttributeRest)
    case maplike(MaplikeRest)
    case setlike(SetlikeRest)
}

public enum Operation {
    case regular(RegularOperation)
    case special(Special, RegularOperation)
}

public struct RegularOperation {

    public let returnType: ReturnType
    public let operationName: OperationName?
    public let argumentList: [Argument]
}

public enum OperationName {
    case identifier(String)
    case includes
}

public struct OperationRest {
    public let optioalOperationName: OperationName?
    public let argumentList: [Argument]
}

public enum Special: String, Equatable, Hashable {

    case getter
    case setter
    case deleter
}

public struct Argument {

    public let rest: ArgumentRest
    public let extendedAttributeList: ExtendedAttributeList
}

public indirect enum ArgumentRest {
    case optional(TypeWithExtendedAttributes, ArgumentName, DefaultValue?)
    case nonOptional(DataType, Bool, ArgumentName)
}

public enum ArgumentName {
    case identifier(String)
    case argumentNameKeyword(ArgumentNameKeyword)
}

public struct AttributeRest {

    public let typeWithExtendedAttributes: TypeWithExtendedAttributes
    public let attributeName: AttributeName
}

public enum AttributeName {
    case attributeNameKeyword(AttributeNameKeyword)
    case identifier(String)
}

public enum AttributeNameKeyword: String {
    case async
    case required
}

public struct MaplikeRest {

    public let keyType: TypeWithExtendedAttributes
    public let valueType: TypeWithExtendedAttributes
}

public struct SetlikeRest {
    public let dataType: TypeWithExtendedAttributes
}

public enum DefaultValue {
    case constValue(ConstValue)
    case string(String)
    case emptyList
    case emptyDictionary
    case null
}

public enum ConstType {

    case identifier(String)
    case primitiveType(PrimitiveType)
}

public enum ConstValue {
    case booleanLiteral(Bool)
    case floatLiteral(FloatLiteral)
    case integer(Int)
}

public enum FloatLiteral {

    case decimal(Double)
    case negativeInfinity
    case infinity
    case notANumber
}

public struct IncludesStatement: Definition {

    public let child: String
    public let parent: String
    public let extendedAttributeList: ExtendedAttributeList
}

public struct Typedef: Definition {

    public let identifier: String
    public let dataType: DataType
    public let extendedAttributeList: ExtendedAttributeList
}

public struct TypeWithExtendedAttributes {

    public let dataType: DataType
    public let extendedAttributeList: ExtendedAttributeList
}

public indirect enum DataType {
    case single(SingleType)
    case union([UnionMemberType], Bool)
}

public indirect enum SingleType {

    case distinguishableType(DistinguishableType)
    case any
    case promiseType(Promise)
}

public enum UnionMemberType {

    case distinguishableType(ExtendedAttributeList, DistinguishableType)
    case nullableUnionType([UnionMemberType], Bool)
}

@frozen
public enum DistinguishableType {

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


public struct Iterable {

    public let typeWithExtendedAttributes0: TypeWithExtendedAttributes
    public let typeWithExtendedAttributes1: TypeWithExtendedAttributes?
}

public struct AsyncIterable {

    public let typeWithExtendedAttributes0: TypeWithExtendedAttributes
    public let typeWithExtendedAttributes1: TypeWithExtendedAttributes
}

public enum ReturnType {
    case void
    case dataType(DataType)
}

public enum ReadWriteAttribute {
    case inherit(AttributeRest)
    case notInherit(AttributeRest)
}

public struct Promise {

    public let returnType: ReturnType
}

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

public struct RecordType {

    public let stringType: StringType
    public let typeWithExtendedAttributes: TypeWithExtendedAttributes
}

public enum PrimitiveType {
    case UnsignedIntegerType(UnsignedIntegerType)
    case UnrestrictedFloatType(UnrestrictedFloatType)
    case boolean
    case byte
    case octet
}

public enum UnrestrictedFloatType {
    case unrestricted(FloatType)
    case restricted(FloatType)
}

public enum FloatType: String, Equatable, Hashable {
    case float
    case double
}

public enum UnsignedIntegerType {
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

public enum Stringifier {
    case readOnlyAttributeRest(Bool, TypeWithExtendedAttributes, AttributeName)
    case regular(RegularOperation)
    case empty
}
