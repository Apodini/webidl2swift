//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import Foundation

enum State {
    case regular
    case identifier
    case integerLiteral
    case hexLiteral
    case decimalLiteral
    case stringLiteral
    case escapedChar
    case startOfComment
    case comment
    case startOfEllipsis
    case ellipsis
    case multilineComment
    case maybeEndOfMultilineComment
}
