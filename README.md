# Lathe Morphisms for Racket

[![Travis build](https://travis-ci.org/lathe/lathe-morphisms-for-racket.svg?branch=master)](https://travis-ci.org/lathe/lathe-morphisms-for-racket)

Lathe Morphisms for Racket is a library providing interfaces for and constructions of concepts in foundational mathematics, espcially category theory. Programming languages themselves have rich connections to these systems. It's often possible to express a subsystem of a program as a mathematical concept and then manipulate it in a way that easily generalizes to any other instance of that concept. Pursuing this kind of mathematical expression of a program ahead of time can be a good way to design DSLs and API surfaces with good properties that help their designs remain stable as the program takes on new requirements.


## Installation and use

This is a library for Racket. To install it, run `raco pkg install --deps search-auto` from the `lathe-morphisms-lib/` directory, and then put an import like `(require lathe-morphisms)` in your Racket program.

The interface to Lathe Morphisms will eventually be documented in the `lathe-morphisms-doc/` package's documentation.
