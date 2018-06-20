# SAT

An experimental SAT solver, for potential use in dependency resolution.

## TODO

* [x] Basic description language for boolean SAT.
* [ ] (Optional) Support loading SAT instances?
* [x] Brute forcer solver for boolean SAT
* [x] Basic DPLL solver for boolean SAT.
* [ ] Add constraint dependency graph (+ viz?).
* [ ] Add support for CDCL.
* [ ] Switch to package version SAT model.
* [ ] Add support for dynamic formula exploration.
* [ ] Add rich diagnostics on failures.
* [ ] (Optional) Investigate forgetting support.
* [ ] (Optional) Investigate conflict clause minimization.
* [ ] (Optional) Investigate restart support.
* [ ] (Optional) Investigate parallel solving.
* [ ] (Optional) Investigate incremental solving.

## References

* @nex3's "PubGrub" writeups
  * Medium post: https://medium.com/@nex3/pubgrub-2fb6470504f
  * https://github.com/dart-lang/pub/blob/master/doc/solver.md
* Knuth's "SAT13" CDCL Implementation: https://www-cs-faculty.stanford.edu/~knuth/programs/sat13.w
* Glucose: A modern CDCL solver used as the basis of many other experiments: http://www.labri.fr/perso/lsimon/glucose/
* CaDiCaL: A fast modern SAT solver which has placed well in competition: https://github.com/arminbiere/cadical
  * A succinct description of the techniques used is in http://fmv.jku.at/papers/Biere-SAT-Competition-2017-solvers.pdf
  * http://fmv.jku.at/papers/BiereFroehlich-SAT15.pdf
  * Uses VFMT heuristic from Siege: http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.68.2512&rep=rep1&type=pdf
* SaTELite: A CNF preprocessor, used with MiniSAT and embedded in others: http://minisat.se/SatELite.html
* Phase Saving: reasoning.cs.ucla.edu/fetch.php?id=69&type=pdf
* PicoSAT Essentials: Description of optimizations used in PicoSAT: https://pdfs.semanticscholar.org/7ea4/cdd0003234f9e98ff5a080d9191c398e26c2.pdf
* Understanding and Using SAT Solvers: Presentation on various SAT solving techniques: http://resources.mpi-inf.mpg.de/departments/rg1/conferences/vtsa09/slides/leberre2.pdf
* Inprocessing Rules: https://arise.or.at/pubpdf/Inprocessing_Rules.pdf
* Lingeling Essentials: https://pdfs.semanticscholar.org/cab3/14776c750c9aa3303f9f90fe7a4152d6744b.pdf?_ga=2.105153415.500134522.1528399382-2141622216.1522385823
* The Effect of Restarts on the Efficiency of Clause Learning: http://users.cecs.anu.edu.au/~jinbo/07-ijcai-restarts.pdf
* A Lightweight Component Caching Scheme for Satisfiability Solvers: https://pdfs.semanticscholar.org/161a/4ba80d447f9f60fd1246e51b360ec78c13de.pdf?_ga=2.108766726.500134522.1528399382-2141622216.1522385823
* Predicting Learnt Clauses Quality in Modern SAT Solvers: https://www.ijcai.org/Proceedings/09/Papers/074.pdf
* Chaff: Engineering an Efficient SAT Solver: https://www.princeton.edu/~chaff/publication/DAC2001v56.pdf
* Conflict-Driven Clause Learning SAT Solvers (Chapter 4 of Handbook of Satisfiability): http://satassociation.org/articles/FAIA185-0131.pdf
