// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

import SAT

final class SolverTests: XCTestCase {
    func testBasics() throws {
        let v0 = Variable(0) 

        XCTAssertEqual(
            try solve(formula:
                Formula(clauses: Clause(terms: Term(v0)))),
            Assignment(bindings: [v0: true]))

        XCTAssertEqual(
            try solve(formula:
                Formula(clauses: Clause(terms: Term(not: v0)))),
            Assignment(bindings: [v0: false]))

        XCTAssertEqual(
            try solve(formula:
                Formula(clauses: 
                    Clause(terms: Term(v0)),
                    Clause(terms: Term(not: v0)))),
            nil)
    }
}
