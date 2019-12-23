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


(require #/for-syntax racket/base)

(require #/for-syntax #/only-in syntax/parse
  expr/c id)

; NOTE: The Racket documentation says `get/build-late-neg-projection`
; is in `racket/contract/combinator`, but it isn't. It's in
; `racket/contract/base`. Since it's also in `racket/contract` and the
; documentation correctly says it is, we require it from there.
(require #/only-in racket/contract
  get/build-late-neg-projection struct-type-property/c)
(require #/only-in racket/contract/base
  -> ->i and/c any/c contract? contract-name contract-out list/c
  rename-contract unconstrained-domain->)
(require #/only-in racket/contract/combinator
  blame-add-context coerce-contract contract-first-order-passes?
  make-contract)
(require #/only-in syntax/parse/define
  define-simple-macro)

(require #/only-in lathe-comforts dissect dissectfn fn w-)
(require #/only-in lathe-comforts/contract by-own-method/c swap/c)
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
  [accepts/c (-> any/c contract?)])

(provide #/contract-out
  [set-sys? (-> any/c boolean?)]
  [set-sys-impl? (-> any/c boolean?)]
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
      [_ (new-ss) (swap/c #/set-sys-element/c new-ss)])]
  [prop:set-sys (struct-type-property/c set-sys-impl?)]
  [make-set-sys-impl-from-contract
    (->
      (-> set-sys? contract?)
      (->i ([ss set-sys?] [element (ss) (set-sys-element/c ss)])
        [_ contract?])
      (->i
        (
          [ss set-sys?]
          [element (ss) (set-sys-element/c ss)]
          [new-ss set-sys?])
        [_ (new-ss) (swap/c #/set-sys-element/c new-ss)])
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
      function-sys-impl?)]
  [function-sys/c (-> contract? contract? contract?)]
  [makeshift-function-sys
    (->i
      (
        [s set-sys?]
        [t set-sys?]
        [apply-to-element (s t)
          (-> (set-sys-element/c s) (set-sys-element/c t))])
      [_ (s t) (function-sys/c (accepts/c s) (accepts/c t))])]
  [function-sys-identity
    (->i ([endpoint set-sys?])
      [_ (endpoint)
        (function-sys/c (accepts/c endpoint) (accepts/c endpoint))])]
  [function-sys-chain-two
    (->i
      (
        [ab function-sys?]
        [bc (ab)
          (function-sys/c
            (accepts/c #/function-sys-target ab)
            any/c)])
      [_ (ab bc)
        (function-sys/c
          (accepts/c #/function-sys-source ab)
          (accepts/c #/function-sys-target bc))])])

(provide #/contract-out
  [mediary-digraph-sys? (-> any/c boolean?)]
  [mediary-digraph-sys-impl? (-> any/c boolean?)]
  [mediary-digraph-sys-node-mediary-set-sys
    (-> mediary-digraph-sys? mediary-set-sys?)]
  [mediary-digraph-sys-replace-node-mediary-set-sys
    (-> mediary-digraph-sys? mediary-set-sys? mediary-digraph-sys?)]
  [mediary-digraph-sys-node/c (-> mediary-digraph-sys? contract?)]
  [mediary-digraph-sys-edge-mediary-set-sys-family
    (->i ([mds mediary-digraph-sys?])
      [_ (mds)
        (->
          (mediary-digraph-sys-node/c mds)
          (mediary-digraph-sys-node/c mds)
          mediary-set-sys?)])]
  [mediary-digraph-sys-replace-edge-mediary-set-sys-family
    (->i
      (
        [mds mediary-digraph-sys?]
        [edge-mediary-set-sys-family (mds)
          (->
            (mediary-digraph-sys-node/c mds)
            (mediary-digraph-sys-node/c mds)
            mediary-set-sys?)])
      [_ mediary-digraph-sys?])]
  [mediary-digraph-sys-edge/c
    (->i
      (
        [mds mediary-digraph-sys?]
        [s (mds) (mediary-digraph-sys-node/c mds)]
        [t (mds) (mediary-digraph-sys-node/c mds)])
      [_ contract?])]
  [prop:mediary-digraph-sys
    (struct-type-property/c mediary-digraph-sys-impl?)]
  [make-mediary-digraph-sys-impl-from-mediary-set-systems
    (->
      (-> mediary-digraph-sys? mediary-set-sys?)
      (-> mediary-digraph-sys? mediary-set-sys? mediary-digraph-sys?)
      (->i ([mds mediary-digraph-sys?])
        [_ (mds)
          (->
            (mediary-digraph-sys-node/c mds)
            (mediary-digraph-sys-node/c mds)
            mediary-set-sys?)])
      (->i
        (
          [mds mediary-digraph-sys?]
          [edge-mediary-set-sys-family (mds)
            (->
              (mediary-digraph-sys-node/c mds)
              (mediary-digraph-sys-node/c mds)
              mediary-set-sys?)])
        [_ mediary-digraph-sys?])
      mediary-digraph-sys-impl?)])

(provide #/contract-out
  [atomic-category-object-sys? (-> any/c boolean?)]
  [atomic-category-object-sys-impl? (-> any/c boolean?)]
  [atomic-category-object-sys-accepts/c
    (-> atomic-category-object-sys? contract?)]
  [atomic-category-object-sys-replace-category-sys
    (-> atomic-category-object-sys? category-sys?
      atomic-category-object-sys?)]
  [atomic-category-object-sys-coherence-constraints
    (->i ([object atomic-category-object-sys?])
      [_ (object)
        (and/c mediary-digraph-sys?
          (by-own-method/c mds
            (contract-first-order-passes?
              (mediary-digraph-sys-node/c mds)
              object)))])]
  [atomic-category-object-sys-constrain-coherence
    (->i
      (
        [mds mediary-digraph-sys?]
        [object (mds)
          (and/c atomic-category-object-sys?
            (mediary-digraph-sys-node/c mds))])
      [_ atomic-category-object-sys?])]
  [atomic-category-object-sys-coherence
    (->i
      (
        [ss set-sys?]
        [object (ss)
          (and/c atomic-category-object-sys?
            (set-sys-element/c ss))])
      [_ (object)
        (w- mds
          (atomic-category-object-sys-coherence-constraints object)
        #/list/c
          (mediary-digraph-sys-edge/c mds object object)
          category-morphism-atomicity?)])]
  [prop:atomic-category-object-sys
    (struct-type-property/c atomic-category-object-sys-impl?)]
  [make-atomic-category-object-sys-impl-from-coherence
    (->
      (-> atomic-category-object-sys? contract?)
      (-> atomic-category-object-sys? category-sys?
        atomic-category-object-sys?)
      (->i ([object atomic-category-object-sys?])
        [_ (object)
          (and/c mediary-digraph-sys?
            (by-own-method/c mds
              (contract-first-order-passes?
                (mediary-digraph-sys-node/c mds)
                object)))])
      (->i
        (
          [mds mediary-digraph-sys?]
          [object (mds)
            (and/c atomic-category-object-sys?
              (mediary-digraph-sys-node/c mds))])
        [_ atomic-category-object-sys?])
      (->i
        (
          [ss set-sys?]
          [object (ss)
            (and/c atomic-category-object-sys?
              (set-sys-element/c ss))])
        [_ (object)
          (w- mds
            (atomic-category-object-sys-coherence-constraints object)
          #/list/c
            (mediary-digraph-sys-edge/c mds object object)
            category-morphism-atomicity?)])
      atomic-category-object-sys-impl?)])

(provide
  category-morphism-atomicity)
(provide #/contract-out
  [category-morphism-atomicity? (-> any/c boolean?)]
  [category-morphism-atomicity-accepts/c
    (-> category-morphism-atomicity? (-> any/c contract?))]
  [category-morphism-atomicity-replace-category-sys
    (-> category-morphism-atomicity? (-> any/c category-sys? any/c))]
  [category-morphism-atomicity-replace-source
    (-> category-morphism-atomicity? (-> any/c any/c any/c))]
  [category-morphism-atomicity-replace-target
    (-> category-morphism-atomicity? (-> any/c any/c any/c))])

(provide #/contract-out
  [atomic-category-morphism-sys? (-> any/c boolean?)]
  [atomic-category-morphism-sys-impl? (-> any/c boolean?)]
  [atomic-category-morphism-sys-accepts/c
    (-> atomic-category-morphism-sys? contract?)]
  [atomic-category-morphism-sys-replace-category-sys
    (-> atomic-category-morphism-sys? category-sys? any/c)]
  [atomic-category-morphism-sys-source
    (-> atomic-category-morphism-sys? any/c)]
  [atomic-category-morphism-sys-replace-source
    (-> atomic-category-morphism-sys? any/c any/c)]
  [atomic-category-morphism-sys-target
    (-> atomic-category-morphism-sys? any/c)]
  [atomic-category-morphism-sys-replace-target
    (-> atomic-category-morphism-sys? any/c any/c)]
  [atomic-category-morphism-sys-atomicity
    (-> atomic-category-morphism-sys? category-morphism-atomicity?)]
  [prop:atomic-category-morphism-sys
    (struct-type-property/c atomic-category-morphism-sys-impl?)]
  [make-atomic-category-morphism-sys-impl-from-atomicity
    (->
      (-> atomic-category-morphism-sys? any/c)
      (-> atomic-category-morphism-sys? any/c)
      (-> atomic-category-morphism-sys? category-morphism-atomicity?)
      atomic-category-morphism-sys-impl?)]
  [atomic-category-morphism-sys/c (-> contract? contract? contract?)])

(provide #/contract-out
  [mediary-category-sys? (-> any/c boolean?)]
  [mediary-category-sys-impl? (-> any/c boolean?)]
  [mediary-category-sys-object-mediary-set-sys
    (-> mediary-category-sys? mediary-set-sys?)]
  [mediary-category-sys-replace-object-mediary-set-sys
    (-> mediary-category-sys? mediary-set-sys? mediary-category-sys?)]
  [mediary-category-sys-object/c (-> mediary-category-sys? contract?)]
  [mediary-category-sys-morphism-mediary-set-sys-family
    (->i ([mcs mediary-category-sys?])
      [_ (mcs)
        (->
          (mediary-category-sys-object/c mcs)
          (mediary-category-sys-object/c mcs)
          mediary-set-sys?)])]
  [mediary-category-sys-replace-morphism-mediary-set-sys-family
    (->i
      (
        [mcs mediary-category-sys?]
        [morphism-mediary-set-sys-family (mcs)
          (->
            (mediary-category-sys-object/c mcs)
            (mediary-category-sys-object/c mcs)
            mediary-set-sys?)])
      [_ mediary-category-sys?])]
  [mediary-category-sys-morphism/c
    (->i
      (
        [mcs mediary-category-sys?]
        [s (mcs) (mediary-category-sys-object/c mcs)]
        [t (mcs) (mediary-category-sys-object/c mcs)])
      [_ contract?])]
  [mediary-category-sys-morphism-chain-two
    (->i
      (
        [mcs mediary-category-sys?]
        [a (mcs) (mediary-category-sys-object/c mcs)]
        [b (mcs) (mediary-category-sys-object/c mcs)]
        [c (mcs) (mediary-category-sys-object/c mcs)]
        [ab (mcs a b) (mediary-category-sys-morphism/c mcs a b)]
        [bc (mcs b c) (mediary-category-sys-morphism/c mcs b c)])
      [_ (mcs a c) (mediary-category-sys-morphism/c mcs a c)])]
  [mediary-category-sys-morphism-atomicity-chain-two
    (->i
      (
        [mcs mediary-category-sys?]
        [a (mcs) (mediary-category-sys-object/c mcs)]
        [b (mcs) (mediary-category-sys-object/c mcs)]
        [c (mcs) (mediary-category-sys-object/c mcs)]
        [ab (mcs a b) (mediary-category-sys-morphism/c mcs a b)]
        [ab-atomicity category-morphism-atomicity?]
        [bc (mcs b c) (mediary-category-sys-morphism/c mcs b c)]
        [bc-atomicity category-morphism-atomicity?])
      [_ category-morphism-atomicity?])]
  [prop:mediary-category-sys
    (struct-type-property/c mediary-category-sys-impl?)]
  [make-mediary-category-sys-impl-from-chain-two
    (->
      (-> mediary-category-sys? mediary-set-sys?)
      (-> mediary-category-sys? mediary-set-sys?
        mediary-category-sys?)
      (->i ([mcs mediary-category-sys?])
        [_ (mcs)
          (->
            (mediary-category-sys-object/c mcs)
            (mediary-category-sys-object/c mcs)
            mediary-set-sys?)])
      (->i
        (
          [mcs mediary-category-sys?]
          [morphism-mediary-set-sys-family (mcs)
            (->
              (mediary-category-sys-object/c mcs)
              (mediary-category-sys-object/c mcs)
              mediary-set-sys?)])
        [_ mediary-category-sys?])
      (->i
        (
          [mcs mediary-category-sys?]
          [a (mcs) (mediary-category-sys-object/c mcs)]
          [b (mcs) (mediary-category-sys-object/c mcs)]
          [c (mcs) (mediary-category-sys-object/c mcs)]
          [ab (mcs a b) (mediary-category-sys-morphism/c mcs a b)]
          [bc (mcs b c) (mediary-category-sys-morphism/c mcs b c)])
        [_ (mcs a c) (mediary-category-sys-morphism/c mcs a c)])
      (->i
        (
          [mcs mediary-category-sys?]
          [a (mcs) (mediary-category-sys-object/c mcs)]
          [b (mcs) (mediary-category-sys-object/c mcs)]
          [c (mcs) (mediary-category-sys-object/c mcs)]
          [ab (mcs a b) (mediary-category-sys-morphism/c mcs a b)]
          [ab-atomicity category-morphism-atomicity?]
          [bc (mcs b c) (mediary-category-sys-morphism/c mcs b c)]
          [bc-atomicity category-morphism-atomicity?])
        [_ category-morphism-atomicity?])
      mediary-category-sys-impl?)])

(provide #/contract-out
  [category-sys? (-> any/c boolean?)]
  [category-sys-impl? (-> any/c boolean?)]
  [category-sys-object-set-sys (-> category-sys? set-sys?)]
  [category-sys-replace-object-set-sys
    (-> category-sys? set-sys? category-sys?)]
  [category-sys-object/c (-> category-sys? contract?)]
  [category-sys-object-replace-category-sys
    (->i
      (
        [cs category-sys?]
        [object (cs) (category-sys-object/c cs)]
        [new-cs category-sys?])
      [_ (new-cs) (swap/c #/category-sys-object/c new-cs)])]
  [category-sys-object-identity-morphism
    (->i ([cs category-sys?] [object (cs) (category-sys-object/c cs)])
      [_ (cs object) (category-sys-morphism/c cs object object)])]
  [category-sys-morphism-set-sys-family
    (->i ([cs category-sys?])
      [_ (cs)
        (-> (category-sys-object/c cs) (category-sys-object/c cs)
          set-sys?)])]
  [category-sys-replace-morphism-set-sys-family
    (->i
      (
        [cs category-sys?]
        [morphism-set-sys-family (cs)
          (-> (category-sys-object/c cs) (category-sys-object/c cs)
            set-sys?)])
      [_ category-sys?])]
  [category-sys-morphism/c
    (->i
      (
        [cs category-sys?]
        [s (cs) (category-sys-object/c cs)]
        [t (cs) (category-sys-object/c cs)])
      [_ contract?])]
  [category-sys-morphism-replace-category-sys
    (->i
      (
        [cs category-sys?]
        [s (cs) (category-sys-object/c cs)]
        [t (cs) (category-sys-object/c cs)]
        [morphism (cs s t) (category-sys-morphism/c cs s t)]
        [new-cs category-sys?])
      [_ (cs new-cs s t)
        (swap/c
          (category-sys-morphism/c new-cs
            (category-sys-object-replace-category-sys cs s new-cs)
            (category-sys-object-replace-category-sys
              cs t new-cs)))])]
  [category-sys-morphism-replace-source
    (->i
      (
        [cs category-sys?]
        [s (cs) (category-sys-object/c cs)]
        [t (cs) (category-sys-object/c cs)]
        [morphism (cs s t) (category-sys-morphism/c cs s t)]
        [new-s (cs) (category-sys-object/c cs)])
      [_ (cs new-s t) (swap/c #/category-sys-morphism/c cs new-s t)])]
  [category-sys-morphism-replace-target
    (->i
      (
        [cs category-sys?]
        [s (cs) (category-sys-object/c cs)]
        [t (cs) (category-sys-object/c cs)]
        [morphism (cs s t) (category-sys-morphism/c cs s t)]
        [new-t (cs) (category-sys-object/c cs)])
      [_ (cs s new-t) (swap/c #/category-sys-morphism/c cs s new-t)])]
  [category-sys-morphism-chain-two
    (->i
      (
        [cs category-sys?]
        [a (cs) (category-sys-object/c cs)]
        [b (cs) (category-sys-object/c cs)]
        [c (cs) (category-sys-object/c cs)]
        [ab (cs a b) (category-sys-morphism/c cs a b)]
        [bc (cs b c) (category-sys-morphism/c cs b c)])
      [_ (cs a c) (category-sys-morphism/c cs a c)])]
  [prop:category-sys (struct-type-property/c category-sys-impl?)]
  [make-category-sys-impl-from-chain-two
    (->
      (-> category-sys? set-sys?)
      (-> category-sys? set-sys? category-sys?)
      (->i
        (
          [cs category-sys?]
          [object (cs) (category-sys-object/c cs)]
          [new-cs category-sys?])
        [_ (new-cs) (swap/c #/category-sys-object/c new-cs)])
      (->i
        ([cs category-sys?] [object (cs) (category-sys-object/c cs)])
        [_ (cs object) (category-sys-morphism/c cs object object)])
      (->i ([cs category-sys?])
        [_ (cs)
          (-> (category-sys-object/c cs) (category-sys-object/c cs)
            set-sys?)])
      (->i
        (
          [cs category-sys?]
          [morphism-set-sys-family (cs)
            (-> (category-sys-object/c cs) (category-sys-object/c cs)
              set-sys?)])
        [_ category-sys?])
      (->i
        (
          [cs category-sys?]
          [s (cs) (category-sys-object/c cs)]
          [t (cs) (category-sys-object/c cs)]
          [morphism (cs s t) (category-sys-morphism/c cs s t)]
          [new-cs category-sys?])
        [_ (cs new-cs s t)
          (swap/c
            (category-sys-morphism/c new-cs
              (category-sys-object-replace-category-sys cs s new-cs)
              (category-sys-object-replace-category-sys
                cs t new-cs)))])
      (->i
        (
          [cs category-sys?]
          [s (cs) (category-sys-object/c cs)]
          [t (cs) (category-sys-object/c cs)]
          [morphism (cs s t) (category-sys-morphism/c cs s t)]
          [new-s (cs) (category-sys-object/c cs)])
        [_ (cs new-s t)
          (swap/c #/category-sys-morphism/c cs new-s t)])
      (->i
        (
          [cs category-sys?]
          [s (cs) (category-sys-object/c cs)]
          [t (cs) (category-sys-object/c cs)]
          [morphism (cs s t) (category-sys-morphism/c cs s t)]
          [new-t (cs) (category-sys-object/c cs)])
        [_ (cs s new-t)
          (swap/c #/category-sys-morphism/c cs s new-t)])
      (->i
        (
          [cs category-sys?]
          [a (cs) (category-sys-object/c cs)]
          [b (cs) (category-sys-object/c cs)]
          [c (cs) (category-sys-object/c cs)]
          [ab (cs a b) (category-sys-morphism/c cs a b)]
          [bc (cs b c) (category-sys-morphism/c cs b c)])
        [_ (cs a c) (category-sys-morphism/c cs a c)])
      category-sys-impl?)])

(provide #/contract-out
  [functor-sys? (-> any/c boolean?)]
  [functor-sys-impl? (-> any/c boolean?)]
  [functor-sys-source (-> functor-sys? category-sys?)]
  [functor-sys-replace-source
    (-> functor-sys? category-sys? functor-sys?)]
  [functor-sys-target (-> functor-sys? category-sys?)]
  [functor-sys-replace-target
    (-> functor-sys? category-sys? functor-sys?)]
  [functor-sys-apply-to-object
    (->i
      (
        [fs functor-sys?]
        [object (fs) (category-sys-object/c #/functor-sys-source fs)])
      [_ (fs) (category-sys-object/c #/functor-sys-target fs)])]
  [functor-sys-apply-to-morphism
    (->i
      (
        [fs functor-sys?]
        [s (fs) (category-sys-object/c #/functor-sys-source fs)]
        [t (fs) (category-sys-object/c #/functor-sys-source fs)]
        [morphism (fs s t)
          (category-sys-morphism/c (functor-sys-source fs) s t)])
      [_ (fs s t)
        (category-sys-object/c (functor-sys-target fs)
          (functor-sys-apply-to-object fs s)
          (functor-sys-apply-to-object fs t))])]
  [prop:functor-sys (struct-type-property/c functor-sys-impl?)]
  [make-functor-sys-impl-from-apply
    (->
      (-> functor-sys? category-sys?)
      (-> functor-sys? category-sys? functor-sys?)
      (-> functor-sys? category-sys?)
      (-> functor-sys? category-sys? functor-sys?)
      (->i
        (
          [fs functor-sys?]
          [object (fs)
            (category-sys-object/c #/functor-sys-source fs)])
        [_ (fs) (category-sys-object/c #/functor-sys-target fs)])
      (->i
        (
          [fs functor-sys?]
          [s (fs) (category-sys-object/c #/functor-sys-source fs)]
          [t (fs) (category-sys-object/c #/functor-sys-source fs)]
          [morphism (fs s t)
            (category-sys-morphism/c (functor-sys-source fs) s t)])
        [_ (fs s t)
          (category-sys-morphism/c (functor-sys-target fs)
            (functor-sys-apply-to-object fs s)
            (functor-sys-apply-to-object fs t))])
      functor-sys-impl?)]
  [functor-sys/c (-> contract? contract? contract?)]
  [makeshift-functor-sys
    (->i
      (
        [s category-sys?]
        [t category-sys?]
        [apply-to-object (s t)
          (-> (category-sys-object/c s) (category-sys-object/c t))]
        [apply-to-morphism (s t apply-to-object)
          (->i
            (
              [a (category-sys-object/c s)]
              [b (category-sys-object/c s)]
              [ab (a b) (category-sys-morphism/c s a b)])
            [_ (a b)
              (category-sys-morphism/c t
                (apply-to-object a)
                (apply-to-object b))])])
      [_ (s t) (functor-sys/c (accepts/c s) (accepts/c t))])]
  [functor-sys-identity
    (->i ([endpoint category-sys?])
      [_ (endpoint)
        (functor-sys/c (accepts/c endpoint) (accepts/c endpoint))])]
  [functor-sys-chain-two
    (->i
      (
        [ab functor-sys?]
        [bc (ab)
          (functor-sys/c (accepts/c #/functor-sys-target ab) any/c)])
      [_ (ab bc)
        (functor-sys/c
          (accepts/c #/functor-sys-source ab)
          (accepts/c #/functor-sys-target bc))])])

(provide #/contract-out
  [natural-transformation-sys? (-> any/c boolean?)]
  [natural-transformation-sys-impl? (-> any/c boolean?)]
  [natural-transformation-sys-endpoint-source
    (-> natural-transformation-sys? category-sys?)]
  [natural-transformation-sys-replace-endpoint-source
    (-> natural-transformation-sys? category-sys?
      natural-transformation-sys?)]
  [natural-transformation-sys-endpoint-target
    (-> natural-transformation-sys? category-sys?)]
  [natural-transformation-sys-replace-endpoint-target
    (-> natural-transformation-sys? category-sys?
      natural-transformation-sys?)]
  [natural-transformation-sys-endpoint/c
    (-> natural-transformation-sys? contract?)]
  [natural-transformation-sys-source
    (->i ([nts natural-transformation-sys?])
      [_ (nts) (natural-transformation-sys-endpoint/c nts)])]
  [natural-transformation-sys-replace-source
    (->i
      (
        [nts natural-transformation-sys?]
        [s (nts) (natural-transformation-sys-endpoint/c nts)])
      [_ natural-transformation-sys?])]
  [natural-transformation-sys-target
    (->i ([nts natural-transformation-sys?])
      [_ (nts) (natural-transformation-sys-endpoint/c nts)])]
  [natural-transformation-sys-replace-target
    (->i
      (
        [nts natural-transformation-sys?]
        [s (nts) (natural-transformation-sys-endpoint/c nts)])
      [_ natural-transformation-sys?])]
  [natural-transformation-sys-apply-to-object
    (->i
      (
        [nts natural-transformation-sys?]
        [object (nts)
          (category-sys-object/c
            (natural-transformation-sys-endpoint-source nts))])
      [_ (nts object)
        (category-sys-morphism/c
          (natural-transformation-sys-endpoint-target nts)
          (functor-sys-apply-to-object
            (natural-transformation-sys-source nts)
            object)
          (functor-sys-apply-to-object
            (natural-transformation-sys-target nts)
            object))])]
  [prop:natural-transformation-sys
    (struct-type-property/c natural-transformation-sys-impl?)]
  [make-natural-transformation-sys-impl-from-apply
    (->
      (-> natural-transformation-sys? category-sys?)
      (-> natural-transformation-sys? category-sys?
        natural-transformation-sys?)
      (-> natural-transformation-sys? category-sys?)
      (-> natural-transformation-sys? category-sys?
        natural-transformation-sys?)
      (-> natural-transformation-sys? functor-sys?)
      (-> natural-transformation-sys? functor-sys?
        natural-transformation-sys?)
      (-> natural-transformation-sys? functor-sys?)
      (-> natural-transformation-sys? functor-sys?
        natural-transformation-sys?)
      (->i
        (
          [nts natural-transformation-sys?]
          [object (nts)
            (category-sys-object/c
              (natural-transformation-sys-endpoint-source nts))])
        [_ (nts object)
          (category-sys-morphism/c
            (natural-transformation-sys-endpoint-target nts)
            (functor-sys-apply-to-object
              (natural-transformation-sys-source nts)
              object)
            (functor-sys-apply-to-object
              (natural-transformation-sys-target nts)
              object))])
      natural-transformation-sys-impl?)]
  [natural-transformation-sys/c
    (-> contract? contract? contract? contract? contract?)]
  [makeshift-natural-transformation-sys
    (->i
      (
        [es category-sys?]
        [et category-sys?]
        [s (es et) (functor-sys/c (accepts/c es) (accepts/c et))]
        [t (es et) (functor-sys/c (accepts/c es) (accepts/c et))]
        [apply-to-object (es et s t)
          (->i ([object (category-sys-object/c es)])
            [_ (object)
              (category-sys-morphism/c et
                (functor-sys-apply-to-object s object)
                (functor-sys-apply-to-object t object))])])
      [_ (es et s t)
        (natural-transformation-sys/c
          (accepts/c es)
          (accepts/c et)
          (accepts/c s)
          (accepts/c t))])]
  [natural-transformation-sys-identity
    (->i ([endpoint functor-sys?])
      [_ (endpoint)
        (natural-transformation-sys/c
          (accepts/c #/functor-sys-source endpoint)
          (accepts/c #/functor-sys-target endpoint)
          (accepts/c endpoint)
          (accepts/c endpoint))])]
  ; TODO: Implement a `natural-transformation-sys-chain-two-along-end`
  ; operation for horizontal composition. See if we can implement it
  ; in a generic enough way that it's part of
  ; `define-makeshift-2-cell`.
  [natural-transformation-sys-chain-two
    (->i
      (
        [ab natural-transformation-sys?]
        [bc (ab)
          (natural-transformation-sys/c
            (accepts/c
              (natural-transformation-sys-endpoint-source ab))
            (accepts/c
              (natural-transformation-sys-endpoint-target ab))
            (accepts/c #/natural-transformation-sys-target ab)
            any/c)])
      [_ (ab bc)
        (natural-transformation-sys/c
          (accepts/c #/natural-transformation-sys-endpoint-source ab)
          (accepts/c #/natural-transformation-sys-endpoint-target ab)
          (accepts/c #/natural-transformation-sys-source ab)
          (accepts/c #/natural-transformation-sys-target bc))])])


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

; NOTE:
;
; The main point of the "sys" suffix is to distinguish, for instance,
; a system (or theory or dictionary or algebra) of monad operations
; from a value that is a single monadic container, or a system of
; number operations from a value that is a single number.
;
; From that beginning point, we've applied the "sys" suffix to quite a
; few more things. While this could be unnecessary noise, it does
; serve some purposes.
;
; The name `atomic-set-element-sys?` (along with its peers
; `atomic-category-object-sys?` and `atomic-category-morphism-sys?`)
; in particular seems like a poor fit for the "sys" suffix since we'll
; often implement this interface on values that really represent some
; other "sys" and only implement the `atomic-set-element-sys?`
; interface on the side for the sake of error detection. However, we
; keep the "sys" suffix in this case because it serves as a way to
; distinguish `atomic-set-element-sys-accepts/c` (a method on
; `atomic-set-element-sys?` values) from `set-sys-element-accepts/c`
; (a method on `set-sys?` values). When we're modeling data structures
; like "category" that contain associated types like "object" and
; "morphism," there's a risk that our very explicit method names would
; have too many nouns in a row, and "sys" can fill the role of a
; punctuation or stress mark.
;
; With a few systems like `function-sys?` (and its peers
; `functor-sys?` and `natural-transformation-sys?`), the system itself
; *is* the function (albeit perhaps with some extra pizzazz like
; `...-replace-source` for error-detection and debugging purposes). In
; particular, there's no other type involved whose values could be
; confused for "functions" the way that a monadic container value
; might be confused for a "monad." Nevertheless, the name `function?`
; would be somewhat confusing name for a new type in in the context of
; Racket, where functions are an established built-in type. The name
; `function-sys?` seems sufficiently distinct while at the same time
; aligning better with the naming conventions going on around it. In
; particular, `function-sys?` is a homomorphism between two `set-sys?`
; theories, and in general, a homomorphism will "has-a" an associated
; homomorphism in the same place where the endpoint theory "has-a" an
; associated theory. By using "sys" in the names of the homomorphisms
; just like we use it on the names of the theories they go between, we
; allow the operations that look up those associated parts to have
; names that are analogous with each other.

; TODO: Split this file into a few different files:
;
; We should probably have these separate modules, at least in public,
; perhaps with corresponding private modules for implementation:
;
;   lathe-morphisms/lawless/set (since it's a common base case)
;   lathe-morphisms/lawless/digraph
;   lathe-morphisms/lawless/category
;   lathe-morphisms/lawless/mediary/set
;   lathe-morphisms/lawless/mediary/digraph
;   lathe-morphisms/lawless/mediary/category
;
; Here, the "mediary" directory is like a "generalized sublibrary" or
; "specialized sublibrary" (as discussed in README.md), since they're
; a pretty unusual experiment that involves defining variants of most
; of the other abstractions. Nevertheless, we should keep the
; `mediary-...` prefix on the names of those systems, since it signals
; the fact that an important part of the system resides in the
; corresponding `atomic-...` and `...-atomicity` types.
;
; Note that since mediary categories are awfully complicated (and
; could easily be a broken or unstable design), and this complexity is
; not likely to help illuminate category theory ideas (nor functional
; programming ideas), we don't use `mediary-category-sys?` in the
; representation of `category-sys?`. People who use `category-sys?`
; generally shouldn't have to think about `mediary-category-sys?`.
;
; If we decide to extrapolate these things to arbitrarily higher
; dimensions, we should probably start an "n-dimensional" or
; "globular" generalized sublibrary for that.

; TODO: Implement the following contract combinators:
;
;   (mediary-digraph-sys/c
;     node-mediary-set-sys/c edge-mediary-set-sys-family/c)
;   (mediary-category-sys/c
;     object-mediary-set-sys/c morphism-mediary-set-sys-family/c)
;   (category-sys/c object-set-sys/c morphism-set-sys-family/c)
;
; These contract combinators fit a pattern that could be abstracted.


(define
  (make-morphism/c
    morphism-sys/c-name
    morphism-sys?
    morphism-sys-source
    morphism-sys-replace-source
    morphism-sys-target
    morphism-sys-replace-target)
  (fn source/c target/c
    (w- source/c (coerce-contract morphism-sys/c-name source/c)
    #/w- target/c (coerce-contract morphism-sys/c-name target/c)
    #/w- name
      `(morphism-sys/c-name
        ,(contract-name source/c)
        ,(contract-name target/c))
    #/w- source/c-late-neg-projection
      (get/build-late-neg-projection source/c)
    #/w- target/c-late-neg-projection
      (get/build-late-neg-projection target/c)
    #/make-contract #:name name
      
      #:first-order
      (fn v
        (and
          (morphism-sys? v)
          (contract-first-order-passes? source/c
            (morphism-sys-source v))
          (contract-first-order-passes? target/c
            (morphism-sys-target v))))
      
      #:late-neg-projection
      (fn blame
        (w- source/c-projection
          (source/c-late-neg-projection
            (blame-add-context blame "source of"))
        #/w- target/c-projection
          (target/c-late-neg-projection
            (blame-add-context blame "target of"))
        #/fn v missing-party
          (w- v
            (morphism-sys-replace-source v
              (source/c-projection (morphism-sys-source v)
                missing-party))
          #/w- v
            (morphism-sys-replace-target v
              (target/c-projection (morphism-sys-target v)
                missing-party))
            v))))))

(define
  (make-2-cell/c
    cell-sys/c-name
    cell-sys?
    cell-sys-endpoint-source
    cell-sys-replace-endpoint-source
    cell-sys-endpoint-target
    cell-sys-replace-endpoint-target
    cell-sys-source
    cell-sys-replace-source
    cell-sys-target
    cell-sys-replace-target)
  (fn endpoint-source/c endpoint-target/c source/c target/c
    (w- endpoint-source/c
      (coerce-contract cell-sys/c-name endpoint-source/c)
    #/w- endpoint-target/c
      (coerce-contract cell-sys/c-name endpoint-target/c)
    #/w- source/c (coerce-contract cell-sys/c-name source/c)
    #/w- target/c (coerce-contract cell-sys/c-name target/c)
    #/w- name
      `(cell-sys/c-name
        ,(contract-name endpoint-source/c)
        ,(contract-name endpoint-target/c)
        ,(contract-name source/c)
        ,(contract-name target/c))
    #/w- endpoint-source/c-late-neg-projection
      (get/build-late-neg-projection endpoint-source/c)
    #/w- endpoint-target/c-late-neg-projection
      (get/build-late-neg-projection endpoint-target/c)
    #/w- source/c-late-neg-projection
      (get/build-late-neg-projection source/c)
    #/w- target/c-late-neg-projection
      (get/build-late-neg-projection target/c)
    #/make-contract #:name name
      
      #:first-order
      (fn v
        (and
          (cell-sys? v)
          (contract-first-order-passes? endpoint-source/c
            (cell-sys-endpoint-source v))
          (contract-first-order-passes? endpoint-target/c
            (cell-sys-endpoint-target v))
          (contract-first-order-passes? source/c
            (cell-sys-source v))
          (contract-first-order-passes? target/c
            (cell-sys-target v))))
      
      #:late-neg-projection
      (fn blame
        (w- endpoint-source/c-projection
          (endpoint-source/c-late-neg-projection
            (blame-add-context blame "endpoint source of"))
        #/w- endpoint-target/c-projection
          (endpoint-target/c-late-neg-projection
            (blame-add-context blame "endpoint target of"))
        #/w- source/c-projection
          (source/c-late-neg-projection
            (blame-add-context blame "source of"))
        #/w- target/c-projection
          (target/c-late-neg-projection
            (blame-add-context blame "target of"))
        #/fn v missing-party
          (w- v
            (cell-sys-replace-endpoint-source v
              (endpoint-source/c-projection
                (cell-sys-endpoint-source v)
                missing-party))
          #/w- v
            (cell-sys-replace-endpoint-target v
              (endpoint-target/c-projection
                (cell-sys-endpoint-target v)
                missing-party))
          #/w- v
            (cell-sys-replace-source v
              (source/c-projection (cell-sys-source v)
                missing-party))
          #/w- v
            (cell-sys-replace-target v
              (target/c-projection (cell-sys-target v)
                missing-party))
            v))))))


(define-simple-macro
  (define-makeshift-morphism
    makeshift-morphism-sys:id
    morphism-sys-identity:id
    morphism-sys-chain-two:id
    makeshift-morphism-sys-name
    prop-morphism-sys
    make-morphism-sys-impl-from-apply
    morphism-sys-source
    morphism-sys-target
    morphism-sys-apply-to-cell
    ...)
  
  #:declare makeshift-morphism-sys-name
  (expr/c #'symbol? #:name "struct name")
  
  #:declare prop-morphism-sys
  (expr/c #'struct-type-property? #:name "structure type property")
  
  #:declare make-morphism-sys-impl-from-apply
  (expr/c
    ; TODO: See if we can use the more accurate contract somehow. For
    ; now, it's commented out.
    #'procedure?
    #;
    #`(->
        (-> any/c any/c)
        (-> any/c any/c any/c)
        (-> any/c any/c)
        (-> any/c any/c any/c)
        #,@(for/list
              (
                [a
                  (in-list
                    (syntax->list
                      #'(morphism-sys-apply-to-cell ...)))])
              #'(-> any/c any/c any/c))
        any/c)
    #:name "structure type property implementation constructor")
  
  #:declare morphism-sys-source
  (expr/c #'(-> any/c any/c) #:name "source accessor")
  
  #:declare morphism-sys-target
  (expr/c #'(-> any/c any/c) #:name "target accessor")
  
  #:declare morphism-sys-apply-to-cell
  (expr/c #'(unconstrained-domain-> any/c)
    #:name "an application behavior function")
  
  #:with (a ...)
  (generate-temporaries #'(morphism-sys-apply-to-cell ...))
  
  #:with (contracted-morphism-sys-apply-to-cell ...)
  (generate-temporaries #'(a ...))
  
  #:with (makeshift-morphism-sys-apply-to-cell ...)
  (generate-temporaries #'(a ...))
  
  #:with (identity ...)
  (for/list ([arg/c (in-list (syntax->list #'(a ...)))])
    #'(lambda endpoints-and-cell
        (dissect (reverse endpoints-and-cell)
          (cons cell rev-endpoints)
          cell)))
  
  (begin
    (define contracted-makeshift-morphism-sys-name
      makeshift-morphism-sys-name.c)
    (define contracted-prop-morphism-sys prop-morphism-sys.c)
    (define contracted-make-morphism-sys-impl-from-apply
      make-morphism-sys-impl-from-apply.c)
    (define contracted-morphism-sys-source morphism-sys-source.c)
    (define contracted-morphism-sys-target morphism-sys-target.c)
    (define contracted-morphism-sys-apply-to-cell
      morphism-sys-apply-to-cell.c)
    ...
    (define-imitation-simple-struct
      (makeshift-morphism-sys?
        makeshift-morphism-sys-source
        makeshift-morphism-sys-target
        makeshift-morphism-sys-apply-to-cell
        ...)
      unguarded-makeshift-morphism-sys
      contracted-makeshift-morphism-sys-name (current-inspector)
      (#:prop contracted-prop-morphism-sys
        (contracted-make-morphism-sys-impl-from-apply
          ; morphism-sys-source
          (dissectfn (unguarded-makeshift-morphism-sys s t a ...) s)
          ; morphism-sys-replace-source
          (fn ms new-s
            (dissect ms (unguarded-makeshift-morphism-sys s t a ...)
            #/unguarded-makeshift-morphism-sys new-s t a ...))
          ; morphism-sys-target
          (dissectfn (unguarded-makeshift-morphism-sys s t a ...) t)
          ; morphism-sys-replace-target
          (fn ms new-t
            (dissect ms (unguarded-makeshift-morphism-sys s t a ...)
            #/unguarded-makeshift-morphism-sys s new-t a ...))
          ; morphism-sys-apply-to-cell
          (fn ms cell
            ( (makeshift-morphism-sys-apply-to-cell ms) cell))
          ...)))
    (define (makeshift-morphism-sys s t a ...)
      (unguarded-makeshift-morphism-sys s t a ...))
    (define (morphism-sys-identity endpoint)
      (makeshift-morphism-sys endpoint endpoint identity ...))
    (define (morphism-sys-chain-two ab bc)
      (makeshift-morphism-sys
        (contracted-morphism-sys-source ab)
        (contracted-morphism-sys-target bc)
        (lambda endpoints-and-cell
          (dissect (reverse endpoints-and-cell)
            (cons cell rev-endpoints)
          #/w- endpoints (reverse rev-endpoints)
          #/apply contracted-morphism-sys-apply-to-cell bc
            (append endpoints
              (apply contracted-morphism-sys-apply-to-cell ab
                endpoints-and-cell))))
        ...))))

(define-simple-macro
  (define-makeshift-2-cell
    makeshift-cell-sys:id
    cell-sys-identity:id
    cell-sys-chain-two:id
    makeshift-cell-sys-name
    prop-cell-sys
    make-cell-sys-impl-from-apply
    endpoint-replace-source
    endpoint-replace-target
    cell-sys-endpoint-source
    cell-sys-endpoint-target
    cell-sys-source
    cell-sys-target
    cell-sys-apply-to-face
    ...)
  
  #:declare makeshift-cell-sys-name
  (expr/c #'symbol? #:name "struct name")
  
  #:declare prop-cell-sys
  (expr/c #'struct-type-property? #:name "structure type property")
  
  #:declare make-cell-sys-impl-from-apply
  (expr/c
    ; TODO: See if we can use the more accurate contract somehow. For
    ; now, it's commented out.
    #'procedure?
    #;
    #`(->
        (-> any/c any/c)
        (-> any/c any/c any/c)
        (-> any/c any/c)
        (-> any/c any/c any/c)
        #,@(for/list
              (
                [a
                  (in-list
                    (syntax->list #'(cell-sys-apply-to-face ...)))])
              #'(-> any/c any/c any/c))
        any/c)
    #:name "structure type property implementation constructor")
  
  #:declare endpoint-replace-source
  (expr/c #'(-> any/c any/c any/c)
    #:name "endpoint system's source replacer")
  
  #:declare endpoint-replace-target
  (expr/c #'(-> any/c any/c any/c)
    #:name "endpoint system's target replacer")
  
  #:declare cell-sys-endpoint-source
  (expr/c #'(-> any/c any/c) #:name "endpoint source accessor")
  
  #:declare cell-sys-endpoint-target
  (expr/c #'(-> any/c any/c) #:name "endpoint target accessor")
  
  #:declare cell-sys-source
  (expr/c #'(-> any/c any/c) #:name "source accessor")
  
  #:declare cell-sys-target
  (expr/c #'(-> any/c any/c) #:name "target accessor")
  
  #:declare cell-sys-apply-to-face
  (expr/c #'(unconstrained-domain-> any/c)
    #:name "an application behavior function")
  
  #:with (a ...) (generate-temporaries #'(cell-sys-apply-to-face ...))
  
  #:with (contracted-cell-sys-apply-to-face ...)
  (generate-temporaries #'(a ...))
  
  #:with (makeshift-cell-sys-apply-to-face ...)
  (generate-temporaries #'(a ...))
  
  #:with (identity ...)
  (for/list ([arg/c (in-list (syntax->list #'(a ...)))])
    #'(lambda endpoints-and-cell
        (dissect (reverse endpoints-and-cell)
          (cons cell rev-endpoints)
          cell)))
  
  (begin
    (define contracted-makeshift-cell-sys-name
      makeshift-cell-sys-name.c)
    (define contracted-prop-cell-sys prop-cell-sys.c)
    (define contracted-make-cell-sys-impl-from-apply
      make-cell-sys-impl-from-apply.c)
    (define contracted-endpoint-replace-source
      endpoint-replace-source.c)
    (define contracted-endpoint-replace-target
      endpoint-replace-target.c)
    (define contracted-cell-sys-endpoint-source
      cell-sys-endpoint-source.c)
    (define contracted-cell-sys-endpoint-target
      cell-sys-endpoint-target.c)
    (define contracted-cell-sys-source cell-sys-source.c)
    (define contracted-cell-sys-target cell-sys-target.c)
    (define contracted-cell-sys-apply-to-face
      cell-sys-apply-to-face.c)
    ...
    (define-imitation-simple-struct
      (makeshift-cell-sys?
        makeshift-cell-sys-endpoint-source
        makeshift-cell-sys-endpoint-target
        makeshift-cell-sys-source
        makeshift-cell-sys-target
        makeshift-cell-sys-apply-to-face
        ...)
      unguarded-makeshift-cell-sys
      contracted-makeshift-cell-sys-name (current-inspector)
      (#:prop contracted-prop-cell-sys
        (contracted-make-cell-sys-impl-from-apply
          ; cell-sys-endpoint-source
          (dissectfn (unguarded-makeshift-cell-sys es et s t a ...)
            es)
          ; cell-sys-replace-endpoint-source
          (fn ms new-es
            (dissect ms (unguarded-makeshift-cell-sys es et s t a ...)
            #/unguarded-makeshift-cell-sys new-es et
              (contracted-endpoint-replace-source s new-es)
              (contracted-endpoint-replace-source t new-es)
              a
              ...))
          ; cell-sys-endpoint-target
          (dissectfn (unguarded-makeshift-cell-sys es et s t a ...)
            et)
          ; cell-sys-replace-endpoint-target
          (fn ms new-et
            (dissect ms (unguarded-makeshift-cell-sys es et s t a ...)
            #/unguarded-makeshift-cell-sys es new-et
              (contracted-endpoint-replace-target s new-et)
              (contracted-endpoint-replace-target t new-et)
              a
              ...))
          ; cell-sys-source
          (dissectfn (unguarded-makeshift-cell-sys es et s t a ...) s)
          ; cell-sys-replace-source
          (fn ms new-s
            (dissect ms (unguarded-makeshift-cell-sys es et s t a ...)
            #/unguarded-makeshift-cell-sys es et new-s t a ...))
          ; cell-sys-target
          (dissectfn (unguarded-makeshift-cell-sys es et s t a ...) t)
          ; cell-sys-replace-target
          (fn ms new-t
            (dissect ms (unguarded-makeshift-cell-sys es et s t a ...)
            #/unguarded-makeshift-cell-sys es et s new-t a ...))
          ; cell-sys-apply-to-face
          (fn ms cell
            ( (makeshift-cell-sys-apply-to-face ms) cell))
          ...)))
    (define (makeshift-cell-sys es et s t a ...)
      (unguarded-makeshift-cell-sys es et s t a ...))
    (define (cell-sys-identity endpoint)
      (makeshift-cell-sys endpoint endpoint identity ...))
    (define (cell-sys-chain-two ab bc)
      (makeshift-cell-sys
        (contracted-cell-sys-endpoint-source ab)
        (contracted-cell-sys-endpoint-target ab)
        (contracted-cell-sys-source ab)
        (contracted-cell-sys-target bc)
        (lambda endpoints-and-cell
          (dissect (reverse endpoints-and-cell)
            (cons cell rev-endpoints)
          #/w- endpoints (reverse rev-endpoints)
          #/apply contracted-cell-sys-apply-to-face bc
            (append endpoints
              (apply contracted-cell-sys-apply-to-face ab
                endpoints-and-cell))))
        ...))))


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

(define (accepts/c v)
  (if (atomic-set-element-sys? v)
    (atomic-set-element-sys-accepts/c v)
    any/c))

(define-imitation-simple-generics
  set-sys? set-sys-impl?
  (#:method set-sys-element/c (#:this))
  (#:method set-sys-element-accepts/c (#:this) ())
  (#:method set-sys-element-replace-set-sys (#:this) () ())
  prop:set-sys make-set-sys-impl-from-contract
  'set-sys 'set-sys-impl (list))

; TODO: See if we should have functions between mediary sets too, i.e.
; `mediary-function-sys?`.
(define-imitation-simple-generics
  function-sys? function-sys-impl?
  (#:method function-sys-source (#:this))
  (#:method function-sys-replace-source (#:this) ())
  (#:method function-sys-target (#:this))
  (#:method function-sys-replace-target (#:this) ())
  (#:method function-sys-apply-to-element (#:this) ())
  prop:function-sys make-function-sys-impl-from-apply
  'function-sys 'function-sys-impl (list))

(define function-sys/c
  (make-morphism/c
    'function-sys/c
    function-sys?
    function-sys-source
    function-sys-replace-source
    function-sys-target
    function-sys-replace-target))

(define-makeshift-morphism
  makeshift-function-sys
  function-sys-identity
  function-sys-chain-two
  'makeshift-function-sys
  prop:function-sys
  make-function-sys-impl-from-apply
  function-sys-source
  function-sys-target
  function-sys-apply-to-element)

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
  make-mediary-digraph-sys-impl-from-mediary-set-systems
  'mediary-digraph-sys 'mediary-digraph-sys-impl (list))

(define (mediary-digraph-sys-node/c mcs)
  (mediary-set-sys-element/c
    (mediary-digraph-sys-node-mediary-set-sys mcs)))

(define (mediary-digraph-sys-edge/c mcs s t)
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
  make-atomic-category-morphism-sys-impl-from-atomicity
  'atomic-category-morphism-sys 'atomic-category-morphism-sys-impl
  (list))

(define (atomic-category-morphism-sys-accepts/c ms)
  (
    (category-morphism-atomicity-accepts/c
      (atomic-category-morphism-sys-atomicity ms))
    ms))

(define (atomic-category-morphism-sys-replace-category-sys ms cs)
  (
    (category-morphism-atomicity-replace-category-sys
      (atomic-category-morphism-sys-atomicity ms))
    ms
    cs))

(define (atomic-category-morphism-sys-replace-source ms s)
  (
    (category-morphism-atomicity-replace-source
      (atomic-category-morphism-sys-atomicity ms))
    ms
    s))

(define (atomic-category-morphism-sys-replace-target ms t)
  (
    (category-morphism-atomicity-replace-target
      (atomic-category-morphism-sys-atomicity ms))
    ms
    t))

(define atomic-category-morphism-sys/c
  (make-morphism/c
    'atomic-category-morphism-sys/c
    atomic-category-morphism-sys?
    atomic-category-morphism-sys-source
    atomic-category-morphism-sys-replace-source
    atomic-category-morphism-sys-target
    atomic-category-morphism-sys-replace-target))

; NOTE:
;
; We don't use `define-makeshift-morphism` to make any
; `atomic-category-morphism-sys?` operations. Atomic category
; morphisms don't have innate composition operations, just the ones
; provided by their category, and there isn't a particular reason to
; create anonymous atomic category morphisms either.
;
; Anonymous atomic category morphisms could make a little bit of
; sense, being simply a pair of a source and a target with no other
; meaningful operations. However, even if we wanted to define an
; operation to make those pairs, `define-makeshift-morphism` wouldn't
; help; it's specialized to a particular property implementation
; constructor signature format where source and target accessors and
; replacers come first, and
; `make-atomic-category-morphism-sys-impl-from-atomicity` isn't a
; property implementation constructor with that signature format. We
; would simply have to define it without the help of the
; `define-makeshift-morphism` abstraction.


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
  (#:method category-sys-morphism-chain-two (#:this) () () () () ())
  prop:category-sys make-category-sys-impl-from-chain-two
  'category-sys 'category-sys-impl (list))

(define (category-sys-object/c cs)
  (set-sys-element/c #/category-sys-object-set-sys cs))

(define (category-sys-morphism/c cs s t)
  (set-sys-element/c
    ( (category-sys-morphism-set-sys-family cs) s t)))

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

(define functor-sys/c
  (make-morphism/c
    'functor-sys/c
    functor-sys?
    functor-sys-source
    functor-sys-replace-source
    functor-sys-target
    functor-sys-replace-target))

(define-makeshift-morphism
  makeshift-functor-sys
  functor-sys-identity
  functor-sys-chain-two
  'makeshift-functor-sys
  prop:functor-sys
  make-functor-sys-impl-from-apply
  functor-sys-source
  functor-sys-target
  functor-sys-apply-to-object
  functor-sys-apply-to-morphism)

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

(define (natural-transformation-sys-endpoint/c nts)
  (rename-contract
    (functor-sys/c
      (accepts/c #/natural-transformation-sys-endpoint-source nts)
      (accepts/c #/natural-transformation-sys-endpoint-source nts))
    `(natural-transformation-sys-endpoint/c ,nts)))

(define natural-transformation-sys/c
  (make-2-cell/c
    'natural-transformation-sys/c
    natural-transformation-sys?
    natural-transformation-sys-endpoint-source
    natural-transformation-sys-replace-endpoint-source
    natural-transformation-sys-endpoint-target
    natural-transformation-sys-replace-endpoint-target
    natural-transformation-sys-source
    natural-transformation-sys-replace-source
    natural-transformation-sys-target
    natural-transformation-sys-replace-target))

(define-makeshift-2-cell
  makeshift-natural-transformation-sys
  natural-transformation-sys-identity
  natural-transformation-sys-chain-two
  'makeshift-natural-transformation-sys
  prop:natural-transformation-sys
  make-natural-transformation-sys-impl-from-apply
  functor-sys-replace-source
  functor-sys-replace-target
  natural-transformation-sys-endpoint-source
  natural-transformation-sys-endpoint-target
  natural-transformation-sys-source
  natural-transformation-sys-target
  natural-transformation-sys-apply-to-object)
