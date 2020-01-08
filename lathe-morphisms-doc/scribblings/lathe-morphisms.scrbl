#lang parendown scribble/manual

@; lathe-morphisms/scribblings/lathe-morphisms.scrbl
@;
@; Interfaces for category theory concepts.

@;   Copyright 2019 The Lathe Authors
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


@(require #/for-label racket/base)
@(require #/for-label #/only-in racket/contract
  struct-type-property/c)
@(require #/for-label #/only-in racket/contract/base
  -> ->i any/c contract? flat-contract?)

@(require #/for-label #/only-in lathe-comforts/contract
  flat-contract-accepting/c)
@(require #/for-label #/only-in lathe-comforts/match match/c)

@(require #/for-label lathe-morphisms/in-fp/category)
@(require #/for-label lathe-morphisms/in-fp/mediary/set)
@(require #/for-label lathe-morphisms/in-fp/set)

@(require #/only-in scribble/decode part-start)

@(require #/only-in lathe-comforts dissect)


@(define (sub ps)
  (dissect ps (part-start depth tag-prefix tags style title)
  #/part-start (add1 depth) tag-prefix tags style title))

@(define-syntax-rule (subsubsubsection args ...)
  (sub #/subsubsection args ...))


@title{Lathe Morphisms}

Lathe Morphisms for Racket isn't much yet, but it's going to be a library centering around category theory and foundational mathematics. We recognize not everyone is going to @emph{want} to wade through specialized mathematical terminology, so as we design and document Lathe Morphisms, we hope to first consider the needs of those people who have little choice.

This goal of writing a category theory library for Racket can take many forms. Even within the field of category theory, it's common to investigate alternative ways of formalizing the basic concepts. Then when trying to represent category theory concepts in a programming language, it's possible to approach that task with varying degrees of fidelity to the matematical concepts. Finally, Racket is a programming language that embraces language extension and polyglot programming, and different ways of programming in Racket (especially different @tt{#lang}s) may justify different API design approaches.

In Lathe Morphisms for Racket, we choose our naming conventions to make room for a number of different approaches all at once. In particular, we're making room for approaches that have support for a form of classical reasoning, even though for now we just have a couple of approaches based on a constructive form of category theory without proof witnesses.

Throughout this library, we sometimes need to ensure that more than one value passed to a function are all @deftech{close enough} together. For functions like these, we consider one of the values @racket[_v] to be the source of truth, and we check that the others are @racket[(ok/c _v)]. This calls the value's @racket[atomic-set-element-sys-accepts/c] method if it has one, and otherwise it just uses @racket[any/c].

At its strictest, the implementation of a value's @tt{...-accepts/c} method will tend to use @racket[match/c] around some recursive calls to @racket[ok/c]. At its most lenient, it can simply return @racket[any/c]. Even for programs where the strictness of contracts is a priority, it's advisable to be at least a lenient enough to allow for any impersonators that program's contracts produce. Generally, concepts Lathe Morphisms offers like categories and functors can't be impersonated in a way that's actually an @racket[impersonator-of?] the original, so they'll be a kind of pseudo-impersonator. Lathe Morphisms doesn't currently offer any pseudo-impersonators of its own, but programmers should watch out for at least the pseudo-impersonators they define themselves.



@table-of-contents[]



@section[#:tag "in-fp"]{Functional-programming-based theories}


@subsection[#:tag "in-fp/mediary"]{Functional-programming-based theories that are "mediary" for open extensibility}


@subsubsection[#:tag "in-fp/mediary/set"]{Mediary sets and their elements}

@defmodule[lathe-morphisms/in-fp/mediary/set]


@subsubsubsection[#:tag "in-fp/mediary/set/set-element-good-behavior"]{Behavior of well-behaved set elements}

@deftogether[(
  @defidform[set-element-good-behavior]
  @defform[
    #:link-target? #f
    
    (set-element-good-behavior
      getter-of-value-expr
      getter-of-accepts/c-expr)
    
    #:contracts
    (
      [getter-of-value-expr (-> any/c)]
      [getter-of-accepts/c-expr
        (-> (flat-contract-accepting/c (getter-of-value-expr)))])
  ]
  @defform[
    #:kind "match expander"
    #:link-target? #f
    (set-element-good-behavior
      getter-of-value-pat
      getter-of-accepts/c-pat)
  ]
  @defproc[(set-element-good-behavior? [v any/c]) boolean?]
  @defproc[
    (set-element-good-behavior-getter-of-value
      [element-gb set-element-good-behavior?])
    (-> any/c)
  ]
  @defproc[
    (set-element-good-behavior-getter-of-accepts/c
      [element-gb set-element-good-behavior?])
    (->
      (flat-contract-accepting/c
        (set-element-good-behavior-value element-gb)))
  ]
)]{
  Struct-like operations which construct and deconstruct a value that represents the behavior that makes a set element well-behaved. Namely, this behavior consists of a way to get the value itself (@racket[getter-of-value-expr]) and a way to get a contract that recognizes values that are @tech{close enough} to it (@racket[getter-of-accepts/c-expr]).
  
  Two @tt{set-element-good-behavior} values are @racket[equal?] if they contain @racket[equal?] elements.
}

@defproc[
  (set-element-good-behavior-value
    [element-gb set-element-good-behavior?])
  any/c
]{
  Given the well-behaved behavior of a well-behaved set element, returns the element.
}

@defproc[
  (set-element-good-behavior-with-value/c [value/c contract?])
  contract?
]{
  Returns a contract that recognizes the well-behaved behavior of a well-behaved set element as long as the given contract recognizes that element.
}

@defproc[
  (set-element-good-behavior-for-mediary-set-sys/c
    [mss mediary-set-sys?])
  contract?
]{
  Returns a contract that recognizes the well-behaved behavior of a well-behaved set element as long as the given mediary set system recognizes that well-behaved element as one of its (not necessarily well-behaved) elements.
}


@subsubsubsection[#:tag "in-fp/mediary/set/atomic-set-element-sys"]{Atomic set elements}

@deftogether[(
  @defproc[(atomic-set-element-sys? [v any/c]) boolean?]
  @defproc[(atomic-set-element-sys-impl? [v any/c]) boolean?]
  @defthing[
    prop:atomic-set-element-sys
    (struct-type-property/c atomic-set-element-sys-impl?)
  ]
)]{
  Structure type property operations for atomic set elements, which are well-behaved set elements that can procure their own @racket[set-element-good-behavior?] values.
}

@defproc[
  (atomic-set-element-sys-good-behavior
    [element atomic-set-element-sys?])
  set-element-good-behavior?
]{
  Given an atomic set element, returns its well-behaved behavior.
}

@defproc[
  (atomic-set-element-sys-accepts/c
    [element atomic-set-element-sys?])
  (flat-contract-accepting/c element)
]{
  Given an atomic set element, returns the contract it uses to check for @tech{close enough} values.
}

@defproc[
  (make-atomic-set-element-sys-impl-from-good-behavior
    [good-behavior
      (-> atomic-set-element-sys? set-element-good-behavior?)])
  atomic-set-element-sys-impl?
]{
  Given an implementation for @racket[atomic-set-element-sys-good-behavior], returns something a struct can use to implement the @racket[prop:atomic-set-element-sys] interface.
}


@subsubsubsection[#:tag "in-fp/mediary/set/mediary-set-sys"]{Mediary sets themselves}

@deftogether[(
  @defproc[(mediary-set-sys? [v any/c]) boolean?]
  @defproc[(mediary-set-sys-impl? [v any/c]) boolean?]
  @defthing[
    prop:mediary-set-sys
    (struct-type-property/c mediary-set-sys-impl?)
  ]
)]{
  Structure type property operations for mediary sets, which are sets where not all the elements have to be well-behaved.
  
  The only thing that makes an element well-behaved is that it can recognize when another value is @tech{close enough} to it.
  
  The behavior of a mediary set itself is limited to recognizing its values.
}

@defproc[
  (mediary-set-sys-element/c [mss mediary-set-sys?])
  contract?
]{
  Returns a contract which recognizes any element of the given mediary set.
}

@defproc[
  (make-mediary-set-sys-impl-from-contract
    [element/c (-> mediary-set-sys? contract?)])
  mediary-set-sys-impl?
]{
  Given an implementation for @racket[mediary-set-sys-element/c], returns something a struct can use to implement the @racket[prop:mediary-set-sys] interface.
}


@subsubsubsection[#:tag "in-fp/mediary/set/util"]{Utilities based on mediary sets}

@defproc[(ok/c [example any/c]) (flat-contract-accepting/c example)]{
  Given a value, returns a contract that recognizes values that are @tech{close enough} to it in the sense of an atomic set element. When the given value is indeed an @racket[atomic-set-element-sys?], this uses its @racket[atomic-set-element-sys-accepts/c] contract. Otherwise, it considers any value (@racket[any/c]) to be close enough.
}


@subsection[#:tag "in-fp/set"]{Sets}

@defmodule[lathe-morphisms/in-fp/set]

@deftogether[(
  @defproc[(set-sys? [v any/c]) boolean?]
  @defproc[(set-sys-impl? [v any/c]) boolean?]
  @defthing[prop:set-sys (struct-type-property/c set-sys-impl?)]
)]{
  Structure type property operations for sets, which have a type of elements represented by a contract and an @tt{...-accepts/c} method.
}

@defproc[(set-sys-element/c [ss set-sys?]) contract?]{
  Returns a contract which recognizes any element of the given set.
}

@defproc[
  (set-sys-element-accepts/c
    [ss set-sys?]
    [element (set-sys-element/c ss)])
  (flat-contract-accepting/c element)
]{
  Given an element of a given set, returns a contract which recognizes values that are @tech{close enough} to it.
}

@defproc[
  (make-set-sys-impl-from-contract
    [element/c (-> set-sys? contract?)]
    [element-accepts/c
      (->i ([_ss set-sys?] [_element (_ss) (set-sys-element/c _ss)])
        [_ (_element) (flat-contract-accepting/c _element)])])
  set-sys-impl?
]{
  Given implementations for @racket[set-sys-element/c] and @racket[set-sys-element-accepts/c], returns something a struct can use to implement the @racket[prop:set-sys] interface.
}


@subsection[#:tag "in-fp/category"]{Categories}

@defmodule[lathe-morphisms/in-fp/category]

@deftogether[(
  @defproc[(category-sys? [v any/c]) boolean?]
  @defproc[(category-sys-impl? [v any/c]) boolean?]
  @defthing[prop:category-sys (struct-type-property/c category-sys-impl?)]
)]{
  Structure type property operations for categories, which have a set (@racket[set-sys?]) of objects and for every two objects, a set of morphisms from one to the other.
}

@defproc[(category-sys-object-set-sys [cs category-sys?]) set-sys?]{
  Returns the set of objects in the given category.
}

@defproc[(category-sys-object/c [cs category-sys?]) contract?]{
  Returns a contract which recognizes any object of the given category.
}

@defproc[
  (category-sys-morphism-set-sys
    [cs category-sys?]
    [s (category-sys-object/c cs)]
    [t (category-sys-object/c cs)])
  set-sys?
]{
  Returns the set of morphisms that go from the given object @racket[s] (the source) to the given object @racket[t] (the target) in the given category.
}

@defproc[
  (category-sys-morphism/c
    [cs category-sys?]
    [s (category-sys-object/c cs)]
    [t (category-sys-object/c cs)])
  contract?
]{
  Returns a contract which recognizes any morphism that goes from the given object @racket[s] (the source) to the given object @racket[t] (the target) in the given category.
}

@defproc[
  (category-sys-object-identity-morphism
    [cs category-sys?]
    [object (category-sys-object/c cs)])
  (category-sys-morphism/c cs object object)
]{
  Returns the identity morphism which goes from the given object to itself in the given category.
}

@defproc[
  (category-sys-morphism-chain-two
    [cs category-sys?]
    [a (category-sys-object/c cs)]
    [b (category-sys-object/c cs)]
    [c (category-sys-object/c cs)]
    [ab (category-sys-morphism/c cs a b)]
    [bc (category-sys-morphism/c cs b c)])
  (category-sys-morphism/c cs a c)
]{
  Returns the morphism which is the composition of two given morphisms fenceposted by three given objects in the given category.
  
  This composition operation is written in @deftech{diagrammatic order}, where in the process of reading off the arguments from left to right, we proceed from the source to the target of each morphism. Composition in category theory literature is most often written with its arguments the other way around.
}

@defproc[
  (make-category-sys-impl-from-chain-two
    [object-set-sys (-> category-sys? set-sys?)]
    [morphism-set-sys
      (->i
        (
          [cs category-sys?]
          [s (cs) (category-sys-object/c cs)]
          [t (cs) (category-sys-object/c cs)])
        [_ set-sys?])]
    [object-identity-morphism
      (->i
        ([cs category-sys?] [object (cs) (category-sys-object/c cs)])
        [_ (cs object) (category-sys-morphism/c cs object object)])]
    [morphism-chain-two
      (->i
        (
          [cs category-sys?]
          [a (cs) (category-sys-object/c cs)]
          [b (cs) (category-sys-object/c cs)]
          [c (cs) (category-sys-object/c cs)]
          [ab (cs a b) (category-sys-morphism/c cs a b)]
          [bc (cs b c) (category-sys-morphism/c cs b c)])
        [_ (cs a c) (category-sys-morphism/c cs a c)])])
  category-sys-impl?
]{
  Given implementations for @racket[category-sys-object-set-sys], @racket[category-sys-morphism-set-sys], @racket[category-sys-object-identity-morphism], and @racket[category-sys-morphism-chain-two], returns something a struct can use to implement the @racket[prop:category-sys] interface.
  
  The given method implementations should observe some algebraic laws. Namely, the @racket[morphism-chain-two] operation should be associative, and @racket[object-identity-morphism] should act as an identity element for it. In more symbolic terms (using a pseudocode DSL):
  
  @racketblock[
    (#:for-all
      _cs category-sys?
      _a (category-sys-object/c _cs)
      _b (category-sys-object/c _cs)
      _ab (category-sys-morphism/c _cs _a _b)
      
      (#:should-be-equal
        (morphism-chain-two _cs _a _a _b
          (object-identity-morphism _cs _a)
          _ab)
        _ab))
    
    (#:for-all
      _cs category-sys?
      _a (category-sys-object/c _cs)
      _b (category-sys-object/c _cs)
      _ab (category-sys-morphism/c _cs _a _b)
      
      (#:should-be-equal
        (morphism-chain-two _cs _a _b _b
          _ab
          (object-identity-morphism _cs _b))
        _ab))
    
    (#:for-all
      _cs category-sys?
      _a (category-sys-object/c _cs)
      _b (category-sys-object/c _cs)
      _c (category-sys-object/c _cs)
      _d (category-sys-object/c _cs)
      _ab (category-sys-morphism/c _cs _a _b)
      _bc (category-sys-morphism/c _cs _b _c)
      _cd (category-sys-morphism/c _cs _c _d)
      
      (#:should-be-equal
        (morphism-chain-two _cs _a _c _d
          (morphism-chain-two _cs _a _b _c _ab _bc)
          _cd)
        (morphism-chain-two _cs _a _b _d
          _ab
          (morphism-chain-two _cs _b _c _d _bc _cd))))
  ]
}
