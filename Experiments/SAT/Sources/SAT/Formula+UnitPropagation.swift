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

        // First, separate all unit and non-unit clauses, and find the implied
        // assignment.
        var unitValues: [Variable: Bool] = [:]
        var replacementClauses: [Clause] = []
        var nonUnitClauses: [Clause] = []
        for clause in clauses {
            // We only consider unit clauses first.
            guard clause.terms.count == 1 else {
                nonUnitClauses.append(clause)
                continue
            }
            
            assert(!clause.terms.isEmpty)
            let term = clause.terms[0]

            // Check if the term already has an assignment.
            if let priorValue = unitValues[term.variable] {
                // If so, this unit clause is either redundant or unsatisiable.
                if priorValue != term.positive {
                    return Formula.unsatisfiable
                } else {
                    continue
                }
            }
                
            // Otherwise, accumulate the assignment.
            replacementClauses.append(clause)
            unitValues[term.variable] = term.positive
        }

        // Substitute all clauses.
        let assignment = Assignment(bindings: unitValues)
        var hasNewUnits = false
        for clause in nonUnitClauses {
            guard let replacement = clause.propagating(assignment) else {
                // If there is no replacement, the clause is true and can be dropped.
                continue
            }

            // If this clause is empty, then the formula is unsatisfiable.
            if replacement.terms.isEmpty {
                return Formula.unsatisfiable
            }

            // Track whether we have uncovered new units.
            if replacement.terms.count == 1 {
                hasNewUnits = true
            }
            
            replacementClauses.append(replacement)
        }

        // Return the result, recursing if we discovered new units.
        let result = Formula(clauses: replacementClauses)
        return hasNewUnits ? result.propagatingUnits() : result
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
