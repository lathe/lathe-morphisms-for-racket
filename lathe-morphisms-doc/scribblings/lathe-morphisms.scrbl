#lang parendown scribble/manual

@; lathe-morphisms/scribblings/lathe-morphisms.scrbl
@;
@; Evergreen utilities.

@;   Copyright 2018 The Lathe Authors
@;
@;   Licensed under the Apache License, Version 2.0 (the "License");
@;   you may not use this file except in compliance with the License.
@;   You may obtain a copy of the License at
@;
@;       http://www.apache.org/licenses/LICENSE-2.0
@;
@;   Unless required by applicable law or agreed to in writing,
@;   software distributed under the License is distributed on an
@;   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
@;   either express or implied. See the License for the specific
@;   language governing permissions and limitations under the License.


@title{Lathe Morphisms}

Lathe Morphisms for Racket

Lathe Morphisms for Racket is a library providing interfaces and constructions of abstract algebraic concepts. Programming languages themselves have rich algebraic properties, so algebras can be handy for building DSLs or for discovering convenient minimalistic interfaces.

There's a particular way algebraic, and especially category-theoretic, terminology is typically applied in a programming language context. Function composition satisfies identity laws like @racket[(lambda (x) ((lambda (x) x) (my-func x)))] = @racket[(lambda (x) (my-func x))], almost satisfying the laws of a monoid, except that some function inputs and outputs are type-incompatible with each other. Once we account for types, the algebraic laws for function composition are a category: Types are the objects of the category, and functions are the morphisms.

In category-theoretic semantics of programming languages, a language is usually identified with its syntactic category. The objects of this category are contexts (the collection of variables in scope), and the morphisms usually correspond to expressions. Notice an expression can be used together with @racket[let] or function application in order to bring another variable binding into scope, so they're an esseential ingredient in building one context out of another.

Languages with the kind of first-class functions and lexical scope that Racket has don't have just any kind of syntactic category: They're Cartesian closed categories, which means they have first-class functions (aka an internal hom, making them "closed") and first-class tuples (aka finite products, making them "Cartesian") which are well-behaved together in a specific way (basically, the ability to do currying). Among the advantages of a Cartesian closed category is the fact that it can be considered to be enriched in itself. That is, an expression over a context can be represented using a function which receives a tuple, and function encapsulation happens to ensure that every program which transforms functions of this type family must respect the laws of the type family's own Cartesian closed category structure. Since they're ordinary functions, the Cartesian closed category structure of this type family is compatible with that of the language at large, and the language has the ability to recreate quite a bit of the algebraic study performed on it.

If you've heard category-theoretical terminology in relation to programming before, you've probably heard of Haskell. Haskell's "functors" and "monads" are specifically the internalized functors and monads of this self-enrichment (or at least the ones that abide by Haskell's @tt{Functor} laws and @tt{Monad} laws are). That is to say, they don't quite capture the generality of what "functors" and "monads" can mean in category theory, but they do capture what these notions instantiate to when specifically discussing Haskell's self-enriched syntactic category. This leads to a few quirks, like the fact that Haskell @tt{Functor}s always have tensorial strength over Haskell's product type (as in, you can smuggle an external value into the functor using a function closure), so the notions of "strong functor" would be redundant in Haskell, and Haskell programmers can instantiate the @tt{Monad} interface by defining "monadic bind," which is a concept that in category theory is only well-defined for @em{strong monads},

For brevity in the Lathe Morphisms library, we follow the spirit of Haskell's naming convention to an extent, where category-theoretic terminology are used specifically in relation to the self-enriched structure of the syntactic category. However, we do this (TODO: We haven't done this quite yet!) under the @tt{lathe-morphisms/as-procedures} collection so that we have room to develop other incarnations of these general concepts. For instance, we may develop a @tt{lathe-morphisms/as-values} collection of tools that are relevant to internal categories (like the ones instantiating Haskell's @tt{Category} type class), a @tt{lathe-morphisms/between-morphisms} collection of higher category theory concepts, or a @tt{lathe-morphisms/in-typed-racket/as-functions} collection of tools specialized for the self-enriched structure of the Typed Racket language's syntactic category. Racket is a platform with many interacting languages, and this naming conventiion can let the Lathe Morphisms package be useful for more than one of them.

Note that in general, it is difficult to apply category-theoretical concepts in their full generality in a programming language, not only because every Peano-arithmetic-capable language has some limit to its proof-theoretic power, but because the mathematical intuitions at play for category theorists often involve classical set-theoretic reasoning with excluded middle and the axiom of choice, which aren't nearly such common intuitions in the context of constructive type thoery. (Category theory is not characterized by one canonical formal system, but merely as the study of categories. Hence, intuition plays a big role in what someone chooses for "category" to mean in their work, and there are a variety of formalisms they can refer to to make their work rigorous.) We might get a long way toward generality using an approach involving anafunctors, but this may or may not be a very ergonomic interface for everyday programming, so more specialized vocabularies like @tt{lathe-morphisms/as-functions} will continue to come in handy after the generalizations are available.



@table-of-contents[]



(TODO: Write this documentation. We'll need at least one export in the library before we have anything to document.)
