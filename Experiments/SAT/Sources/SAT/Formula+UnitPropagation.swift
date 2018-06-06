// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

public extension Formula {
    /// Perform unit propagation on the formula.
    ///
    /// See: https://en.wikipedia.org/wiki/Unit_propagation
    ///
    /// - Returns: The new formula, with units propagated.
    public func propagatingUnits() -> Formula {
        // FIXME: If the term is not normalized, we could miss a unit
        // here. Should we have a normalization step somewhere, and assert
        // that things are normalized?

        // First, find all units and their polarity.
        var unitValues: [Variable: Bool] = [:]
        for clause in clauses where clause.terms.count == 1 {
            assert(!clause.terms.isEmpty)
            let term = clause.terms[0]
            unitValues[term.variable] = term.positive
        }

        // Substitute all clauses.
        let assignment = Assignment(bindings: unitValues)
        var replacementClauses: [Clause] = []
        for clause in clauses {
            // Ignore the unit clauses themselves.
            if clause.terms.count == 1 {
                replacementClauses.append(clause)
                continue
            }
                
            guard let replacement = clause.propagating(assignment) else {
                // If there is no replacement, the clause is true and can be dropped.
                continue
            }

            // If this clause is empty, then the formula is unsatisfiable.
            if clause.terms.isEmpty {
                return Formula.unsatisfiable
            }

            replacementClauses.append(replacement)
        }

        return Formula(clauses: replacementClauses)
    }
}

public extension Clause {
    /// Return a new clause derived by propagting a mapping of variable values.
    ///
    /// - Returns: The new clause, if possible, or false if the clause would
    ///   become true (this is not currently trivially representable).
    func propagating(_ assignment: Assignment) -> Clause? {
        var replacementTerms: [Term] = []
        for term in terms {
            // If the term is indeterminate, it is preserved.
            guard let satisfied = term.isSatisfied(by: assignment) else {
                replacementTerms.append(term)
                continue
            }

            // If the term is satisfied, the clause is true.
            if satisfied {
                return nil
            }

            // Otherwise, the term is false and can be dropped.
        }

        return Clause(terms: replacementTerms)
    }
}
