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

final class ClauseTests: XCTestCase {
    func testIsSatisfied() {
        // Check a unary clause.
        XCTAssertEqual(Clause(terms: Term(v0)).isSatisfied(by: Assignment(bindings: [:])), nil)
        XCTAssertEqual(Clause(terms: Term(v0)).isSatisfied(by: Assignment(bindings: [v0: true])), true)
        XCTAssertEqual(Clause(terms: Term(v0)).isSatisfied(by: Assignment(bindings: [v0: false])), false)

        // Check binary clauses.
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).isSatisfied(by:
                Assignment(bindings: [:])), nil)
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).isSatisfied(by:
                Assignment(bindings: [v0: true])), true)
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).isSatisfied(by:
                Assignment(bindings: [v0: false])), nil)
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).isSatisfied(by:
                Assignment(bindings: [v1: true])), nil)
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).isSatisfied(by:
                Assignment(bindings: [v1: false])), true)

        for a in [false, true] {
            for b in [false, true] {
                XCTAssertEqual(
                    Clause(terms: Term(v0), Term(not: v1)).isSatisfied(by:
                        Assignment(bindings: [v0: a, v1: b])),
                    a || !b)
            }
        }
    }

    func testPropagation() {
        XCTAssertEqual(
            Clause(terms: Term(v0)).propagating(Assignment(bindings: [:])),
            Clause(terms: Term(v0)))
        XCTAssertEqual(
            Clause(terms: Term(v0)).propagating(Assignment(bindings: [v0: true])),
            nil)
        XCTAssertEqual(
            Clause(terms: Term(v0)).propagating(Assignment(bindings: [v0: false])),
            Clause(terms: []))

        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).propagating(Assignment(bindings: [:])),
            Clause(terms: Term(v0), Term(not: v1)))
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).propagating(Assignment(bindings: [v0: true])),
            nil)
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).propagating(Assignment(bindings: [v0: false])),
            Clause(terms: Term(not: v1)))
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).propagating(Assignment(bindings: [v1: true])),
            Clause(terms: Term(v0)))
        XCTAssertEqual(
            Clause(terms: Term(v0), Term(not: v1)).propagating(Assignment(bindings: [v1: false])),
            nil)
    }
}
