//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

// swiftlint:disable identifier_name
public enum Terminal: String, Equatable, CustomStringConvertible {

    public var description: String {
        rawValue
    }

    case openingParenthesis = "("
    case closingParenthesis = ")"
    case openingCurlyBraces = "{"
    case closingCurlyBraces = "}"
    case openingSquareBracket = "["
    case closingSquareBracket = "]"
    case openingAngleBracket = "<"
    case closingAngleBracket = ">"
    case async = "async"
    case attribute = "attribute"
    case callback = "callback"
    case const = "const"
    case constructor = "constructor"
    case deleter = "deleter"
    case dictionary = "dictionary"
    case `enum` = "enum"
    case getter = "getter"
    case includes = "includes"
    case inherit = "inherit"
    case interface = "interface"
    case iterable = "iterable"
    case maplike = "maplike"
    case mixin = "mixin"
    case namespace = "namespace"
    case partial = "partial"
    case readonly = "readonly"
    case required = "required"
    case setlike = "setlike"
    case setter = "setter"
    case `static` = "static"
    case stringifier = "stringifier"
    case typedef = "typedef"
    case unrestricted = "unrestricted"
    case semicolon = ";"
    case colon = ":"
    case equalSign = "="
    case comma = ","
    case questionMark = "?"
    case dot = "."
    case ellipsis = "..."
    case minus = "-"

    case `true` = "true"
    case `false` = "false"

    case negativeInfinity = "-Infinity"
    case infinity = "Infinity"
    case nan = "NaN"

    case null = "null"
    case record = "record"
    case promise = "Promise"
    case sequence = "sequence"
    case object = "object"
    case symbol = "symbol"
    case or = "or"
    case any = "any"
    case optional = "optional"

    case ByteString = "ByteString"
    case DOMString = "DOMString"
    case USVString = "USVString"

    case boolean = "boolean"
    case byte = "byte"
    case octet = "octet"
    case float = "float"
    case double = "double"
    case unsigned = "unsigned"
    case short = "short"
    case long = "long"
    case undefined = "undefined"

    case ArrayBuffer = "ArrayBuffer"
    case DataView = "DataView"
    case Int8Array = "Int8Array"
    case Int16Array = "Int16Array"
    case Int32Array = "Int32Array"
    case Uint8Array = "Uint8Array"
    case Uint16Array = "Uint16Array"
    case Uint32Array = "Uint32Array"
    case Uint8ClampedArray = "Uint8ClampedArray"
    case Float32Array = "Float32Array"
    case Float64Array = "Float64Array"
    case FrozenArray = "FrozenArray"
}
// swiftlint:enable identifier_name
