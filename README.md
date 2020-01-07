# Lathe Morphisms for Racket

[![Travis build](https://travis-ci.org/lathe/lathe-morphisms-for-racket.svg?branch=master)](https://travis-ci.org/lathe/lathe-morphisms-for-racket)

Lathe Morphisms for Racket isn't much yet, but it's going to be a library centering around category theory and foundational mathematics. We recognize not everyone is going to *want* to wade through specialized mathematical terminology, so as we design and document Lathe Morphisms, we hope to first consider the needs of those people who have little choice.

This goal of writing a category theory library for Racket can take many forms. Even within the field of category theory, it's common to investigate alternative ways of formalizing the basic concepts. Then when trying to represent category theory concepts in a programming language, it's possible to approach that task with varying degrees of fidelity to the matematical concepts. Finally, Racket is a programming language that embraces language extension and polyglot programming, and different ways of programming in Racket (especially different `#lang`s) may justify different API design approaches.

In Lathe Morphisms for Racket, we choose our naming conventions to make room for a number of different approaches all at once. In particular, to use a contrived example, the naming convention for our modules is broken up like this:

```
lathe-morphisms  /no-contracts  /ana  /no-choice  /mediary  /for-fp  /adjunction
```

In this example, `/no-contracts` specifies the style of Racket programming that influences the API design, `/ana` specifies that we're approaching category theory in a way that makes use of anafunctors, `/no-choce` specifies how our concept of category theory is using a metatheory that differs from the usual ZFC-style metatheory, `/mediary` specifies a more exotic kind of modification to the way we're approaching category theory, and `/for-fp` specifies how we're specializing the more generalized abstractions to make them convenient for a specific purpose. Finally, `/adjunction` is the name of the category theory concept being modeled.

This is a quite a number of moving parts, and we risk a bit of a combinatorial explosion in the API! Fortunately, not every combination of choices will be in much demand, and not all the moving parts are fully independent of each other. For instance, the `/for-fp` specialization, which specializes our notion of category theory to the situation where the only category of interest is the category of contracts and procedures between them, will tend to appear only in conjunction with the `/in-fp` metatheory, which models the stuff, structure, and properties of each algebraic theory by using contracts, procedures, and trivial values respectively.

Each of these moving parts also has a default setting, letting us write a module path as simple as `lathe-morphisms/adjunction` or `lathe-morphisms/in-fp/adjunction`. In particular, when every moving parts is at its default setting and the names are as short as `lathe-morphisms/adjunction`, Lathe Morphisms stays as close to the mathematical category theory literature as possible. We hope this will help users find their way between the concepts Lathe Morphisms offers and the concepts they may learn about in various category theory learning materials.

* By default, the API style we use is that of a Racket library with contracts that are detailed enough to be informative, with very little use of `any/c`.

* By default, we do not use anafunctors, mainly because there doesn't seem to be any well-established terminology for discussing the "non-ana-" style of category theory from an ana-by-default viewpoint.

* By default, we use a classical metatheory where the axiom of choice holds.

* By default, we do not modify the metatheory in any particularly exotic way.

* By default, we do not specialize our notion of category theory to any particular domain-specific context.

At present, Lathe Morphisms is not fleshed out very far. It only supports a few combinations of choices, and none of them take place in a classical metatheory.

* The `lathe-morphisms/in-fp` collection represents a style of category theory that uses a constructive metatheory. In this approach, an algebraic theory's stuff, structure, and properties are represented a particular way: The stuff (e.g. a category's set of objects and sets of morphisms between objects) is represented by Racket contracts, the structure (e.g. its identity and composition operations) is represented by Racket procedures, and the properties (e.g. its unit and associativity laws) are represented only as informal recommendations. This will likely serve as a building block for the other approaches as needed.

* The `lathe-morphisms/in-fp/mediary` collection represents a style of category theory where the metatheory is similar to the constructive metatheory of `lathe-morphisms/in-fp`, but with an exotic modification: Each of its algebraic theories is tailored for open extensibility. Our concept of a "mediary" algebraic theory is one where certain laws only hold for "well-behaved" elements. Using mediary theories, one library can define a model of a mediary theory, another library developed independently can define a well-behaved element, and then a user who discovers both libraries can use them together. We use this approach primarily to justify a notion of "well-behaved set element" that can say some things about its own equality without predetermining what set it actually belongs to.


## Future directions for expanding the library

In terms of Racket programming styles, the primary alternative style we're considering is `/no-contracts`, a style where programs use no perform error-checking without the aid of Racket's contract system, perhaps using a more Scheme-like error discipline. There may also be an alternative style where we make use of static bindings to propagate some information, not unlike the way Racket carries static information on the bindings associated with unit signatures and structure types. And of course, we may have different styles to cater to different `#lang` languages.

In terms of approaches we can take to the metatheory of category theory, a few of them form a pretty clear succession of options, each weaker than the last:

* The default: A classical metatheory with the axiom of choice.

* `/no-choice`: A classical metatheory without the axiom of choice.

* `/in-fp-with-proofs`: A constructive metatheory where we use Racket procedures to represent both set-theoretic functions (such as the function to compose a morphism `f : A -> B` and a morphism `g : B -> C` to obtain a morphism `g o f : A -> C`) and logical implications (like the implication to compose a proof witness of `A = B` and a proof witness of `B = C` to obtain a proof witness of `A = C`). This kind of metathoery tends not to support the axiom of choice or the principle of excluded middle.

* `/in-fp`: A constructive metatheory where we use Racket procedures to represent set-theoretic functions, but logical laws and proofs are purely in the domain of documentation and don't have any representation in the program.

If we take a simplistic approach, we lose the functor comprehension principle in the `/no-choice` tier, and we lose the function comprehension principle in the `/in-fp-with-proofs` tier. These principles are assumed by many hallmark results and constructions of category theory, and a common approach to regaining the functor comprehension principle is to use anafunctors. So every tier which needs it may have a corresponding `/ana` tier, e.g. `/ana/no-choice`, where we model functors as anafunctors and functions as anafunctions wherever necessary so that we can regain the comphrehension principles.

In terms of exotic modifications to the metatheory, we have a few ideas. A few of them are motivated in part by the temptation to apply category theory to concepts that exist in Racket's contract system:

* The default: No modification.

* `/mediary`: Here we model what we call "mediary" algebraic theories, in which only "well-behaved" elements have things like reflexive cells and unit laws, and the mediary theory itself focuses on operations that involve more than one element. "A Local System for Linear Logic" describes this kind of proof system for a classical linear logic, but we're extrapolating this concept to category theory. We do this primarily for the purpose of having at least some notion of "well-behaved set element" (`atomic-set-element-sys?`) that we can use in our contract to check that multiple inputs have made decisions that are *similar enough* (`ok/c`) to a certain decision we consider canonical.

* `/internal`: Here we would model the concepts of category theory in a way that's internal to some specified category (using a notion of "category" is appropriate to the metatheory being modified). The theory of internal categories is well established, so calling it "exotic" might be a bit of an exaggeration.

* Some algebraic theories are *decidable*, like decidable equivalence relations and decidable partial orders. Essentially, these theories can exhibit example proof witnesses. It may be interesting to consider algebraic theories that can exhibit other kinds of cell inhabitants as well, such as sets that can exhibit example elements, not unlike Racket's `contract-random-generate`.

* Some algebraic theories may have only *partial* operations. Mediary theories may be good for open definitions, but partial theories may serve that purpose in an even more expressive way, by allowing a theory to be built up as an aggregation of partial information. If we follow this path far enough that we allow individual elements to bring along their own extensions to the theory they belong to, we might arrive at a generalized discipline which can guide the design of overloadable operators like `equal?` and `contract-stronger?`.

Finally, in terms of specializations, we only have two in mind so far:

* The default: No specialization.

* `/for-fp`: Wherever a concept would be parameterized over the user's choice of category, instead we assume the user wants just one category in particular: The category of Racket procedure composition. For instance, the combination of the `/in-fp` metatheory with the `/for-fp` specialization makes concepts like "functor" and "monad" correspond with the meanings they usually have in functional programming.


## An untyped category theory library

Something that might make Lathe Morphisms for Racket stand out a little compared to other category theory libraries is that it's not primarily a library for a typed language, but a library for Racket, which conventionally enforces its interfaces using contracts. There are situations in a typed language like Haskell where we might use a type or constraint which contains a duplicated variable like `(HasProducts cat, HasPullbacks cat)` to enforce that our `HasProducts` and `HasPullbacks` constructions are based on the same category `cat`. In Lathe Morphisms, we'll have to explicitly verify at run time that the two occurrences of `cat` are compatible (a purpose for which we use `ok/c`). For performance, some users might decide to skip checks like these. With that in mind, we design our interfaces to use the user's choice of contracts, and the user can make use of that to specify pretty strict contracts, but the contract `any/c` is a legitimate choice as well.

Even without having types itself, Lathe Morphisms may turn out to be handy for implementing compile-time systems like typechecked DSLs.


## Some more words on our constructive approach to classical reasoning

One of the most subtle mismatches between general category theory and the kind of category theory used in functional programming is the difference between classical and constructive mathematics. There's a constructive flavor to most of category theory,[1] particularly when the category axioms are interpeted "internally" as properties of the objects and morphisms of another category (often a topos). As long as this constructive flavor holds up, the correspondence between category theory and functional programming can go very far. Nevertheless, mathematicians tend to expect things to be defined in terms of a classical set theory with the axiom of choice, and category theory is often described primarily in terms of that foundation. In general there are a few nonconstructive definitions and proofs of category theory that are only revisited to make them constructive whenever the need arises, but are usually discussed in classical terms.

One common way of revisiting the definitions is to use anafunctors in place of functors. This way, a fully faithful and essentially surjective functor can have its inverse taken (thereby making it a useful representation of an *equivalence of categories*) without resorting to the axiom of choice. This works because an anafunctor makes a little bit more of its representation explicit, and it makes a little bit less of its behavior constructive, so the process of constructing the inverse can make use of more materials to do less work.

In Lathe Morphisms, we're going to do something similar but with a bigger bundle of extra materials: We'll represent a category in a way that is explicitly associated with a classical set theory derivation system. This derivation system will let us use a constructive functional programming style to build proofs that are nonconstructive. And since we have nonconstructive proofs (at some level), the way we think of categories can be largely accurate to the way they're thought of in classical mathematics.

This wouldn't be nearly the first time a language or library for developing mathematical theorems had used constructive mathematics as a basis for studying classical mathematics. We will likely be visiting several well-trodden techniques in service of that goal, such as apartness relations and the aforementioned anafunctors.

[1]: There's an analysis of several possible reasons why category theory is so constructive in "[https://pdfs.semanticscholar.org/501f/93c37f777f0171e541912c960022cad07624.pdf](Two Constructivist Aspects of Category Theory)," Colin McLarty 2006.


## Installation and use

This is a library for Racket. To install it, run `raco pkg install --deps search-auto` from the `lathe-morphisms-lib/` directory, and then put an import like `(require lathe-morphisms)` in your Racket program.

The interface to Lathe Morphisms will eventually be documented in the `lathe-morphisms-doc/` package's documentation.
