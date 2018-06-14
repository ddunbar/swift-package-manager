// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

/// A conflict-driven clause learning solver.
///
/// See: https://en.wikipedia.org/wiki/Conflict-Driven_Clause_Learning
public class CDCLSolver: Solver {
    /// The current solver context.
    public struct Context {
        /// The solver the context is operating for.
        public let solver: CDCLSolver
        
        /// The formula being solved.
        public let formula: Formula
        
        /// The current stack of decisions.
        ///
        /// This stack always represents a _consistent_ set of assignments (the
        /// formula is not unsatisfied by the induced assignment).
        public var decisions: [Decision] = []

        /// The current implication graph.
        public var implications: ImplicationGraph = ImplicationGraph.empty

        /// The list of learned clauses.
        public var learnedClauses: [Clause] = []

        /// The currently induced assignment.
        public var currentAssignment: Assignment {
            return implications.currentAssignment
        }

        /// Create an initial empty solution context.
        public init(solver: CDCLSolver, formula: Formula) {
            self.solver = solver
            self.formula = formula
        }
    }
    
    /// An individual decision made by the solver.
    public struct Decision {
        /// The level at which the decision was made.
        public let level: Int

        /// The variable that was selected.
        public let variable: Variable

        /// The assignment that was made.
        public let value: Bool

        /// The resulting implication graph.
        public let implications: ImplicationGraph
    }

    /// The graph of assignments resulting from prior decisions.
    public struct ImplicationGraph: CustomStringConvertible {
        /// The empty implication graph.
        static let empty = ImplicationGraph(nodes: [], edges: [])
        
        /// A node in the graph consists of a variable assignment.
        public struct Node: CustomStringConvertible {
            /// The variable that was selected.
            public let variable: Variable

            /// The selected value for the variable.
            public let value: Bool

            /// The decision level at which this node was created. 
            public let decisionLevel: Int

            public var description: String {
                return "Node{\(variable)\(value ? "" : "'")@\(decisionLevel)}"
            }
        }

        /// An edge represents the source of an implication.
        public struct Edge: CustomStringConvertible {
            /// The source node.
            public let source: Node

            /// The destination node.
            public let destination: Node

            /// The constraint which caused the implication.
            public let cause: Clause

            public var description: String {
                return "Edge{src: \(source), dst: \(destination), cause: \(cause) }"
            }
        }

        /// The list of nodes.
        public var nodes: [Node]

        /// The list of edges.
        public var edges: [Edge]

        /// The currently induced assignment.
        public var currentAssignment: Assignment {
            return Assignment(bindings: Dictionary(uniqueKeysWithValues: nodes.map {
                        ($0.variable, $0.value)
                    }))
        }

        public var description: String {
            return """
                ImplicationGraph{
                    nodes: \(nodes),
                    edges: [
                        \(edges.map{ String(describing: $0) }.joined(separator: ",\n        "))] }
                """
        }
    }

    /// An arbitrary intermediate state of the solver algorithm.
    public enum IntermediateState {
        /// An individual decision which was made.
    case decision(Decision)
    }

    public enum IntermediateOrResult {
    case intermediate(IntermediateState)
    case result(Assignment?)
    }
    
    public var iterations = 0
    
    public init() {}

    public func solveWithIntermediateStates(formula: Formula) -> AnySequence<IntermediateOrResult> {
        let context = Context(solver: self, formula: formula)
        var done = false
        let result = sequence(state: context) { context -> IntermediateOrResult? in
            // If we already completed, the sequence is finished.
            if done {
                return nil
            }
            
            // If the state is complete, we are done.
            let assignment = context.currentAssignment
            if let result = formula.isSatisfied(by: assignment) {
                // The state should only ever encode a satisfiable state.
                assert(result)
                done = true
                return .result(assignment)
            }

            // Otherwise, step the solver.
            guard let next = context.stepOnce() else {
                // If solver cannot step the context, then the formula is not satisfiable.
                return .result(nil)
            }

            return .intermediate(next)
        }
        return AnySequence(result)
    }
    
    public func solve(formula: Formula) throws -> Assignment? {
        // FIXME: Consider pre-filtering (an upfront unit propagation step).

        for case let .result(result) in solveWithIntermediateStates(formula: formula) {
            return result
        }
        fatalError("no result provided")
    }
}

