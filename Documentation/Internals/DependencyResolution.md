# Swift Package Manager Dependency Resolution

## Introduction

This document describes the dependency resolution approach taken by the Swift
package manager.

Dependency resolution is the process by which the package manager resolves a
concrete set of packages and versions to use when operating on a package
(building, updating, etc.).

The dependency resolution problem is intrinsically hard because the dependencies
of each package are only known at a specific version. Informally it is easy to
think about the package as being the repository, but it is more accurate to
think of the repository as a collection of many different packages at different
versions, and each of those packages has dependencies. Unfortunately, this
feature makes the dependency resolution problem
[NP-hard](https://en.wikipedia.org/wiki/NP-hardness).

This document discusses the current approach taken by the package manager to
deal with the hardness of this problem.

## Background

* Scale
* Diagnostics

## References

Our implementation of the dependency resolution logic is in
[`DependencyResolver.swift`](../../Sources/PackageGraph/DependencyResolver.swift).

`Aptitude` uses a custom solver for the full NP-complete problem. This approach
is documented in
[Modelling and Resolving Software Dependencies](https://people.debian.org/~dburrows/model.pdf).

The `pip` package manager for `Python` has an open issue (since 2013) on
implementing a more proper dependency resolver in
[Issue #988](https://github.com/pypa/pip/issues/988).

[`libzypp`](https://en.wikipedia.org/wiki/ZYpp) is a package management engine
used by Linux system package managers, and uses a SAT-based resolution strategy
using [MiniSat](http://minisat.se). The solver engine itself is
[`libsolv`](https://github.com/openSUSE/libsolv).

[`Pub`](https://www.dartlang.org/tools/pub) is the package manager for the
[Dart](https://www.dartlang.org) programming language, and has a good discussion
of [versioning](https://www.dartlang.org/tools/pub/versioning) issues. The
package manager itself appears to directly implement an unbounded backtracking
solver.

The [`Meteor`](https://en.wikipedia.org/wiki/Meteor_(web_framework)) JavaScript
framework uses a SAT-based approach using an `Emscripten`-compiled version of
MiniSat, as part of their
[logic-solver](https://github.com/meteor/meteor/tree/devel/packages/logic-solver)
library.
