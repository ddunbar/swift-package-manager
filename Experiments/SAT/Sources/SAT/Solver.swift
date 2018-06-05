// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

/// An abstraction of a formula solver.
public protocol Solver {
    /// Find a satisfying assignment for the given formula, if one exists.
    func solve(formula: Formula) throws -> Assignment?
}

/// A brute force SAT solver.
public class BruteForceSolver: Solver {
    public func solve(formula: Formula) throws -> Assignment? {
        // Find all of the variables.
        let variables = Set(formula.clauses.flatMap{ [$0.a.variable, $0.b.variable, $0.c.variable] })

        // Iterate over all subsets of variables.
        for subset in variables.powerSet {
            // Create an assignment of these variables to true.
            let candidate = Assignment(bindings: Dictionary(
                    uniqueKeysWithValues: variables.map{ ($0, subset.contains($0)) }))

            if formula.isSatisfied(by: candidate)! {
                return candidate
            }
        }

        return nil
    }
}

public func solve(formula: Formula) throws -> Assignment? {
    return try BruteForceSolver().solve(formula: formula)
}
