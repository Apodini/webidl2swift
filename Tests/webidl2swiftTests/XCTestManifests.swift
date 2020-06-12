//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import XCTest

#if !canImport(ObjectiveC)
// swiftlint:disable:next missing_docs
public func allTests() -> [XCTestCaseEntry] {
    [
        testCase(webidl2swiftTests.allTests),
        testCase(TokenizerTests.allTests),
        testCase(ParserTests.allTests),
    ]
}
#endif
