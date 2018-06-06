// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

import SAT

final class TermTests: XCTestCase {
    func testIsSatisfied() {
        let v0 = Variable(0)

        XCTAssertEqual(Term(v0).isSatisfied(by: Assignment(bindings: [:])), nil)
        XCTAssertEqual(Term(v0).isSatisfied(by: Assignment(bindings: [v0: true])), true)
        XCTAssertEqual(Term(v0).isSatisfied(by: Assignment(bindings: [v0: false])), false)
    }

    func testDescription() {
        XCTAssertEqual(
            String(describing: Clause(terms: [])),
            "F")
        XCTAssertEqual(
            String(describing: Clause(terms: Term(Variable(0)))),
            "(ν0)")
        XCTAssertEqual(
            String(describing: Clause(terms:
                    Term(Variable(0)),
                    Term(Variable(1)))),
            "(ν0 ⋎ ν1)")
    }
}
