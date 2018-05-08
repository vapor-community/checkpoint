import XCTest

import CheckpointTests

var tests = [XCTestCaseEntry]()
tests += CheckpointTests.allTests()
XCTMain(tests)