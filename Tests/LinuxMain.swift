//
//  Created by Manuel Burghard. Licensed unter MIT.
//

import XCTest

import webidl2swiftTests

var tests = [XCTestCaseEntry]()
tests += webidl2swiftTests.allTests()
tests += TokenizerTests.allTests()
tests += ParserTests.allTests()
XCTMain(tests)
