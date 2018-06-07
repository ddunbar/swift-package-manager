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
    public init() {}
    
    public func solve(formula: Formula) throws -> Assignment? {
        // Find all of the variables.
        let variables = Set(formula.clauses.flatMap{ $0.terms.map{ $0.variable } })

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

/// A basic Davis–Putnam–Logemann–Loveland solver.
///
/// See: https://en.wikipedia.org/wiki/DPLL_algorithm
public class DPLLSolver: Solver {
    public init() {}
    
    public func solve(formula: Formula) throws -> Assignment? {
        // First, perform unit propagation and pure literal elimination.
        var formula = formula
        formula = formula.propagatingUnits()
        formula = formula.eliminatingPureLiterals()

        // Next, find the unit assignments and see if the formula is resolved.
        let unitValues: [Variable: Bool] = Dictionary(uniqueKeysWithValues: formula.clauses.compactMap{
                guard $0.terms.count == 1 else {
                    return nil
                }
                return ($0.terms[0].variable, $0.terms[0].positive)
            })

        // If the satisfiability is determined by the unit assignment, we are done.
        let assignment = Assignment(bindings: unitValues)
        if let result = formula.isSatisfied(by: assignment) {
            return result ? assignment : nil
        }
        
        // Otherwise, select a non-unit literal and split with each potential assignment.
        let splitOn = selectNonUnitLiteral(from: formula)
        return try solve(formula: Formula(clauses: [Clause(terms: Term(splitOn))] + formula.clauses)) ??
                   solve(formula: Formula(clauses: [Clause(terms: Term(not: splitOn))] + formula.clauses))
    }

    /// Pick a literal which does not appear as a unit, if possible.
    ///
    /// The formula must not be trivially solvable (it must have a non-unit
    /// clause).
    private func selectNonUnitLiteral(from formula: Formula) -> Variable {
        // We should never see a trivially satisfiable formula.
        assert(!formula.clauses.isEmpty)
        assert(formula.clauses.filter{ $0.terms.isEmpty }.isEmpty)

        // We currently just pick the first variable from the first clause.
        guard let nonUnit = formula.clauses.first(where: { $0.terms.count != 1 }) else {
            fatalError("missing any non-unit clauses")
        }

        // We are guaranteed this variable is non-unit, because of unit propagation.
        return nonUnit.terms[0].variable
    }
}

public func solve(formula: Formula) throws -> Assignment? {
    return try DPLLSolver().solve(formula: formula)
}