private extension CDCLSolver.Context {
    /// Perform a single solver step and update the context.
    ///
    /// - Returns: An intermediate state representing the change, if
    ///   possible. If the context cannot be stepped (the formula is
    ///   unsatisfiable), returns nil.
    //
    // FIXME: We should extend this so it can report multiple intermediate
    // states.
    mutating func stepOnce() -> CDCLSolver.IntermediateState? {
        solver.iterations += 1

        // Select a new literal to branch on.
        let selectedVariables = Set(currentAssignment.bindings.keys)
        let allVariables = Set(formula.clauses.flatMap{ $0.terms.map{ $0.variable } })
        let selectableVariables = allVariables.lazy.filter{ !selectedVariables.contains($0) }
        guard let selected = selectableVariables.min(by: { $0.id < $1.id }) else {
            // There are no unselected variables. This should never actually be
            // reached in practice, but it is not an error per se.
            return nil
        }

        // Perform unit propagation using the new binding.
        guard let implications = propagateUnits(binding: selected, to: true, on: implications) else {
            // FIXME: We reached a conflict, we don't know how to do conflict resolution yet.
            fatalError("error: conflict resolution is not yet implemented")
        }
        
        // Create a new decision.
        let decision = CDCLSolver.Decision(
            level: decisions.count + 1,
            variable: selected, value: true,
            implications: implications)

        // Update the context.
        self.decisions.append(decision)
        self.implications = implications

        return .decision(decision)
    }

    /// Perform unit propagation after a new assignment.
    ///
    /// - Returns: The new implication graph, if the assignment is consistent.
    mutating func propagateUnits(
        binding variable: Variable, to value: Bool, on implications: CDCLSolver.ImplicationGraph,
        cause: Clause? = nil
    ) -> CDCLSolver.ImplicationGraph?
    {
        // Get the current assignment.
        let assignment = implications.currentAssignment
        var implications = implications

        if let prior = assignment.bindings[variable] {
            // Ignore redundant bindings.
            if prior == value {
                return implications
            }

            // Otherwise, we found a conflict.
            fatalError("FIXME: Handle redundant unit binding")
        }
        
        // First, add the new binding to the graph.
        let node = CDCLSolver.ImplicationGraph.Node(
            variable: variable, value: value, decisionLevel: self.decisions.count + 1)
        implications.nodes.append(node)

        // Add the implication edges, if there is a cause.
        if let cause = cause {
            implications.edges += cause.terms.compactMap{ term in
                // Ignore the node being bound.
                if term.variable == variable {
                    return nil
                }

                // Find the node where this term was bound.
                return CDCLSolver.ImplicationGraph.Edge(
                    source: implications.nodes.first(where: { $0.variable == term.variable })!,
                    destination: node,
                    cause: cause)
            }
        }
        
        // Iterate over every clause in the formula + learned clauses, looking
        // for new units.
        //
        // FIXME: This is fairly ugly and **very** slow.
        var newUnits: [(Variable, value: Bool, cause: Clause)] = []
        for clause in formula.clauses + learnedClauses {
            // Ignore formulas which don't contain the bound variable.
            guard clause.terms.first(where: { $0.variable == variable }) != nil else { continue }
            
            // If this clause is already satisfied, ignore it.
            if let result = clause.isSatisfied(by: assignment) {
                assert(result)
                continue
            }
            
            // This clause has become a unit if it has two unassigned variables,
            // and one is the variable being assigned.
            let unassignedVariables = Set(clause.terms.compactMap{ term in
                    return assignment.bindings.contains(key: term.variable) ? nil : term.variable
                })

            // The unassigned variables should always include the variable being bound.
            assert(unassignedVariables.contains(variable))
            switch unassignedVariables.count {
            case 1:
                // The term has become fully bound.
                let term = clause.terms.first(where: { $0.variable == variable })!
                if term.positive == value {
                    // The term is now satisfied, ignore it.
                    continue
                } else {
                    // Otherwise, the clause is now unsatisfiable.
                    return nil
                }

            case 2:
                // We found a clause which will become satisfied or unit.

                // FIXME: This code is probably broken if a clause can have
                // redundant terms. We should disallow that as an invariant.

                // Find the assigned term.
                let term = clause.terms.first(where: { $0.variable == variable })!
                if term.positive == value {
                    // The term is now satisfied, ignore it.
                    continue
                } else {
                    // Otherwise, the other term is now a unit.
                    let otherVariable = unassignedVariables.first(where: { $0 != variable })!
                    let otherTerm = clause.terms.first(where: { $0.variable == otherVariable })!
                    let otherValue = otherTerm.positive
                    newUnits.append((otherVariable, otherValue, clause))
                }

            default:
                continue
            }
        }

        // Apply the new units.
        for (otherVariable, otherValue, cause) in newUnits {
            // Add to the implication graph.
            if let result = propagateUnits(binding: otherVariable, to: otherValue, on: implications, cause: cause) {
                implications = result
            } else {
                // FIXME: Allow representation of an unresolvable implication graph.
                return nil
            }
        }

        return implications
    }
}
