// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

import XCTest

import SAT

final class FormulaTests: XCTestCase {
    func testIsSatisfied() {
        let v0 = Variable(0)
        let v1 = Variable(1)

        // Check a unary formula.
        XCTAssertEqual(Formula(clauses: Clause(terms: Term(v0))).isSatisfied(by:
                Assignment(bindings: [:])), nil)
        XCTAssertEqual(Formula(clauses: Clause(terms: Term(v0))).isSatisfied(by:
                Assignment(bindings: [v0: true])), true)
        XCTAssertEqual(Formula(clauses: Clause(terms: Term(v0))).isSatisfied(by:
                Assignment(bindings: [v0: false])), false)

        // Check a binary formula.
        XCTAssertEqual(
            Formula(clauses:
                Clause(terms: Term(v0)),
                Clause(terms: Term(not: v1))
            ).isSatisfied(by:
                Assignment(bindings: [:])), nil)
        XCTAssertEqual(
            Formula(clauses:
                Clause(terms: Term(v0)),
                Clause(terms: Term(not: v1))
            ).isSatisfied(by:
                Assignment(bindings: [v0: true])), nil)
        XCTAssertEqual(
            Formula(clauses:
                Clause(terms: Term(v0)),
                Clause(terms: Term(not: v1))
            ).isSatisfied(by:
                Assignment(bindings: [v0: false])), false)
        XCTAssertEqual(
            Formula(clauses:
                Clause(terms: Term(v0)),
                Clause(terms: Term(not: v1))
            ).isSatisfied(by:
                Assignment(bindings: [v1: true])), false)
        XCTAssertEqual(
            Formula(clauses:
                Clause(terms: Term(v0)),
                Clause(terms: Term(not: v1))
            ).isSatisfied(by:
                Assignment(bindings: [v1: false])), nil)

        for a in [false, true] {
            for b in [false, true] {
                XCTAssertEqual(
                    Formula(clauses:
                        Clause(terms: Term(v0)),
                        Clause(terms: Term(not: v1))
                    ).isSatisfied(by:
                        Assignment(bindings: [v0: a, v1: b])),
                    a && !b)
            }
        }
    }

    func testDescription() {
        XCTAssertEqual(
            String(describing: Formula(clauses: [])),
            "T")
        XCTAssertEqual(
            String(describing: Formula(clauses: Clause(terms: Term(Variable(0))))),
            "(ν0)")
        XCTAssertEqual(
            String(describing: Formula(clauses:
                    Clause(terms: Term(Variable(0))),
                    Clause(terms: Term(Variable(1))))),
            "(ν0) ⋏ (ν1)")
    }
}
