# Third-party Package Ecosystem Development

This document is a vision for what the Swift Package ecosystem should look like
with regards to the integration of "third-party" software.


## Overview

There is a large corpus of important third-party C libraries which developers
would like to be easily available in Swift. These libraries often form a common
base upona which it is important for higher level applications to live, either
because they constitute the bare operating system services (e.g., the POSIX or
Win32 APIs), or because they provide a well-understood stock component (e.g.,
Memcached or PostgreSQL) that the developer wishes to leverage.

On Apple platforms, many of these libraries are provided by the platform SDK and
thus their availability in Swift can be maintained and evolved by the Swift team
directly.

On other platforms, or for popular third-party libraries which are not shipped
by Apple, where there is not an established group with the ability to change the
third-party library directly, we need mechanisms in place by which these
libraries can be adapted to integrate into the Swift Package ecosystem.


## Goal

The goal is to support a rich, collaborative, and evolving ecosystem which can
build on the large corpus of high quality C libraries. In particular, we would
like:

* A consistent process for integrating a new library.
* Minimal duplication of effort in integrating software.
* Easy tracking of upstream development on the third-party library.
* Good support for solving standard integration problems to bridge a C API into
  Swift "well".


## Background

This problem area has historically been solved by Swift on Apple platforms
through the introduction of "overlays" -- additional code defined inside the
Swift project itself which implements or improves that API of another library.

### What is an overlay?

Technically, the overlay is defined as the Swift module with the same
name as a non-Swift module. There can only be one such module.

Overlays are required when the library defines functionality in macros or
functions which are not bridgable to Swift, and need to be replaced or shimmed
with additional C or Swift code. Common examples are replacing function-like
macros with inline functions and defining alternate implementations of varargs
functions.

Overlays are also useful when the naive imported Swift API is hard to use to
some degree. For example, a C struct containing a large fixed size array
importing as a tuple, or a function taking a block needing to be annotated with
`@noescape`. Another common example is exposing C enum types as native Swift
enums.

Overlays may also be useful as a way to ensure source portability for POSIX APIs
which are not portable when imported into Swift. For example, the `DIR` type as
imported by `Darwin.C` versus `Glibc` is incompatible at the Swift level.

### How are third-party libraries integrated into the ecosystem?

The Swift package manager currently supports two mechanisms by which third-party
libraries can be integrated into the ecosystem:

1. There are "system module" packages, which are intended to wrap a third-party
   library which has been installed on the host system using an external
   mechanism (e.g., `apt get` or `brew install`). These packages can define
   module maps, and will likely be enhanced to support full overlays including
   compiled code.

2. The package manager can directly build C family source code. This allows
   adapting existing third-party libraries so that they can be built directly by
   the package manager without any involvement from an external build system or
   packaging tool.


## Examples

Numerous examples of this paradigm exist even in the current early ecosystem,
the following are just a few cherry-picked ones:

* [OpenSSL](https://github.com/Zewo/OpenSSL)

  This is decomposed into a platform specific system module package
  ([Linux](https://github.com/Zewo/COpenSSL-OSX),
  [OS X](https://github.com/Zewo/COpenSSL)), and the wrapper.

  An example feature implemented in the overlay is a wrapper over a
  [C enum](https://github.com/Zewo/OpenSSL/blob/master/Sources/OpenSSL/Hash.swift).

* [HTTPParser](https://github.com/Zewo/HTTPParser)

  This is a fork of commonly used single-file C library for parsing HTTP
  headers. It is decomposed into a
  [C library package](https://github.com/Zewo/CHTTPParser) and the wrapper
  package.

* [PostgreSQL-Swift](https://github.com/stepanhruda/PostgreSQL-Swift)

  This is decomposed into a system module package for
  [libpq](https://github.com/stepanhruda/libpq).

  An example of a higher-level API here is a `StringLiteralConvertible` wrapper
  for a
  [SQL query string](https://github.com/stepanhruda/PostgreSQL-Swift/blob/master/Sources/Query.swift).

  Another wrapper for the same library is available at
  [SwiftPostgres](https://github.com/ljodal/SwiftPostgres), but which uses a
  different `libpq` system module package (actually one from the aforementioned
  `Zewo` project). Their wrapper for the same library is here
  [PostgreSQL](https://github.com/Zewo/PostgreSQL).

* [SwiftGtk](https://github.com/TomasLinhart/SwiftGtk)

  This is a wrapper for the GTK GUI library, again decomposed over two platform
  specific module map packages.

  An example of a "natural" translation into a Swift API is the
  [Button](https://github.com/TomasLinhart/SwiftGtk/blob/master/Sources/Button.swift)
  wrapper and its `label` property.

All of these are "simple" overlays in the sense that they do not redefine or
reimplement the underlying C API (the package manager doesn't support that). An
example where a slightly more complex overlay is useful is the Swift package
project itself, which defines a
[libc](https://github.com/apple/swift-package-manager/tree/master/Sources/libc)
module to paper over cross platform differences. **FIXME: Find more examples of
complex overlay code.**


## Overlay Guidelines

The technical requirements for overlays lead to several natural guidelines:

* The overlay should reexport any underlying API which it does not
  replace. Without this behavior, the underlying API would be completely
  inaccessible to any package graph containing this overlay.

* The overlay should expose the API with full fidelity, for the same reason. An
  overlay may be *incomplete*, but it should not redefine API in such a way that
  certain features of the library are not implementable.

* The overlay should only implement the minimal functionality necessary to
  bridge the library to Swift "well".

  Since there can only be one such module, it is very problematic for the
  ecosystem if critical libraries have multiple overlay modules defined, since
  any particular package graph would only be able to use dependencies which,
  transitively, include the same overlay.

  Thus, high-level wrappers which define API which cannot meet the previous
  requirements should generally be exposed through additional packages, so that
  multiple such wrappers can coexist.
