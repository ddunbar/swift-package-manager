// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for Swift project authors

public extension Set {
    public var powerSet: [Set<Element>] {
        // If the set is empty, we are done.
        if isEmpty {
            return [Set()]
        }

        // Otherwise, take an element and return the power set with and without it.
        var set = self
        let item = set.removeFirst()
        let nextSet = set.powerSet
        return nextSet + nextSet.map{ set in
            var set = set
            set.insert(item)
            return set
        }
    }
}
