// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

import SAT

private let v0 = Variable(0)
private let v1 = Variable(1)
private let v2 = Variable(2)

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

    func testDPLLSolver() throws {
        // Check a basic instance.
        do {
            let formula = Formula(clauses: 
                Clause(terms: Term(not: v0), Term(not: v1)),
                Clause(terms: Term(v0), Term(v1)))
            guard let result = try DPLLSolver().solve(formula: formula) else {
                XCTFail("formula was not solved, but should have been")
                return
            }
            let r0 = result.bindings[v0]!
            let r1 = result.bindings[v1]!
            XCTAssertTrue((!r0 || !r1) && (r0 || r1))
        }
    }
}
