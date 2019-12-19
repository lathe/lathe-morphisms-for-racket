#lang parendown racket/base

; lawless.rkt
;
; Interfaces for category theory concepts where none of the laws have
; to hold. Nevertheless, we do go to some lengths to ensure these
; interfaces carry enough information to write informative contracts.

;   Copyright 2019 The Lathe Authors
;
;   Licensed under the Apache License, Version 2.0 (the "License");
;   you may not use this file except in compliance with the License.
;   You may obtain a copy of the License at
;
;       http://www.apache.org/licenses/LICENSE-2.0
;
;   Unless required by applicable law or agreed to in writing,
;   software distributed under the License is distributed on an
;   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
;   either express or implied. See the License for the specific
;   language governing permissions and limitations under the License.


(require #/only-in racket/contract struct-type-property/c)
(require #/only-in racket/contract/base
  -> ->i and/c any/c contract? contract-out)
(require #/only-in racket/contract/combinator
  contract-first-order-passes?)

(require #/only-in lathe-comforts w-)
(require #/only-in lathe-comforts/match
  define-match-expander-attenuated
  define-match-expander-from-match-and-make)
(require #/only-in lathe-comforts/struct
  auto-equal auto-write define-imitation-simple-generics
  define-imitation-simple-struct)


(provide #/contract-out
  [atomic-set-element-sys? (-> any/c boolean?)]
  [atomic-set-element-sys-impl? (-> any/c boolean?)]
  [atomic-set-element-sys-accepts/c
    (-> atomic-set-element-sys? contract?)]
  [atomic-set-element-sys-replace-set-sys
    (-> atomic-set-element-sys? set-sys? any/c)]
  [prop:atomic-set-element-sys
    (struct-type-property/c atomic-set-element-sys-impl?)]
  [make-atomic-set-element-sys-impl-from-accepts-and-replace
    (->
      (-> atomic-set-element-sys? contract?)
      (-> atomic-set-element-sys? set-sys? any/c)
      atomic-set-element-sys-impl?)])

(provide #/contract-out
  [mediary-set-sys? (-> any/c boolean?)]
  [mediary-set-sys-impl? (-> any/c boolean?)]
  [mediary-set-sys-element/c (-> mediary-set-sys? contract?)]
  [prop:mediary-set-sys
    (struct-type-property/c mediary-set-sys-impl?)]
  [make-mediary-set-sys-impl-from-contract
    (-> (-> mediary-set-sys? contract?) mediary-set-sys-impl?)])

(provide #/contract-out
  [set-sys? (-> any/c boolean?)]
  [set-sys-impl? (-> any/c boolean?)]
  [set-sys-mediary-set-sys (-> set-sys? mediary-set-sys?)]
  [set-sys-replace-mediary-set-sys
    (-> set-sys? mediary-set-sys? set-sys?)]
  [set-sys-element/c (-> set-sys? contract?)]
  [set-sys-element-accepts/c
    (->i ([ss set-sys?] [element (ss) (set-sys-element/c ss)])
      [_ contract?])]
  [set-sys-element-replace-set-sys
    (->i
      (
        [ss set-sys?]
        [element (ss) (set-sys-element/c ss)]
        [new-ss set-sys?])
      [_ any/c])]
  [prop:set-sys (struct-type-property/c set-sys-impl?)]
  [make-set-sys-impl-from-mediary
    (->
      (-> set-sys? mediary-set-sys?)
      (-> set-sys? mediary-set-sys? set-sys?)
      (->i ([ss set-sys?] [element (ss) (set-sys-element/c ss)])
        [_ contract?])
      (->i
        (
          [ss set-sys?]
          [element (ss) (set-sys-element/c ss)]
          [new-ss set-sys?])
        [_ any/c])
      set-sys-impl?)])

(provide #/contract-out
  [function-sys? (-> any/c boolean?)]
  [function-sys-impl? (-> any/c boolean?)]
  [function-sys-source (-> function-sys? set-sys?)]
  [function-sys-replace-source
    (-> function-sys? set-sys? function-sys?)]
  [function-sys-target (-> function-sys? set-sys?)]
  [function-sys-replace-target
    (-> function-sys? set-sys? function-sys?)]
  [function-sys-apply-to-element
    (->i
      (
        [fs function-sys?]
        [element (fs) (set-sys-element/c #/function-sys-source fs)])
      [_ (fs) (set-sys-element/c #/function-sys-target fs)])]
  [prop:function-sys (struct-type-property/c function-sys-impl?)]
  [make-function-sys-impl-from-apply
    (->
      (-> function-sys? set-sys?)
      (-> function-sys? set-sys? function-sys?)
      (-> function-sys? set-sys?)
      (-> function-sys? set-sys? function-sys?)
      (->i
        (
          [fs function-sys?]
          [element (fs) (set-sys-element/c #/function-sys-source fs)])
        [_ (fs) (set-sys-element/c #/function-sys-target fs)])
      function-sys-impl?)])

; TODO: Export more things.


; In this file we explore a "mediary" approach. This is a term we've
; coined to allude to the kind of system that's called "local" in
; Calculus of Structures literature. Those systems are mostly made up
; of variations on the Calculus of Structures "medial rule," which
; commutes one connective over another. Using these medial rules, the
; introduction and cut rules are commuted all the way to the edges of
; the derivation where they can be reduced to their atomic form. Thus,
; as long as the atoms are well-behaved enough to have their own intro
; and cut rules, the full-powered intro and cut rules are admissible
; and don't have to be part of the proof system's definition.
;
; One example of a Calculus of Structures paper that does this is
; "A Local System for Linear Logic."
;
; We're using this approach a bit differently, for category theory
; instead of proof theory. The idea that every object in a category
; has an identity morphism is a quality that strongly resembles the
; idea that every proposition in a proof system entails itself (the
; introduction rule). In this spirit, we're defining a kind of
; "mediary category" which becomes a proper category as long as the
; objects and morphisms are well-behaved. It seems a cell in a weak
; higher category is well-behaved as long as it has a family of
; well-behaved higher identity cells on it that relate all the ways it
; can be composed with peer-level identity cells. This takes care of
; the unitors, which leaves the associator and interchange cells.
;
; Simpson's conjecture suggests that as long as their are weak
; unitors, nothing is lost by having strict composition. If true, this
; might mean we don't have to have to worry about associators and
; interchange at all.
;
; Anyway, the benefit of having a mediary category is that it can be
; considered an open definition: Any well-behaved enough new objects
; and morphisms can be added onto it.
;
; And the reason we've bothered to explore it is because we already
; have a use for defining open lawless sets. A well-behaved element of
; a lawful set is one that supports an equality relation. With lawless
; sets, we don't model such a relation, but for error-checking
; purposes we do still have a way to create a contract to check that
; an element is equal enough to a given one (`...-accepts/c`). So if
; we define something that isn't an element of any one particular set,
; but which supports an `...-accepts/c` operation to enforce that
; another value is equal enough, the interface we're instantiating is
; that of a well-behaved element of a lawless set. Namely, here in
; this module named "lawless," we call that interface
; `atomic-set-element-sys?`, and the "lawless" is implied. We use the
; term "atomic" to convey that this is a well-behaved atom for some
; medial system, and in this case that medial system is
; `medial-set-sys?`.

; TODO: See if we should rename some of these things to remove "sys":
;
; The names `atomic-set-element-sys?`, `atomic-category-object-sys?`,
; and `atomic-category-morphism-sys?` in particular seem like they
; should lose the "sys" since we'll often use them on values that
; really represent some other system and only implement these
; interfaces for self-identification.
;
; The names `function-sys?`, `functor-sys?`, and
; `natural-transformation-sys?` might make sense to prune as well. The
; original point of the "sys" suffix (coined in Punctaffy) was to
; distinguish, for instance, a dictionary of monad operations from a
; value that was a monadic container, or a dictionary of number
; operations from a value that was a number. With things like
; `function-sys?`, the system itself is the function, albiet perhaps
; with some extra pizzazz to let contracts apply to it and to let it
; implement `...-accepts/c` functionality on the side. Most
; importantly, these don't even carry data types of their own (except
; those carried by their source and target), so there's no data value
; that can be confused for a "function" the way that a monadic
; container value might be confused for a "monad."

; TODO: Split this file into a few different files:
;
; We should probably have:
;
;   set.rkt (since it's a common base case)
;   digraph.rkt
;   category.rkt
;
; Arguably we should split off mediary sets as a "generalized
; sublibrary" (as discussed in README.md), since they're a pretty
; unusual experiment:
;
;   mediary/set.rkt
;   mediary/digraph.rkt
;   mediary/category.rkt
;   set.rkt
;   category.rkt
;
; Even if we split off "mediary" into its own library, we should keep
; the "mediary" qualifier on the names so that it's clear that they
; correspond with "atomic" and "atomicity" counterpart definitions.
;
; If we decide to extrapolate these things to arbitrarily higher
; dimensions, we should probably start an "n-dimensional" or
; "globular" generalized sublibrary for that.
;
; Oh, and we should export these things from public modules and
; document them.


(define-imitation-simple-generics
  atomic-set-element-sys? atomic-set-element-sys-impl?
  (#:method atomic-set-element-sys-accepts/c (#:this))
  (#:method atomic-set-element-sys-replace-set-sys (#:this) ())
  prop:atomic-set-element-sys
  make-atomic-set-element-sys-impl-from-accepts-and-replace
  'atomic-set-element-sys 'atomic-set-element-sys-impl (list))

(define-imitation-simple-generics
  mediary-set-sys? mediary-set-sys-impl?
  (#:method mediary-set-sys-element/c (#:this))
  prop:mediary-set-sys make-mediary-set-sys-impl-from-contract
  'mediary-set-sys 'mediary-set-sys-impl (list))

(define-imitation-simple-generics
  set-sys? set-sys-impl?
  (#:method set-sys-mediary-set-sys (#:this))
  (#:method set-sys-replace-mediary-set-sys (#:this) ())
  (#:method set-sys-element-accepts/c (#:this) ())
  (#:method set-sys-element-replace-set-sys (#:this) () ())
  prop:set-sys make-set-sys-impl-from-mediary
  'set-sys 'set-sys-impl (list))

(define (set-sys-element/c ss)
  (mediary-set-sys-element/c #/set-sys-mediary-set-sys ss))

; TODO: See if we should have functions between mediary sets too, i.e.
; `mediary-function-sys?`. If we do that, see if we should define
; `function-sys?` in terms of `mediary-function-sys?`.
(define-imitation-simple-generics
  function-sys? function-sys-impl?
  (#:method function-sys-source (#:this))
  (#:method function-sys-replace-source (#:this) ())
  (#:method function-sys-target (#:this))
  (#:method function-sys-replace-target (#:this) ())
  (#:method function-sys-apply-to-element (#:this) ())
  prop:function-sys make-function-sys-impl-from-apply
  'function-sys 'function-sys-impl (list))

; NOTE: Even though we define `mediary-digraph-sys?`, we don't define
; `atomic-digraph-node-sys?`, `atomic-digraph-edge-sys?`, or
; `digraph-sys?`, nor do we use `mediary-digraph-sys?` or
; `digraph-sys?` as a building block for the structure of
; `mediary-category-sys?` or `category-sys?`. We define this solely to
; be passed into an `atomic-category-object-sys-constrain-coherence`
; method.
(define-imitation-simple-generics
  mediary-digraph-sys? mediary-digraph-sys-impl?
  (#:method mediary-digraph-sys-node-mediary-set-sys (#:this))
  (#:method mediary-digraph-sys-replace-node-mediary-set-sys
    (#:this)
    ())
  (#:method mediary-digraph-sys-edge-mediary-set-sys-family (#:this))
  (#:method mediary-digraph-sys-replace-edge-mediary-set-sys-family
    (#:this)
    ())
  prop:mediary-digraph-sys
  make-mediary-digraph-sys-impl-from-chain-two
  'mediary-digraph-sys 'mediary-digraph-sys-impl (list))

(define (mediary-digraph-sys-object/c mcs)
  (mediary-set-sys-element/c
    (mediary-digraph-sys-node-mediary-set-sys mcs)))

(define (mediary-digraph-sys-morphism/c mcs s t)
  (mediary-set-sys-element/c
    ( (mediary-digraph-sys-edge-mediary-set-sys-family mcs) s t)))

(define-imitation-simple-generics
  atomic-category-object-sys? atomic-category-object-sys-impl?
  
  ; NOTE:
  ;
  ; Most of the methods here correspond to particular methods of
  ; `category-sys?`. The
  ; `atomic-category-object-sys-coherence-constraints`,
  ; `atomic-category-object-constrain-coherence`, and
  ; `atomic-category-object-sys-coherence` methods are an exception;
  ; they don't correspond to `category-sys?` methods named
  ; `category-sys-object-coherence-constraints`,
  ; `category-sys-object-constrain-coherence`, and
  ; `category-sys-object-coherence` as one might expect.
  ;
  ;   [atomic-category-object-sys-coherence-constraints
  ;     (->i ([object atomic-category-object-sys?])
  ;       [_
  ;         (and/c mediary-digraph-sys?
  ;           (by-own-method/c mds
  ;             (contract-first-order-passes?
  ;               (mediary-digraph-sys-node/c mds)
  ;               object)))])]
  ;   [atomic-category-object-sys-constrain-coherence
  ;     (->i
  ;       (
  ;         [mds mediary-digraph-sys?]
  ;         [object (mds)
  ;           (and/c atomic-category-object-sys?
  ;             (mediary-digraph-sys-node/c mds))])
  ;       [_ atomic-category-object-sys?])]
  ;   [atomic-category-object-sys-coherence
  ;     (->i
  ;       (
  ;         [ss set-sys?]
  ;         [object (ss)
  ;           (and/c atomic-category-object-sys?
  ;             (set-sys-element/c ss))])
  ;       [_
  ;         (w- mds
  ;           (atomic-category-object-sys-coherence-constraints
  ;             object)
  ;         #/list/c
  ;           (mediary-digraph-sys-edge/c mds object object)
  ;           category-morphism-atomicity?)])]
  ;
  ; The purpose of `atomic-category-object-sys-coherence` is mainly to
  ; let the object supply its own identity morphism. A
  ; `mediary-category-sys?` doesn't supply an identity morphism for
  ; every object; the objects have to bring their own.
  ;
  ; There are a few complications to the signature of
  ; `atomic-category-object-sys-coherence` so as to be more consistent
  ; with the way we represent coherence information on
  ; higher-dimensional cells.
  ;
  ; Coherence information tends to include unitor laws, which are
  ; cells that relate a morphism to its composition with one of its
  ; endpoints' identity cells. To express this composition, one of the
  ; arguments to `atomic-category-object-sys-coherence` is the
  ; composition algebra in which to express it (in this
  ; low-dimensional case, merely a `set-sys?` with no form of
  ; composition at all).
  ;
  ; The purpose of `atomic-category-object-sys-constrain-coherence` is
  ; to let an object's coherence information (in this low-dimensional
  ; case, just its identity morphism) be subject to the expectations
  ; of the surrounding category. Even if a category is designed to be
  ; extended with `atomic-category-object-sys?` values, the particular
  ; `atomic-category-object-sys?` values it allows should be ones that
  ; have coherence information that is also allowed. By using this
  ; method, the category can impose that constraint on the objects.
  ;
  ; Once imposed, those constraints can be retrieved again via
  ; `atomic-category-object-sys-coherence-constraints`, which the
  ; signature of `atomic-category-object-sys-coherence` makes use of
  ; to report appropriate contract violation errors.
  ;
  ; The constraints accepted by
  ; `atomic-category-object-sys-constrain-coherence` and exposed again
  ; by `atomic-category-object-sys-coherence-constraints` are carried
  ; in a mediary directed graph, which contains just enough structure
  ; to allow these functions to have informative contracts.
  ; (Specifically, the "directed graph" is an n-category without
  ; identities or composition, and it's "mediary" because it omits the
  ; error-checking-specific capability to specify a contract on a cell
  ; that ensures it's an acceptable repeat of a given cell
  ; (`...-accepts/c`).) (TODO: There are several terms for variations
  ; on the theme of directed graphs. Figure out which specific term
  ; we're looking for here.)
  ;
  ; Note that it is straightforward to take the intersection of the
  ; contracts of two directed graphs like these, since they consist
  ; only of contracts that cells of various shapes must abide by, and
  ; the contracts can be combined with `and/c`. As such, the result of
  ; a `...-coherence-constraints` method will often be an intersection
  ; of the directed graphs given to the `...-constrain-coherence`
  ; method.
  ;
  (#:method atomic-category-object-sys-accepts/c (#:this))
  (#:method atomic-category-object-sys-replace-category-sys
    (#:this)
    ())
  (#:method atomic-category-object-sys-coherence-constraints (#:this))
  (#:method atomic-category-object-sys-constrain-coherence
    ()
    (#:this))
  (#:method atomic-category-object-sys-coherence () (#:this))
  prop:atomic-category-object-sys
  make-atomic-category-object-sys-impl-from-coherence
  'atomic-category-object-sys 'atomic-category-object-sys-impl (list))

(define-imitation-simple-struct
  (category-morphism-atomicity?
    
    ;   [category-morphism-atomicity-accepts/c
    ;     (-> category-morphism-atomicity? (-> any/c contract?))]
    category-morphism-atomicity-accepts/c
    
    ;   [category-morphism-atomicity-replace-category-sys
    ;     (-> category-morphism-atomicity?
    ;       (-> any/c category-sys? any/c))]
    category-morphism-atomicity-replace-category-sys
    
    ;   [category-morphism-atomicity-replace-source
    ;     (-> category-morphism-atomicity? (-> any/c any/c any/c))]
    category-morphism-atomicity-replace-source
    
    ;   [category-morphism-atomicity-replace-target
    ;     (-> category-morphism-atomicity? (-> any/c any/c any/c))]
    category-morphism-atomicity-replace-target)
  
  unguarded-category-morphism-atomicity
  'category-morphism-atomicity (current-inspector)
  (auto-write)
  (auto-equal))

(define-imitation-simple-generics
  atomic-category-morphism-sys? atomic-category-morphism-sys-impl?
  
  ; NOTE:
  ;
  ; Most of the functionality here is comprised of the fields of the
  ; `category-morphism-atomicity?` result of
  ; `atomic-category-morphism-sys-atomicity`, which correspond to
  ; various particular methods of `category-sys?`. The
  ; `atomic-category-morphism-sys-source` and
  ; `atomic-category-morphism-sys-target` methods don't follow the
  ; pattern; they don't correspond to `category-sys?` methods named
  ; `category-sys-morphism-source` and `category-sys-morphism-target`
  ; as one might expect.
  ;
  ; That's by design. Even if a category is designed to be extended
  ; with `atomic-category-morphism-sys?` values, its
  ; `(category-sys-morphism/c cs source target)` contract shouldn't
  ; accept just any `atomic-category-morphism-sys?` it sees; it
  ; should only accept one whose source and target are acceptable by
  ; the given `source` and `target` objects. So an
  ; `atomic-category-morphism-sys?` needs to expose source and target
  ; values that can be checked this way.
  ;
  (#:method atomic-category-morphism-sys-source (#:this))
  (#:method atomic-category-morphism-sys-target (#:this))
  (#:method atomic-category-morphism-sys-atomicity (#:this))
  prop:atomic-category-morphism-sys
  make-atomic-category-morphism-sys-impl-from-accepts-and-replace
  'atomic-category-morphism-sys 'atomic-category-morphism-sys-impl
  (list))

(define-imitation-simple-generics
  mediary-category-sys? mediary-category-sys-impl?
  (#:method mediary-category-sys-object-mediary-set-sys (#:this))
  (#:method mediary-category-sys-replace-object-mediary-set-sys
    (#:this)
    ())
  (#:method mediary-category-sys-morphism-mediary-set-sys-family
    (#:this))
  (#:method
    mediary-category-sys-replace-morphism-mediary-set-sys-family
    (#:this)
    ())
  ;   [mediary-category-sys-morphism-chain-two
  ;     (->i
  ;       (
  ;         [mcs mediary-category-sys?]
  ;         [a (mcs) (mediary-category-sys-object/c mcs)]
  ;         [b (mcs) (mediary-category-sys-object/c mcs)]
  ;         [c (mcs) (mediary-category-sys-object/c mcs)]
  ;         [ab (mcs a b) (mediary-category-sys-morphism/c mcs a b)]
  ;         [bc (mcs b c) (mediary-category-sys-morphism/c mcs b c)])
  ;       [_ (mcs a c) (mediary-category-sys-morphism/c mcs a c)])]
  (#:method mediary-category-sys-morphism-chain-two
    (#:this)
    ()
    ()
    ()
    ()
    ())
  
  ; NOTE:
  ;
  ; It's not enough just to have a composition operation on morphisms.
  ; Not all the objects and morphisms of a `mediary-category-sys?` are
  ; necessarily well-behaved in the sense of having identity cells
  ; (and, if this were a lawful or higher-dimensional category, unitor
  ; laws for those cells to obey). However, if all the generating
  ; objects and morphisms really are well-behaved, then the whole
  ; `mediary-category-sys?` ought to be as well-behaved as a
  ; `category-sys?`, so we ought to find that the composition
  ; morphisms are well-behaved like the others.
  ;
  ; We can ensure this by making it so the composition of any two
  ; morphisms that have "atomicity" functionality has its own
  ; atomicity functionality in turn. This also allows small parts of a
  ; `mediary-category-sys?` to be poorly behaved without interfering
  ; with the usefulness of well-behaved subsystems.
  ;
  ;   [mediary-category-sys-morphism-atomicity-chain-two
  ;     (->i
  ;       (
  ;         [mcs mediary-category-sys?]
  ;         [a (mcs) (mediary-category-sys-object/c mcs)]
  ;         [b (mcs) (mediary-category-sys-object/c mcs)]
  ;         [c (mcs) (mediary-category-sys-object/c mcs)]
  ;         [ab (mcs a b) (mediary-category-sys-morphism/c mcs a b)]
  ;         [ab-atomicity category-morphism-atomicity?]
  ;         [bc (mcs b c) (mediary-category-sys-morphism/c mcs b c)]
  ;         [bc-atomicity category-morphism-atomicity?])
  ;       [_ category-morphism-atomicity?])]
  ;
  (#:method mediary-category-sys-morphism-atomicity-chain-two
    (#:this)
    ()
    ()
    ()
    ()
    ()
    ()
    ())
  prop:mediary-category-sys
  make-mediary-category-sys-impl-from-chain-two
  'mediary-category-sys 'mediary-category-sys-impl (list))

(define (mediary-category-sys-object/c mcs)
  (mediary-set-sys-element/c
    (mediary-category-sys-object-mediary-set-sys mcs)))

(define (mediary-category-sys-morphism/c mcs s t)
  (mediary-set-sys-element/c
    (
      (mediary-category-sys-morphism-mediary-set-sys-family mcs)
      s
      t)))

(define-imitation-simple-generics
  category-sys? category-sys-impl?
  (#:method category-sys-object-mediary-set-sys (#:this))
  (#:method category-sys-replace-object-mediary-set-sys (#:this) ())
  (#:method category-sys-morphism-mediary-set-sys-family (#:this))
  (#:method category-sys-replace-morphism-mediary-set-sys-family
    (#:this)
    ())
  (#:method category-sys-mediary-category-sys (#:this))
  (#:method category-sys-replace-mediary-category-sys (#:this) ())
  (#:method category-sys-object-set-sys (#:this))
  (#:method category-sys-replace-object-set-sys (#:this) ())
  (#:method category-sys-object-replace-category-sys (#:this) () ())
  (#:method category-sys-object-identity-morphism (#:this) ())
  (#:method category-sys-morphism-set-sys-family (#:this))
  (#:method category-sys-replace-morphism-set-sys-family (#:this) ())
  (#:method category-sys-morphism-replace-category-sys
    (#:this)
    ()
    ()
    ()
    ())
  (#:method category-sys-morphism-replace-source (#:this) () () () ())
  (#:method category-sys-morphism-replace-target (#:this) () () () ())
  prop:category-sys make-category-sys-impl-from-mediary
  'category-sys 'category-sys-impl (list))

(define (category-sys-object/c cs)
  (mediary-set-sys-element/c
    (category-sys-object-mediary-set-sys cs)))

(define (category-sys-morphism/c cs s t)
  (mediary-set-sys-element/c
    ( (category-sys-morphism-mediary-set-sys-family cs) s t)))

(define-match-expander-attenuated
  attenuated-category-morphism-atomicity
  unguarded-category-morphism-atomicity
  [accepts/c (-> any/c contract?)]
  [replace-category-sys (-> any/c category-sys? any/c)]
  [replace-source (-> any/c any/c any/c)]
  [replace-target (-> any/c any/c any/c)]
  #t)
(define-match-expander-from-match-and-make
  category-morphism-atomicity
  unguarded-category-morphism-atomicity
  attenuated-category-morphism-atomicity
  attenuated-category-morphism-atomicity)

(define-imitation-simple-generics
  functor-sys? functor-sys-impl?
  (#:method functor-sys-source (#:this))
  (#:method functor-sys-replace-source (#:this) ())
  (#:method functor-sys-target (#:this))
  (#:method functor-sys-replace-target (#:this) ())
  (#:method functor-sys-apply-to-object (#:this) ())
  (#:method functor-sys-apply-to-morphism (#:this) () () ())
  prop:functor-sys make-functor-sys-impl-from-apply
  'functor-sys 'functor-sys-impl (list))

(define-imitation-simple-generics
  natural-transformation-sys? natural-transformation-sys-impl?
  (#:method natural-transformation-sys-endpoint-source (#:this))
  (#:method natural-transformation-sys-replace-endpoint-source
    (#:this)
    ())
  (#:method natural-transformation-sys-endpoint-target (#:this))
  (#:method natural-transformation-sys-replace-endpoint-target
    (#:this)
    ())
  (#:method natural-transformation-sys-source (#:this))
  (#:method natural-transformation-sys-replace-source (#:this) ())
  (#:method natural-transformation-sys-target (#:this))
  (#:method natural-transformation-sys-replace-target (#:this) ())
  (#:method natural-transformation-sys-apply-to-object (#:this) ())
  prop:natural-transformation-sys
  make-natural-transformation-sys-impl-from-apply
  'natural-transformation-sys 'natural-transformation-sys-impl (list))
