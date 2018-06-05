// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

import SAT

final class AssignmentTests: XCTestCase {
    func testBasics() {
        let a = Assignment(bindings: [
                Variable(0): true,
                Variable(1): false ])
        XCTAssertEqual(String(describing: a), "{ν0=T,ν1=F}")
    }
}
