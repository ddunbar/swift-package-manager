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
        ///
        /// In addition, unless the decision stack is empty then there are no
        /// trivial unit clauses.
        public var decisions: [Decision] = []

        /// The current implication graph.
        ///
        /// - Invariant: The formula is not unsatisfiable under this graph.
        public var implications: ImplicationGraph {
            return decisions.last?.implications ?? ImplicationGraph.empty
        }

        /// The list of learned clauses.
        public var learnedClauses: [Clause] = []

        /// The corresponding derivations for the learned clauses.
        public var learnedClauseDerivations: [ClauseDerivation] = []

        /// The currently induced assignment.
        public var currentAssignment: Assignment {
            return implications.currentAssignment!
        }

        /// Create an initial empty solution context.
        public init(solver: CDCLSolver, formula: Formula) {
            assert(formula != Formula.unsatisfiable)
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
        public static let empty = ImplicationGraph(nodes: [], edges: [], bindings: [:], conflicts: [])
        
        /// A node in the graph consists of a variable assignment.
        public struct Node: CustomStringConvertible, Equatable {
            /// The variable that was selected.
            public let variable: Variable

            /// The selected value for the variable.
            public let value: Bool

            /// The decision level at which this node was created. 
            public let decisionLevel: Int

            public init(variable: Variable, value: Bool, decisionLevel: Int) {
                self.variable = variable
                self.value = value
                self.decisionLevel = decisionLevel
            }
            
            public var description: String {
                return "Node{\(variable)\(value ? "" : "'")@\(decisionLevel)}"
            }
        }

        /// An edge represents the source of an implication.
        public struct Edge: CustomStringConvertible, Equatable {
            /// The source node, if any (a missing source node indicates an
            /// implication via a unit clause).
            public let source: Node?

            /// The destination node.
            public let destination: Node

            /// The constraint which caused the implication.
            public let cause: Clause

            public init(destination: Node, cause: Clause) {
                self.source = nil
                self.destination = destination
                self.cause = cause
            }

            public init(source: Node, destination: Node, cause: Clause) {
                self.source = source
                self.destination = destination
                self.cause = cause
            }

            public var description: String {
                return "Edge{src: \(String(describing: source)), dst: \(destination), cause: \(cause) }"
            }
        }

        /// The list of nodes.
        public private(set) var nodes: [Node]

        /// The list of edges.
        public private(set) var edges: [Edge]

        /// The current binding assignments.
        public private(set) var bindings: [Variable: Bool]

        /// The list of discovered conflicts.
        public private(set) var conflicts: [(Variable, decisionLevel: Int, cause: Clause)]

        /// Whether this implication graph is in a conflict state.
        public var isInConflict: Bool {
            return !conflicts.isEmpty
        }
        
        /// The currently induced assignment.
        public var currentAssignment: Assignment? {
            guard conflicts.isEmpty else {
                return nil
            }
            
            return Assignment(bindings: bindings)
        }

        /// Bind a variable to a value.
        ///
        /// - Parameters:
        ///   - variable: The variable to bind.
        ///   - value: The value for the variable.
        ///   - cause: If given, the clause which caused this binding.
        /// - Returns: True if the binding was added (false if the variable was already bound).
        public mutating func bind(_ variable: Variable, to value: Bool, decisionLevel: Int, cause: Clause? = nil) -> Bool {
            // Check if this value is already bound...
            if let prior = bindings[variable] {
                // If so, see if it is a conflict.
                if prior != value {
                    guard let cause = cause else {
                        // We never expect to see an explicit conflicting
                        // binding (this would imply the algorithm made an
                        // obvious false choice).
                        fatalError("unexpected explicit conflict with no cause")
                    }
                    conflicts.append((variable, decisionLevel, cause))
                }
                return false
            }

            // Add a new node for the binding.
            let node = Node(variable: variable, value: value, decisionLevel: decisionLevel)
            nodes.append(node)
            bindings[variable] = value

            // Add the implication edges, if there is a cause.
            if let cause = cause {
                // Add the conflict edges.
                if cause.terms.count == 1 {
                    // Unit clauses are a special case.
                    edges.append(Edge(destination: node, cause: cause))
                } else {
                    // Otherwise add an edge for every term (except the variable being bound).
                    assert(cause.terms.first(where: { $0.variable == variable }) != nil)
                    for term in cause.terms where term.variable != variable {
                        // Find the node where this term was bound.
                        let source = nodes.first(where: { $0.variable == term.variable })!
                        edges.append(Edge(source: source, destination: node, cause: cause))
                    }
                }
            }

            return true
        }
        
        /// Analyze the graph (presumed to be in a conflict state) to produce a new
        /// clause to learn.
        ///
        /// The resulting clause is guaranteed to be consistent with the original
        /// formula.
        public func analyzeConflict() -> (Clause, ClauseDerivation) {
            /// Find an implied variable (one not set via a direct decision) in the
            /// clause which was set at the given `decisionLevel`, if present.
            ///
            /// The clause is presumed to only have nodes which have been
            /// assigned. (FIXME: If we relaxed that restriction, this would make
            /// sense as a general purpose method, but it would be less resilient to
            /// bugs).
            func findImpliedVariable(in clause: Clause, at decisionLevel: Int) -> Variable? {
                for term in clause.terms {
                    let variable = term.variable
                    let node = nodes.first(where: { $0.variable == variable })!

                    if node.decisionLevel == decisionLevel,
                    edges.first(where: { $0.destination == node }) != nil {
                        return variable
                    }
                }
                return nil
            }

            precondition(isInConflict)

            // We currently only handle a single conflict.
            guard conflicts.count == 1 else {
                fatalError("unexpected multiple conflicts, not yet supported")
            }

            let decisionLevel = conflicts[0].decisionLevel
            var clause = conflicts[0].cause
            var derivation = ClauseDerivation()

            // While there are implied variables at the current level, perform a resolution.
            while let variable = findImpliedVariable(in: clause, at: decisionLevel) {
                // Select a predecessor.
                let implication = edges.first(where: { $0.destination.variable == variable })!

                // Compute the resolution of the implication cause and the result.
                derivation.append((clause, implication.cause, variable))
                clause = clause.resolution(with: implication.cause, on: variable)!
            }
            
            return (clause, derivation)
        }

        public var description: String {
            return """
                ImplicationGraph{
                    nodes: \(nodes),
                    edges: [
                        \(edges.map{ String(describing: $0) }.joined(separator: ",\n        "))],
                    conflicts: \(conflicts) }
                """
        }
    }

    /// Track the sources of a (conflict) clause derivation.
    public typealias ClauseDerivation = [(Clause, Clause, Variable)]
    
    /// An arbitrary intermediate state of the solver algorithm.
    public enum IntermediateState {
        /// An assignment of all trivial units.
    case trivialUnitPropagation([Variable: Bool])
        /// An individual decision which was made.
    case decision(Decision)
        /// A clause was learned as a result of a conflict.
    case learned(Clause, from: ImplicationGraph)
    }

    public enum IntermediateOrResult {
    case intermediate(IntermediateState)
    case result(Assignment?)
    }
    
    public var iterations = 0
    
    public init() {}

    public func solveWithIntermediateStates(formula: Formula) -> AnySequence<IntermediateOrResult> {
        // The unsatisfiable formula is a special case.
        if formula == Formula.unsatisfiable {
            return AnySequence([.result(nil)])
        }

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

        // If the decision stack is empty, then we must look for any trivial
        // (single clause) units (which are not handled as part of CDCL's normal
        // unit propagation phase).
        //
        // FIXME: Given how backtracking works, we re-discover all of the units
        // every time we discover a new unit clause (since we will bactrack to
        // decision level 0). We could theoretically work a little harder to be
        // smarter during backtracking to avoid this redundant work.
        if decisions.isEmpty {
            // Collect the trivial units.
            for clause in formula.clauses + learnedClauses where clause.terms.count == 1 {
                let term = clause.terms[0]
                let decisionLevel = decisions.count
                let variable = term.variable
                let value = term.positive
                let next = propagateUnits(binding: variable, to: value, at: decisionLevel, on: implications, cause: clause)

                // If we found a conflict at this point, the formula is unsatisfiable.
                if next.isInConflict {
                    return nil
                }

                // Record the decision and update the context.
                self.decisions.append(
                    CDCLSolver.Decision(level: decisionLevel, variable: variable, value: value, implications: next))
            }

            // Report the trivial unit assignments.
            if let decision = decisions.last {
                // FIXME: NOTE: We can only return one decision, so we return
                // the aggregation of all units being applied.
                return .decision(decision)
            }
        }
        
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
        //
        // NOTE: We are allowed to always choose true here, because at this
        // point we know there are no trivial units.
        let decisionLevel = decisions.count
        let next = propagateUnits(binding: selected, to: true, at: decisionLevel, on: implications)

        // If we found a conflict, resolve it.
        if next.isInConflict {
            // Derive a conflict clause.
            let (clause, derivation) = next.analyzeConflict()

            // Learn the clause.
            learnedClauses.append(clause)
            learnedClauseDerivations.append(derivation)

            // Find the second highest decision level assigned in this clause,
            // then backtrack above that (i.e. backtrack to a point where we can
            // reconsider the impact of that choice in light of this new
            // clause).
            let backtrackLevel = clause.terms.compactMap{ term -> Int? in
                let node = next.nodes.first(where: { $0.variable == term.variable })!
                return node.decisionLevel != decisions.count ? node.decisionLevel : nil }.max() ?? 0
            self.decisions = Array(self.decisions[0 ..< backtrackLevel])
            
            return .learned(clause, from: next)
        }
        
        // Record the decision and update the context.
        let decision = CDCLSolver.Decision(
            level: decisionLevel,
            variable: selected, value: true,
            implications: next)
        self.decisions.append(decision)

        return .decision(decision)
    }

    /// Perform unit propagation after a new assignment.
    ///
    /// - Returns: The new implication graph, if the assignment is consistent.
    func propagateUnits(
        binding variable: Variable, to value: Bool, at decisionLevel: Int,
        on implications: CDCLSolver.ImplicationGraph,
        cause: Clause? = nil
    ) -> CDCLSolver.ImplicationGraph
    {
        // Get the current assignment.
        guard let assignment = implications.currentAssignment else {
            // If the graph is in conflict, stop propagation.
            //
            // FIXME: Is it ever worth continuing propagation? It seems like
            // there might be value in potentially deriving multiple learned
            // clauses in this case.
            return implications
        }
        var implications = implications

        // First, add the new binding to the graph.
        guard implications.bind(variable, to: value, decisionLevel: decisionLevel, cause: cause) else {
            // If the variable was already bound, we are done.
            return implications
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
            if unassignedVariables.count == 2 {
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
            }
        }

        // Apply the new units.
        for (otherVariable, otherValue, cause) in newUnits {
            // Add to the implication graph.
            implications = propagateUnits(binding: otherVariable, to: otherValue, at: decisionLevel,
                on: implications, cause: cause)
        }

        return implications
    }
}
