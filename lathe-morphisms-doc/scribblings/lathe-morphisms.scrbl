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
  
  When @racket[good-behavior] is called with an element @racket[_element] to obtain a @racket[set-element-good-behavior?] value, the result of calling the @racket[set-element-good-behavior-getter-of-value] getter of that value should be @racket[_element].
  
  Most of the time, @tt{make-atomic-set-element-sys-impl-from-good-behavior} is more general-purpose than necessary, and @racket[make-atomic-set-element-sys-impl-from-contract] can be used instead.
}

@defproc[
  (make-atomic-set-element-sys-impl-from-contract
    [accepts/c
      (->i ([element atomic-set-element-sys?])
        [_ (element) (flat-contract-accepting/c element)])])
  atomic-set-element-sys-impl?
]{
  Given an implementation for @racket[atomic-set-element-sys-accepts/c], returns something a struct can use to implement the @racket[prop:atomic-set-element-sys] interface.
  
  While this is more convenient, @racket[make-atomic-set-element-sys-impl-from-good-behavior] is technically more general-purpose. That alternative gives more comprehensive control over things like the @racket[eq?] identity of various values, the timing of side effects, the particular @racket[prop:procedure]-implementing structs that implement the procedures, the presence of impersonators in various places, and whether the @racket[set-element-good-behavior-getter-of-value] getter returns @racket[element] (which it should) or some other value (which it shouldn't). For an API-compliant pure FP style with little use of impersonators, there's virtually no need for that extra generality.
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

@defproc[
  (makeshift-set-sys-from-contract
    [element/c (-> contract?)]
    [element-accepts/c
      (->i ([_element (element/c)])
        [_ (_element) (flat-contract-accepting/c _element)])])
  set-sys?
]{
  Given implementations for @racket[set-sys-element/c] and @racket[set-sys-element-accepts/c], returns a set.
}


@subsection[#:tag "in-fp/category"]{Categories}

@defmodule[lathe-morphisms/in-fp/category]

@deftogether[(
  @defproc[(category-sys? [v any/c]) boolean?]
  @defproc[(category-sys-impl? [v any/c]) boolean?]
  @defthing[
    prop:category-sys
    (struct-type-property/c category-sys-impl?)
  ]
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
  
  This composition operation is written in @emph{diagrammatic order}, where in the process of reading off the arguments from left to right, we proceed from the source to the target of each morphism. Composition in category theory literature is most often written with its arguments the other way around.
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

@deftogether[(
  @defproc[(functor-sys? [v any/c]) boolean?]
  @defproc[(functor-sys-impl? [v any/c]) boolean?]
  @defthing[
    prop:functor-sys
    (struct-type-property/c functor-sys-impl?)
  ]
)]{
  Structure type property operations for functors, structure-preserving transformations of objects and morphisms from a source category to a target category.
}

@defproc[(functor-sys-source [fs functor-sys?]) category-sys?]{
  Returns a functor's source category.
}

@defproc[
  (functor-sys-replace-source [fs functor-sys?] [new-s category-sys?])
  functor-sys?
]{
  Returns a functor like the given one, but with its source category replaced with the given one. This may raise an error if the given value isn't similar enough to the one being replaced. This is intended only for use by @racket[functor-sys/c] and similar error-detection systems as a way to replace a value with one that reports better errors.
}

@defproc[(functor-sys-target [fs functor-sys?]) category-sys?]{
  Returns a functor's target category.
}

@defproc[
  (functor-sys-replace-target [fs functor-sys?] [new-t category-sys?])
  functor-sys?
]{
  Returns a functor like the given one, but with its target category replaced with the given one. This may raise an error if the given value isn't similar enough to the one being replaced. This is intended only for use by @racket[functor-sys/c] and similar error-detection systems as a way to replace a value with one that reports better errors.
}

@defproc[
  (functor-sys-apply-to-object
    [fs functor-sys?]
    [object (category-sys-object/c (functor-sys-source fs))])
  (category-sys-object/c (functor-sys-target fs))
]{
  Transforms an object according to the given functor.
}

@defproc[
  (functor-sys-apply-to-morphism
    [fs functor-sys?]
    [a (category-sys-object/c (functor-sys-source fs))]
    [b (category-sys-object/c (functor-sys-source fs))]
    [ab (category-sys-morphism/c (functor-sys-source fs) a b)])
  (category-sys-morphism/c (functor-sys-target fs)
    (functor-sys-apply-to-object fs a)
    (functor-sys-apply-to-object fs b))
]{
  Uses the given functor to transform a morphism that originally goes from the given source object @racket[a] to the given target object @racket[b].
}

@defproc[
  (make-functor-sys-impl-from-apply
    [source
      (-> functor-sys? category-sys?)]
    [replace-source
      (-> functor-sys? category-sys? functor-sys?)]
    [target
      (-> functor-sys? category-sys?)]
    [replace-target
      (-> functor-sys? category-sys? functor-sys?)]
    [apply-to-object
      (->i
        (
          [fs functor-sys?]
          [object (fs)
            (category-sys-object/c (functor-sys-source fs))])
        [_ (fs) (category-sys-object/c (functor-sys-target fs))])]
    [apply-to-morphism
      (->i
        (
          [fs functor-sys?]
          [a (fs) (category-sys-object/c (functor-sys-source fs))]
          [b (fs) (category-sys-object/c (functor-sys-source fs))]
          [morphism (fs a b)
            (category-sys-morphism/c (functor-sys-source fs) a b)])
        [_ (fs a b)
          (category-sys-morphism/c (functor-sys-target fs)
            (functor-sys-apply-to-object fs a)
            (functor-sys-apply-to-object fs b))])])
  functor-sys-impl?
]{
  Given implementations for the following methods, returns something a struct can use to implement the @racket[prop:functor-sys] interface.
  
  @itemlist[
    @item{@racket[functor-sys-source]}
    @item{@racket[functor-sys-replace-source]}
    @item{@racket[functor-sys-target]}
    @item{@racket[functor-sys-replace-target]}
    @item{@racket[functor-sys-apply-to-object]}
    @item{@racket[functor-sys-apply-to-morphism]}
  ]
  
  When the @tt{replace} methods don't raise errors, they should observe the lens laws: The result of getting a value after it's been replaced should be the same as just using the value that was passed to the replacer. The result of replacing a value with itself should be the same as not using the replacer at all. The of replacing a value and replacing it a second time should be the same as just skipping to the second replacement.
  
  Moreover, the @tt{replace} methods should not raise an error when a value is replaced with itself. They're intended only for use by @racket[functor-sys/c] and similar error-detection systems, which will tend to replace a replace a value with one that reports better errors.
  
  The other given method implementations should observe some algebraic laws. Namely, the @racket[apply-to-morphism] operation should respect the identity and associativity laws of the @racket[category-sys-object-identity-morphism] and @racket[category-sys-morphism-chain-two] operations. In more symbolic terms (using a pseudocode DSL):
  
  @racketblock[
    (#:for-all
      _fs functor-sys?
      #:let _s (functor-sys-source _fs)
      #:let _t (functor-sys-target _fs)
      _a (category-sys-object/c _s)
      
      (#:should-be-equal
        (apply-to-morphism _fs _a _a
          (category-sys-object-identity-morphism _s _a))
        (category-sys-object-identity-morphism _t
          (apply-to-object _fs _a))))
    
    (#:for-all
      _fs functor-sys?
      #:let _s (functor-sys-source _fs)
      #:let _t (functor-sys-target _fs)
      _a (category-sys-object/c _s)
      _b (category-sys-object/c _s)
      _c (category-sys-object/c _s)
      _ab (category-sys-morphism/c _s _a _b)
      _bc (category-sys-morphism/c _s _b _c)
      
      (#:should-be-equal
        (apply-to-morphism _fs _a _c
          (category-sys-morphism-chain-two _s _a _b _c _ab _bc))
        (category-sys-morphism-chain-two _t
          (apply-to-object _fs _a)
          (apply-to-object _fs _b)
          (apply-to-object _fs _c)
          (apply-to-morphism _fs _a _b _ab)
          (apply-to-morphism _fs _b _c _bc))))
  ]
}

@defproc[
  (functor-sys/c [source/c contract?] [target/c contract?])
  contract?
]{
  Returns a contract that recognizes any functor whose source and target categories are recognized by the given contracts.
  
  The result is a flat contract as long as the given contracts are flat.
}

@defproc[
  (makeshift-functor-sys
    [s category-sys?]
    [t category-sys?]
    [apply-to-object
      (-> (category-sys-object/c s) (category-sys-object/c t))]
    [apply-to-morphism
      (->i
        (
          [a (category-sys-object/c s)]
          [b (category-sys-object/c s)]
          [ab (a b) (category-sys-morphism/c s a b)])
        [_ (a b)
          (category-sys-morphism/c t
            (apply-to-object a)
            (apply-to-object b))])])
  (functor-sys/c (ok/c s) (ok/c t))
]{
  Returns a functor that goes from the source category @racket[s] to the target category @racket[t], transforming objects and morphisms using the given procedures.
  
  This may be more convenient than defining an instance of @racket[prop:functor-sys].
  
  The given procedures should satisfy algebraic laws. Namely, the @racket[apply-to-morphism] operation should respect the identity and associativity laws of the @racket[category-sys-object-identity-morphism] and @racket[category-sys-morphism-chain-two] operations. In more symbolic terms (using a pseudocode DSL):
  
  @racketblock[
    (#:for-all
      _a (category-sys-object/c _s)
      
      (#:should-be-equal
        (apply-to-morphism _a _a
          (category-sys-object-identity-morphism _s _a))
        (category-sys-object-identity-morphism _t
          (apply-to-object _a))))
    
    (#:for-all
      _a (category-sys-object/c _s)
      _b (category-sys-object/c _s)
      _c (category-sys-object/c _s)
      _ab (category-sys-morphism/c _s _a _b)
      _bc (category-sys-morphism/c _s _b _c)
      
      (#:should-be-equal
        (apply-to-morphism _a _c
          (category-sys-morphism-chain-two _s _a _b _c _ab _bc))
        (category-sys-morphism-chain-two _t
          (apply-to-object _a)
          (apply-to-object _b)
          (apply-to-object _c)
          (apply-to-morphism _a _b _ab)
          (apply-to-morphism _b _c _bc))))
  ]
}

@defproc[
  (functor-sys-identity [endpoint category-sys?])
  (functor-sys/c (ok/c endpoint) (ok/c endpoint))
]{
  Returns the identity functor on the given category. This is a functor that goes from the given category to itself, taking every object and every morphism to itself.
}

@defproc[
  (functor-sys-chain-two
    [ab functor-sys?]
    [bc (functor-sys/c (ok/c (functor-sys-target ab)) any/c)])
  (functor-sys/c
    (ok/c (functor-sys-source ab))
    (ok/c (functor-sys-target bc)))
]{
  Returns the composition of the two given functors. This is a functor that goes from the first functor's source category to the second functor's target category, transforming every object and every morphism by applying the first functor and then the second. The target of the first functor should match the source of the second.
  
  This composition operation is written in @emph{diagrammatic order}, where in the process of reading off the arguments from left to right, we proceed from the source to the target of each functor. Composition in category theory literature is most often written with its arguments the other way around.
}

@deftogether[(
  @defproc[(natural-transformation-sys? [v any/c]) boolean?]
  @defproc[(natural-transformation-sys-impl? [v any/c]) boolean?]
  @defthing[
    prop:natural-transformation-sys
    (struct-type-property/c natural-transformation-sys-impl?)
  ]
)]{
  Structure type property operations for natural transformations, transformations of morphisms that relate a source functor (@racket[functor-sys?]) to a target functor.
}

@defproc[
  (natural-transformation-sys-endpoint-source
    [nts natural-transformation-sys?])
  category-sys?
]{
  Returns a natural transformation's endpoint functors' source category.
}

@defproc[
  (natural-transformation-sys-replace-endpoint-source
    [nts natural-transformation-sys?]
    [new-es category-sys?])
  natural-transformation-sys?
]{
  Returns a natural transformation like the given one, but with its endpoint functors' source category replaced with the given one. This may raise an error if the given value isn't similar enough to the one being replaced. This is intended only for use by @racket[natural-transformation-sys/c] and similar error-detection systems as a way to replace a value with one that reports better errors.
}

@defproc[
  (natural-transformation-sys-endpoint-target
    [nts natural-transformation-sys?])
  category-sys?
]{
  Returns a natural transformation's endpoint functors' target category.
}

@defproc[
  (natural-transformation-sys-replace-endpoint-target
    [nts natural-transformation-sys?]
    [new-et category-sys?])
  natural-transformation-sys?
]{
  Returns a natural transformation like the given one, but with its endpoint functors' target category replaced with the given one. This may raise an error if the given value isn't similar enough to the one being replaced. This is intended only for use by @racket[natural-transformation-sys/c] and similar error-detection systems as a way to replace a value with one that reports better errors.
}

@defproc[
  (natural-transformation-sys-endpoint/c
    [nts natural-transformation-sys?])
  flat-contract?
]{
  Returns a flat contract that recognizes any functor that goes from the natural transformation's endpoint functors' source category to their target category.
}

@defproc[
  (natural-transformation-sys-source
    [nts natural-transformation-sys?])
  (natural-transformation-sys-endpoint/c nts)
]{
  Returns a natural transformation's source functor.
}

@defproc[
  (natural-transformation-sys-replace-source
    [nts natural-transformation-sys?]
    [new-s (natural-transformation-sys-endpoint/c nts)])
  natural-transformation-sys?
]{
  Returns a natural transformation like the given one, but with its source functor replaced with the given one. This may raise an error if the given value isn't similar enough to the one being replaced. This is intended only for use by @racket[natural-transformation-sys/c] and similar error-detection systems as a way to replace a value with one that reports better errors.
}

@defproc[
  (natural-transformation-sys-target
    [nts natural-transformation-sys?])
  (natural-transformation-sys-endpoint/c nts)
]{
  Returns a natural transformation's target functor.
}

@defproc[
  (natural-transformation-sys-replace-target
    [nts natural-transformation-sys?]
    [new-t (natural-transformation-sys-endpoint/c nts)])
  natural-transformation-sys?
]{
  Returns a natural transformation like the given one, but with its target functor replaced with the given one. This may raise an error if the given value isn't similar enough to the one being replaced. This is intended only for use by @racket[natural-transformation-sys/c] and similar error-detection systems as a way to replace a value with one that reports better errors.
}

@defproc[
  (natural-transformation-sys-apply-to-morphism
    [nts natural-transformation-sys?]
    [a
      (category-sys-object/c
        (natural-transformation-sys-endpoint-source nts))]
    [b
      (category-sys-object/c
        (natural-transformation-sys-endpoint-source nts))]
    [ab
      (category-sys-morphism/c
        (natural-transformation-sys-endpoint-source nts)
        a
        b)])
  (category-sys-morphism/c
    (natural-transformation-sys-endpoint-target nts)
    (functor-sys-apply-to-object
      (natural-transformation-sys-source nts)
      a)
    (functor-sys-apply-to-object
      (natural-transformation-sys-target nts)
      b))
]{
  Uses the given natural transformation to transform a morphism that originally goes from the given source object @racket[a] to the given target object @racket[b].
}

@defproc[
  (make-natural-transformation-sys-impl-from-apply
    [endpoint-source
      (-> natural-transformation-sys? category-sys?)]
    [replace-endpoint-source
      (-> natural-transformation-sys? category-sys?
        natural-transformation-sys?)]
    [endpoint-target
      (-> natural-transformation-sys? category-sys?)]
    [replace-endpoint-target
      (-> natural-transformation-sys? category-sys?
        natural-transformation-sys?)]
    [source
      (->i ([nts natural-transformation-sys?])
        [_ (nts) (natural-transformation-sys-endpoint/c nts)])]
    [replace-source
      (->i
        (
          [nts natural-transformation-sys?]
          [s (nts) (natural-transformation-sys-endpoint/c nts)])
        [_ natural-transformation-sys?])]
    [target
      (->i ([nts natural-transformation-sys?])
        [_ (nts) (natural-transformation-sys-endpoint/c nts)])]
    [replace-target
      (->i
        (
          [nts natural-transformation-sys?]
          [s (nts) (natural-transformation-sys-endpoint/c nts)])
        [_ natural-transformation-sys?])]
    [apply-to-morphism
      (->i
        (
          [nts natural-transformation-sys?]
          [a (nts)
            (category-sys-object/c
              (natural-transformation-sys-endpoint-source nts))]
          [b (nts)
            (category-sys-object/c
              (natural-transformation-sys-endpoint-source nts))]
          [ab (nts a b)
            (category-sys-morphism/c
              (natural-transformation-sys-endpoint-source nts)
              a
              b)])
        [_ (nts a b ab)
          (category-sys-morphism/c
            (natural-transformation-sys-endpoint-target nts)
            (functor-sys-apply-to-object
              (natural-transformation-sys-source nts)
              a)
            (functor-sys-apply-to-object
              (natural-transformation-sys-target nts)
              b))])])
  natural-transformation-sys-impl?
]{
  Given implementations for the following methods, returns something a struct can use to implement the @racket[prop:natural-transformation-sys] interface.
  
  @itemlist[
    @item{@racket[natural-transformation-sys-endpoint-source]}
    @item{@racket[natural-transformation-sys-replace-endpoint-source]}
    @item{@racket[natural-transformation-sys-endpoint-target]}
    @item{@racket[natural-transformation-sys-replace-endpoint-target]}
    @item{@racket[natural-transformation-sys-source]}
    @item{@racket[natural-transformation-sys-replace-source]}
    @item{@racket[natural-transformation-sys-target]}
    @item{@racket[natural-transformation-sys-replace-target]}
    @item{@racket[natural-transformation-sys-apply-to-morphism]}
  ]
  
  When the @tt{replace} methods don't raise errors, they should observe the lens laws: The result of getting a value after it's been replaced should be the same as just using the value that was passed to the replacer. The result of replacing a value with itself should be the same as not using the replacer at all. The of replacing a value and replacing it a second time should be the same as just skipping to the second replacement.
  
  Moreover, the @tt{replace} methods should not raise an error when a value is replaced with itself. They're intended only for use by @racket[natural-transformation-sys/c] and similar error-detection systems, which will tend to replace a replace a value with one that reports better errors.
  
  The other given method implementations should observe some algebraic laws. Namely, applying the @racket[apply-to-morphism] operation to a composed morphism should be the same as applying it to just one composed part of that morphism and applying the source and target functors to the other parts so that it joins up. In more symbolic terms (using a pseudocode DSL):
  
  @racketblock[
    (#:for-all
      _nts natural-transformation-sys?
      #:let _es (natural-transformation-sys-endpoint-source _nts)
      #:let _et (natural-transformation-sys-endpoint-target _nts)
      #:let _s (natural-transformation-sys-source _nts)
      #:let _t (natural-transformation-sys-target _nts)
      _a (category-sys-object/c _es)
      _b (category-sys-object/c _es)
      _c (category-sys-object/c _es)
      _ab (category-sys-morphism/c _es _a _b)
      _bc (category-sys-morphism/c _es _b _c)
      
      (#:should-be-equal
        (apply-to-morphism _nts _a _c
          (category-sys-morphism-chain-two _es _a _b _c _ab _bc))
        (category-sys-morphism-chain-two _t
          (functor-sys-apply-to-object _s _a)
          (functor-sys-apply-to-object _s _b)
          (functor-sys-apply-to-object _t _c)
          (functor-sys-apply-to-morphism _s _a _b _ab)
          (apply-to-morphism _nts _b _c _bc)))
      
      (#:should-be-equal
        (apply-to-morphism _nts _a _c
          (category-sys-morphism-chain-two _es _a _b _c _ab _bc))
        (category-sys-morphism-chain-two _t
          (functor-sys-apply-to-object _s _a)
          (functor-sys-apply-to-object _t _b)
          (functor-sys-apply-to-object _t _c)
          (apply-to-morphism _nts _a _b _ab)
          (functor-sys-apply-to-morphism _t _b _c _bc))))
  ]
  
  Using an infix notation where we infer most arguments and write @tt{(ab ; bc)} for the @racket[category-sys-morphism-chain-two] operation, these laws can be written like so:
  
  @codeblock[#:keep-lang-line? #f]{
    #lang scribble/manual
    s ab ; nts bc = nts (ab ; bc) = nts ab ; t bc
  }
  
  Using more math-style variable name choices:
  
  @codeblock[#:keep-lang-line? #f]{
    #lang scribble/manual
    F f ; alpha g = alpha (f ; g) = alpha f ; G g
  }
  
  In category theory literature, it's common for natural transformations' component functions to go from objects to morphisms, not morphisms to morphisms. We consider a natural transformation to act on an object by applying to its identity morphism. In that case the usual naturality square law looks like this:
  
  @codeblock[#:keep-lang-line? #f]{
    #lang scribble/manual
    F f ; alpha (id y) = alpha (id x) ; G f
  }
  
  We can derive that law like so:
  
  @codeblock[#:keep-lang-line? #f]{
    #lang scribble/manual
       F f ; alpha (id y)
    =  alpha (f ; id y)
    =  alpha f
    =  alpha (id x ; f)
    =  alpha (id x) ; G f
  }
}

@defproc[
  (natural-transformation-sys/c
    [endpoint-source/c contract?]
    [endpoint-target/c contract?]
    [source/c contract?]
    [target/c contract?])
  contract?
]{
  Returns a contract that recognizes any natural transformation for which the source and target functors and their source and target categories are recognized by the given contracts.
  
  The result is a flat contract as long as the given contracts are flat.
}

@defproc[
  (makeshift-natural-transformation-sys
    [es category-sys?]
    [et category-sys?]
    [s (functor-sys/c (ok/c es) (ok/c et))]
    [t (functor-sys/c (ok/c es) (ok/c et))]
    [apply-to-morphism
      (->i
        (
          [a (category-sys-object/c es)]
          [b (category-sys-object/c es)]
          [ab (a b) (category-sys-morphism/c es a b)])
        [_ (a b ab)
          (category-sys-morphism/c et
            (functor-sys-apply-to-object s a)
            (functor-sys-apply-to-object t b))])])
  (natural-transformation-sys/c (ok/c es) (ok/c et) (ok/c s) (ok/c t))
]{
  Returns a natural transformation that goes from the source functor @racket[s] to the target functor @racket[t], transforming morphisms using the given procedure.
  
  This may be more convenient than defining an instance of @racket[prop:natural-transformation-sys].
  
  The given procedure should satisfy algebraic laws. Namely, applying the @racket[apply-to-morphism] operation to a composed morphism should be the same as applying it to just one composed part of that morphism and applying the source and target functors to the other parts so that it joins up. In more symbolic terms (using a pseudocode DSL):
  
  @racketblock[
    (#:for-all
      _a (category-sys-object/c _es)
      _b (category-sys-object/c _es)
      _c (category-sys-object/c _es)
      _ab (category-sys-morphism/c _es _a _b)
      _bc (category-sys-morphism/c _es _b _c)
      
      (#:should-be-equal
        (apply-to-morphism _a _c
          (category-sys-morphism-chain-two _es _a _b _c _ab _bc))
        (category-sys-morphism-chain-two _t
          (functor-sys-apply-to-object _s _a)
          (functor-sys-apply-to-object _s _b)
          (functor-sys-apply-to-object _t _c)
          (functor-sys-apply-to-morphism _s _a _b _ab)
          (apply-to-morphism _b _c _bc)))
      
      (#:should-be-equal
        (apply-to-morphism _a _c
          (category-sys-morphism-chain-two _es _a _b _c _ab _bc))
        (category-sys-morphism-chain-two _t
          (functor-sys-apply-to-object _s _a)
          (functor-sys-apply-to-object _t _b)
          (functor-sys-apply-to-object _t _c)
          (apply-to-morphism _a _b _ab)
          (functor-sys-apply-to-morphism _t _b _c _bc))))
  ]
  
  For a little more discussion about how our choice of natural transformation laws relates to the more common naturality square law, see the documentation for @racket[make-natural-transformation-sys-impl-from-apply].
}

@defproc[
  (natural-transformation-sys-identity [endpoint functor-sys?])
  (natural-transformation-sys/c
    (ok/c (functor-sys-source endpoint))
    (ok/c (functor-sys-target endpoint))
    (ok/c endpoint)
    (ok/c endpoint))
]{
  Returns the identity natural transformation on the given functor. This is a natural transformation that goes from the given functor to itself, taking every morphism to itself.
}

@defproc[
  (natural-transformation-sys-chain-two
    [ab natural-transformation-sys?]
    [bc
      (natural-transformation-sys/c
        (ok/c (natural-transformation-sys-endpoint-source ab))
        (ok/c (natural-transformation-sys-endpoint-target ab))
        (ok/c (natural-transformation-sys-target ab))
        any/c)])
  (natural-transformation-sys/c
    (ok/c (natural-transformation-sys-endpoint-source ab))
    (ok/c (natural-transformation-sys-endpoint-target ab))
    (ok/c (natural-transformation-sys-source ab))
    (ok/c (natural-transformation-sys-target bc)))
]{
  Returns the vertical composition of the two given natural transformations. This is a natural transformation that goes from the first natural transformation's source functor to the second natural transformation's target functor. The target functor of the first natural transformation should match the source functor of the second.
  
  If all the algebraic structures involved obey their laws, then the way this natural transformation transforms a morphism that's composed from two morphisms is equivalent to applying the first natural transformation to the first part of the morphism, applying the second natural transformation to the second part of the morphism, and composing the results. Moreover, every morphism is the composition of itself and an identity morphism, so this specification determines the behavior on all morphisms. However, if any of the algebraic structures involved doesn't obey its laws, this operation may leak some Lathe Morphisms implementation details that are subject to change.
  
  This composition operation is written in @emph{diagrammatic order}, where in the process of reading off the arguments from left to right, we proceed from the source to the target of each natural transformation. Composition in category theory literature is most often written with its arguments the other way around.
}

@defproc[
  (natural-transformation-sys-chain-two-along-end
    [ab natural-transformation-sys?]
    [bc
      (natural-transformation-sys/c
        (ok/c (natural-transformation-sys-endpoint-target ab))
        any/c
        any/c
        any/c)])
  (natural-transformation-sys/c
    (ok/c (natural-transformation-sys-endpoint-source ab))
    (ok/c (natural-transformation-sys-endpoint-target bc))
    (ok/c
      (functor-sys-chain-two
        (natural-transformation-sys-source ab)
        (natural-transformation-sys-source bc)))
    (ok/c
      (functor-sys-chain-two
        (natural-transformation-sys-target ab)
        (natural-transformation-sys-target bc))))
]{
  Returns the horizontal composition of the two given natural transformations. This is a natural transformation that goes from the composition of their source functors to the composition of their target functors, transforming every morphism by applying the first natural transformation and then the second. The first natural transformation's endpoint functors' target category should match the second's endpoint functors' source category.
  
  This composition operation is written in @emph{diagrammatic order}, where in the process of reading off the arguments from left to right, we proceed from the endpoint source to the endpoint target of each natural transformation. Composition in category theory literature is most often written with its arguments the other way around.
}
