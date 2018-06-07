// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

public extension Formula {
    /// Eliminate pure literals.
    ///
    /// The resulting formula will continue to contain a unit clause referencing
    /// any pure literals, so that the required polarity of it's assignment is
    /// implied.
    public func eliminatingPureLiterals() -> Formula {
        // First, identify all pure literals.
        var literalValues: [Variable: Bool?] = [:]
        for clause in clauses {
            for term in clause.terms {
                if let prior = literalValues[term.variable] {
                    // If the value has been seen, but the polarity is
                    // different, then this is not a pure literal.
                    if prior != term.positive {
                        literalValues[term.variable] = nil
                    }
                } else {
                    // Otherwise, if the term hasn't been seen just remember its polarity.
                    literalValues[term.variable] = term.positive
                }
            }
        }

        // Create an assignment for all pure literals.
        let assignment = Assignment(bindings:
            Dictionary(uniqueKeysWithValues: literalValues.compactMap{ (key, value) in
                    guard let positive = value else { return nil }
                    return (key, positive)
                }))

        // Create a new set of unit clauses for each binding.
        var replacementClauses: [Clause] = []
        for (key, positive) in assignment.bindings.sorted(by: { $0.0.id < $1.0.id }) {
            replacementClauses.append(Clause(terms: Term(key, positive: positive)))
        }
        
        // Drop clauses with pure literals.
        for clause in clauses {
            if !clause.terms.contains(where: { literalValues.index(forKey: $0.variable) != nil }) {
                replacementClauses.append(clause)
            }
        }
        
        return Formula(clauses: replacementClauses)
    }
}
