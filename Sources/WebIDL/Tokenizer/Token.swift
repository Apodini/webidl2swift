//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation
import SwiftSyntax

extension SourceLocation: Equatable {
    public static func ==(left: Self, right: Self) -> Bool {
        return left.offset == right.offset &&
            left.column == right.column &&
            left.line == right.line &&
            left.file == right.file
    }
}

extension SourceLocation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(offset)
        hasher.combine(column)
        hasher.combine(line)
        hasher.combine(file)
    }
}

extension SourceRange: Equatable {
    public static func ==(left: Self, right: Self) -> Bool {
        return left.start == right.start && left.end == right.end
    }
}

extension SourceRange: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(start)
        hasher.combine(end)
    }
}

public struct Token: Hashable {
    let kind: Kind
    let range: SourceRange

    public enum Kind: Hashable, CustomStringConvertible {
        case terminal(Terminal)

        case integer                    //  =   /-?([1-9][0-9]*|0[Xx][0-9A-Fa-f]+|0[0-7]*)/
        case decimal                    //  =   /-?(([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)([Ee][+-]?[0-9]+)?|[0-9]+[Ee][+-]?[0-9]+)/
        case identifier                 //  =   /[_-]?[A-Za-z][0-9A-Z_a-z-]*/
        case string                     //  =   /"[^"]*"/
        case other                      //  =   /[^\t\n\r 0-9A-Za-z]/
        case comment(String)
        case multilineComment(String)

        public var description: String {

            switch self {
            case .terminal(let terminal):
                return ".terminal(\(terminal.description))"
            case .integer:
                return ".integer"
            case .decimal:
                return ".decimal"
            case .identifier:
                return ".identifer"
            case .string:
                return ".string"
            case .other:
                return ".other"
            case .comment:
                return ".comment"
            case .multilineComment:
                return ".multilineComment"
            }
        }
    }
}
