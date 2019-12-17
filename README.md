# Lathe Morphisms for Racket

[![Travis build](https://travis-ci.org/lathe/lathe-morphisms-for-racket.svg?branch=master)](https://travis-ci.org/lathe/lathe-morphisms-for-racket)

Lathe Morphisms for Racket isn't much yet, but it's going to be a library centering around category theory and foundational mathematics.

Many functional languages use abstractions named after category theory concepts. Unfortunately, since the instances of those concepts are internal to a specific kind of category, the other features of that category give them a slightly different feel than they have in the rest of category theory. This leads to some surprises when moving between learning materials, which can test programmers' patience as they try to make their way through a pile of unfamiliar terminology.

There are many category theory libraries in the world, and Lathe Morphisms aims to be yet another one. One of our priorities will be to model these concepts in a way that more explicitly describes how slippery the definitions are, both by making our abstractions general enough that the user can configure them to their preferred context and by writing our documentation in a way that clarifies the sometimes unintuitive relationships between the functional programming and classical mathematics ideas.

We recognize that not all programmers are going to *want* to wade through specialized mathematical terminology, so Lathe Morphisms isn't for everyone. However, category theory is rather unreasonably effective, and sometimes it'll be the easiest option available. We hope that for the programmers who do need category theory, Lathe Morphisms can help make the concepts easier to grasp.


## An untyped category theory library

Something that might make Lathe Morphisms for Racket stand out a little is that it's not a library for a typed language, but a library for Racket, which conventionally enforces its interfaces using contracts. There are situations in a typed language like Haskell where we might use a type or constraint which contains a duplicated variable like `(HasProducts cat, HasPullbacks cat)` to enforce that our `HasProducts` and `HasPullbacks` constructions are based on the same category `cat`. In Lathe Morphisms, we'll have to explicitly verify at run time that the two occurrences of `cat` are compatible. For performance, some users might decide to skip checks like these.

Nevertheless, it may turn out that Lathe Morphisms is handy for implementing things like typechecked DLSs. So it's not merely that Lathe Morphisms is less verified than other libraries; it just takes a different attitude to approach the topic of verification.


## A constructive approach to classical reasoning

One of the most subtle mismatches between general category theory and the kind of category theory used in functional programming is the difference between classical and constructive mathematics. There's a constructive flavor to most of category theory,[1] particularly when the category axioms are interpeted "internally" as properties of the objects and morphisms of another category (often a topos). As long as this constructive flavor holds up, the correspondence between category theory and functional programming can go very far. Nevertheless, mathematicians tends to expect things to be defined in terms of a classical set theory with the axiom of choice, and category theory is often described primarily in terms of that foundation. In general there are a few nonconstructive definitions and proofs of category theory that are only revisited to make them constructive whenever the need arises, but are usually discussed in classical terms.

One common way of revisiting the definitions is to use anafunctors in place of functors. This way, a fully faithful and essentially surjective functor can have its inverse taken (thereby making it a useful representation of an *equivalence of categories*) without resorting to the axiom of choice. This works because an anafunctor makes a little bit more of its representation explicit, and it makes a little bit less of its behavior constructive, so the process of constructing the inverse can make use of more materials to do less work.

In Lathe Morphisms, we're going to do something similar but with a bigger bundle of extra materials: We'll represent a category in a way that is explicitly associated with a classical set theory derivation system. This derivation system will let us use a constructive functional programming style to build proofs that are nonconstructive. And since we have nonconstructive proofs (at some level), the way we think of categories can be largely accurate to the way they're thought of in classical mathematics.

This wouldn't be nearly the first time a language or library for developing mathematical theorems had used constructive mathematics as a basis for studying classical mathematics. We will likely be visiting several well-trodden techniques in service of that goal, such as apartness relations and the aforementioned anafunctors.

[1]: There's an analysis of several possible reasons why category theory is so constructive in "[https://pdfs.semanticscholar.org/501f/93c37f777f0171e541912c960022cad07624.pdf](Two Constructivist Aspects of Category Theory)," Colin McLarty 2006.


## Specialized sublibraries

Despite the overall mission of Lathe Morphisms to act as a clarifying middle ground between the functional programming and classical mathematics worlds of category theory, not everything people build is going to need to generalize to both worlds.

For contexts where informal category theory reasoning is helpful but formally explicit reasoning is too much work for too little benefit (e.g. because Racket isn't typechecked anyway), the classical derivation system can be one that's trivial and inconsistent, where the so-called proofs are written without any information content at all.

In many contexts, the specific category of Racket function composition is the only category we need. When we specialize our definitions to that category, we will tend to end up with definitions that line up with Haskell terminology like `Functor` and `Monad`.

For convenience, we might provide these specialized operations with names that conflate them with the more general terminology. Unfortunately, this poses the same potential for confusion that we're making Lathe Morphism to avoid.

In a way, the closer we get to calling Lathe Morphisms a library for *foundational* mathematics, the less we can do about this. All mathematical argumentation happens relative to some unspecified foundational metatheory, and audiences have to instantiate that with whatever metatheory helps them make sense of the argument.

Our approach will be to embrace these multiple meanings of category theory concepts but at the same time try to situate them relative to each other in formally precise ways that help people navigate between the perspectives. For instance, we will strive to ensure the design of the sublibraries continues to have analogues in the more generalized approach, and we'll arrange that the module names and documentation clearly state the way that these sublibraries are specialized.


## Generalized sublibraries

It may be interesting to explore various ways of generalizing category theory itself, especially higher-dimensional category theory. However, there are at least a few different ways of approaching higher-dimensional category theory, not to mention other possible foundational approaches like type theory, set theory, topology, etc.

We will likely consider the ground level to be 0-, 1-, 2-, and maybe 3-dimensional category theory. When we want to regard these as specializations, we'll make a sublibrary that becomes the home base of that foundational approach. As far as that sublibrary is concerned, the ground-level library is its specialized sublibrary.


## Installation and use

This is a library for Racket. To install it, run `raco pkg install --deps search-auto` from the `lathe-morphisms-lib/` directory, and then put an import like `(require lathe-morphisms)` in your Racket program.

The interface to Lathe Morphisms will eventually be documented in the `lathe-morphisms-doc/` package's documentation.
