# Lathe Morphisms for Racket

[![Travis build](https://travis-ci.org/lathe/lathe-morphisms-for-racket.svg?branch=master)](https://travis-ci.org/lathe/lathe-morphisms-for-racket)

Lathe Morphisms for Racket isn't much yet, but it's going to be a library centering around category theory and foundational mathematics.

Many functional languages use abstractions named after category theory concepts. Unfortunately, since the instances of those concepts are internal to a specific kind of category, the other features of that category give them a slightly different feel than they have in the rest of category theory. This leads to some surprises when moving between learning materials, which tests programmers' patience as they try to make their way through a pile of unfamiliar terminology.

Lathe Morphisms aims to model these concepts in their full generality, so that they line up nicely with the more mathematically oriented learning resources and thereby become (even a little bit) more accessible. We recognize that not all programmers are going to *want* to wade through specialized mathematical terminology, so we're tailoring Lathe Morphisms specifically for the programmers who find they have no choice.

One of the biggest mismatches between general category theory and the kind of category theory used in functional programming is the difference between classical and constructive mathematics. Category theory literature typically takes for granted the law of excluded middle and the axiom of choice, which don't exist in the usual functional programming setting.

Another difference is that functional programming's use of category theory tends to be internal to a Cartesian closed category, and this means functors have tensorial strengths autmatically. In practical terms, this means functional programmers may be accustomed to smuggling arbitrary first-class values into a `map` operation's body by using a function closure, but that technique won't work in just any category, and they won't always realize that at first.

In Lathe Morphisms, we intend to ameliorate these differences by being specific about which categories and which classical logic derivation systems we're using. The usual analogues of Haskell's `Functor` or `Monad` utilities will (just as in Haskell) be specific to

* the trivial classical logic derivation system where validity is not enforced at all and the derivations have no information content either

* a particular category of function composition, where the category laws are expressed using that trivial derivation system

but we also intend to support functors and monads which encode other choices than these.

We don't think of this as anything new. Languages and libraries for developing mathematical theorems have often started with constructive mathematics and studied classical mathematics on top of that. We will likely be visiting several well-trodden techniques in service of that goal, such as apartness relations and anafunctors.

What might make Lathe Morphisms for Racket stand out a little is that it's not a library for a typed language, but a library for Racket, which conventionally enforces its interfaces using contracts. In a typed language like Haskell, we might use a type or constraint which contains a duplicated variable like `(HasProducts cat, HasPullbacks cat)` to enforce that our `HasProducts` and `HasPullbacks` constructions are based on the same category `cat`. In Lathe Morphisms, we're going to try to enforce that kind of thing at run time in cooperation with Racket's contract system. In some cases, we might decide not to bother enforcing it at all.

In a way, Lathe Morphisms is a catch-all utility library specialized to utilities that may be easiest to understand in the context of the literature of category theory or foundational mathematics. By expressing each concept with the same amount of generality it has in that literature, rather than specializing it to a particular programming task, we hope to make it easier to transfer knowledge back and forth.


## Installation and use

This is a library for Racket. To install it, run `raco pkg install --deps search-auto` from the `lathe-morphisms-lib/` directory, and then put an import like `(require lathe-morphisms)` in your Racket program.

The interface to Lathe Morphisms will eventually be documented in the `lathe-morphisms-doc/` package's documentation.
