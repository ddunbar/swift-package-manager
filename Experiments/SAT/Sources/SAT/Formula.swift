// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A boolean logical formula in CNF, a conjunction of disjunctive clauses.
public struct Formula: CustomStringConvertible, Equatable {
    /// The list of clauses forming the conjunction.
    public let clauses: [Clause]

    public init(clauses: [Clause]) {
        self.clauses = clauses
    }

    public init(clauses: Clause...) {
        self.init(clauses: clauses)
    }

    /// The canonical unsatisfiable formula.
    static public var unsatisfiable: Formula {
        return Formula(clauses: Clause())
    }
    
    /// Check if the formula is satisfied by a given assignment.
    public func isSatisfied(by assignment: Assignment) -> Bool? {
        var hadIndeterminate = false
        
        // The formula is satisfied if all clauses are satisfied.
        for clause in self.clauses {
            guard let result = clause.isSatisfied(by: assignment) else {
                // Track if we had any indeterminate clause.
                hadIndeterminate = true
                continue
            }

            // If any clause is unsatisfied, the formula is unsatisfiable.
            if !result {
                return false
            }
        }

        // If there was an indeterminate formula, and no unsatisfied clauses,
        // the formula is indeterminate.
        if hadIndeterminate {
            return nil
        }
        
        return true
    }

    public var description: String {
        // An empty formula is a special case (and true).
        if clauses.isEmpty {
            return "T"
        }
        
        return clauses.map{ String(describing: $0) }.joined(separator: " ⋏ ")
    }
}

/// An individual disjunctive clause in a boolean formula.
public struct Clause: CustomStringConvertible, Equatable {
    /// The terms in the clause.
    public let terms: [Term]

    /// Create a new clause from a list of terms.
    public init(terms: [Term]) {
        self.terms = terms
    }

    /// Create a new clause from a list of terms.
    public init(terms: Term...) {
        self.init(terms: terms)
    }
    
    /// Check if the clause is satisfied by a given assignment.
    ///
    /// If the clause references an unbound variable, the result is indeterminate.
    public func isSatisfied(by assignment: Assignment) -> Bool? {
        var hadIndeterminate = false

        // The clause is satisfied if any term is satisfied.
        for term in terms {
            guard let result = term.isSatisfied(by: assignment) else {
                // Track if we had any indeterminate clause.
                hadIndeterminate = true
                continue
            }

            // If any clause is satisfied, the clause is satisfiable.
            if result {
                return true
            }
        }

        // If there was an indeterminate term, and no satisfied terms, the
        // clause is indeterminate.
        if hadIndeterminate {
            return nil
        }

        return false
    }

    /// Compute the resolution operation of two clauses, where `variable` occurs
    /// with mixed polarity in each.
    ///
    /// - Returns: The resolution, unless the result is tautological.
    public func resolution(with clause: Clause, on variable: Variable) -> Clause? {
        var terms: [Term] = []
        var polarities: [Variable: Bool] = [:]
        var hasNegative = false, hasPositive = false
        for term in self.terms + clause.terms {
            if term.variable == variable {
                if term.positive {
                    assert(!hasPositive)
                    hasPositive = true
                } else {
                    assert(!hasNegative)
                    hasNegative = true
                }
            } else {
                // Check if we have already seen this term.
                if let prior = polarities[term.variable] {
                    if term.positive != prior {
                        // We found a tautology.
                        return nil
                    }
                    continue
                }

                polarities[term.variable] = term.positive
                terms.append(term)
            }
        }
        assert(hasPositive && hasNegative)
        return Clause(terms: terms)
    }
    
    public var description: String {
        // An empty clause is a special case (and false).
        if terms.isEmpty {
            return "F"
        }
        
        return "(" + terms.map{ String(describing: $0) }.joined(separator: " ⋎ ") + ")"
    }
}

/// An individual term in a clause.
public struct Term: CustomStringConvertible, Hashable {
    /// The variable the term refers to.
    public let variable: Variable

    /// Whether the variable must be true (if it is not negated).
    public let positive: Bool

    /// Create a new term.
    public init (_ variable: Variable, positive: Bool = true) {
        self.variable = variable
        self.positive = positive
    }

    /// Create a new term for the negation of a variable.
    public init(not variable: Variable) {
        self.init(variable, positive: false)
    }
    
    /// Check if the clause is satisfied by a given assignment.
    ///
    /// If the clause references an unbound variable, the result is indeterminate.
    public func isSatisfied(by assignment: Assignment) -> Bool? {
        guard let result = assignment.bindings[variable] else {
            return nil
        }
        return result == positive
    }

    public var description: String {
        return String(describing: variable) + (positive ? "" : "'")
    }
}

/// A formula variable.
public struct Variable: CustomStringConvertible, Hashable {
    /// A unique ID for the variable.
    public let id: Int

    public init(_ id: Int) {
        self.id = id
    }

    public var description: String {
        return "ν\(self.id)"
    }
}
