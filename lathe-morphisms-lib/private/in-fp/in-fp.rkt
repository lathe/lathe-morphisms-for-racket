#lang parendown racket/base

; in-fp.rkt
;
; Interfaces for category theory concepts where none of the laws are
; represented computationally. Nevertheless, we do go to some lengths
; to ensure these interfaces carry enough information to write
; informative contracts.

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
  -> ->i and/c any/c contract? contract-name contract-out
  flat-contract? list/c rename-contract unconstrained-domain->)
(require #/only-in racket/contract/combinator
  blame-add-context coerce-contract contract-first-order-passes?
  make-contract make-flat-contract)
(require #/only-in racket/contract/region define/contract)
(require #/only-in syntax/parse/define
  define-simple-macro)

(require #/only-in lathe-comforts dissect dissectfn fn w-)
(require #/only-in lathe-comforts/contract
  by-own-method/c flat-contract-accepting/c value-name-for-contract)
(require #/only-in lathe-comforts/match
  define-match-expander-attenuated
  define-match-expander-from-match-and-make match/c)
(require #/only-in lathe-comforts/struct
  auto-equal auto-write define-imitation-simple-generics
  define-imitation-simple-struct)


(provide
  set-element-good-behavior)
(provide #/contract-out
  [set-element-good-behavior? (-> any/c boolean?)]
  [set-element-good-behavior-getter-of-value
    (-> set-element-good-behavior? (-> any/c))]
  [set-element-good-behavior-value
    (-> set-element-good-behavior? any/c)]
  [set-element-good-behavior-getter-of-accepts/c
    (->i ([element set-element-good-behavior?])
      [_ (element)
        (->
          (flat-contract-accepting/c
            (set-element-good-behavior-value element)))])]
  [set-element-good-behavior-with-value/c (-> contract? contract?)]
  [set-element-good-behavior-for-mediary-set-sys/c
    (-> mediary-set-sys? contract?)])

(provide #/contract-out
  [atomic-set-element-sys? (-> any/c boolean?)]
  [atomic-set-element-sys-impl? (-> any/c boolean?)]
  [prop:atomic-set-element-sys
    (struct-type-property/c atomic-set-element-sys-impl?)]
  [atomic-set-element-sys-good-behavior
    (-> atomic-set-element-sys? set-element-good-behavior?)]
  [atomic-set-element-sys-accepts/c
    (->i ([element atomic-set-element-sys?])
      [_ (element) (flat-contract-accepting/c element)])]
  [make-atomic-set-element-sys-impl-from-good-behavior
    (-> (-> atomic-set-element-sys? set-element-good-behavior?)
      atomic-set-element-sys-impl?)]
  [make-atomic-set-element-sys-impl-from-contract
    (->
      (->i ([element atomic-set-element-sys?])
        [_ (element) (flat-contract-accepting/c element)])
      atomic-set-element-sys-impl?)])

(provide #/contract-out
  [mediary-set-sys? (-> any/c boolean?)]
  [mediary-set-sys-impl? (-> any/c boolean?)]
  [prop:mediary-set-sys
    (struct-type-property/c mediary-set-sys-impl?)]
  [mediary-set-sys-element/c (-> mediary-set-sys? contract?)]
  [make-mediary-set-sys-impl-from-contract
    (-> (-> mediary-set-sys? contract?) mediary-set-sys-impl?)])

(provide #/contract-out
  [ok/c
    (->i ([example any/c])
      [_ (example) (flat-contract-accepting/c example)])])

(provide #/contract-out
  [set-sys? (-> any/c boolean?)]
  [set-sys-impl? (-> any/c boolean?)]
  [prop:set-sys (struct-type-property/c set-sys-impl?)]
  [set-sys-element/c (-> set-sys? contract?)]
  [set-sys-element-accepts/c
    (->i ([ss set-sys?] [element (ss) (set-sys-element/c ss)])
      [_ (element) (flat-contract-accepting/c element)])]
  [make-set-sys-impl-from-contract
    (->
      (-> set-sys? contract?)
      (->i ([ss set-sys?] [element (ss) (set-sys-element/c ss)])
        [_ (element) (flat-contract-accepting/c element)])
      set-sys-impl?)]
  [makeshift-set-sys-from-contract
    (->i
      (
        [element/c (-> contract?)]
        [element-accepts/c (element/c)
          (->i ([_element (element/c)])
            [_ (_element) (flat-contract-accepting/c _element)])])
      [_ set-sys?])])

; TODO: Export these from `lathe-morphisms/in-fp/set` once we need
; them.
(provide #/contract-out
  [function-sys? (-> any/c boolean?)]
  [function-sys-impl? (-> any/c boolean?)]
  [prop:function-sys (struct-type-property/c function-sys-impl?)]
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
      [_ (s t) (function-sys/c (ok/c s) (ok/c t))])]
  [function-sys-identity
    (->i ([endpoint set-sys?])
      [_ (endpoint)
        (function-sys/c (ok/c endpoint) (ok/c endpoint))])]
  [function-sys-chain-two
    (->i
      (
        [ab function-sys?]
        [bc (ab)
          (function-sys/c (ok/c #/function-sys-target ab) any/c)])
      [_ (ab bc)
        (function-sys/c
          (ok/c #/function-sys-source ab)
          (ok/c #/function-sys-target bc))])])

; TODO: Export these from `lathe-morphisms/in-fp/mediary/quiver` once
; we need them.
(provide #/contract-out
  [mediary-quiver-sys? (-> any/c boolean?)]
  [mediary-quiver-sys-impl? (-> any/c boolean?)]
  [prop:mediary-quiver-sys
    (struct-type-property/c mediary-quiver-sys-impl?)]
  [mediary-quiver-sys-node-mediary-set-sys
    (-> mediary-quiver-sys? mediary-set-sys?)]
  [mediary-quiver-sys-node/c (-> mediary-quiver-sys? contract?)]
  [mediary-quiver-sys-edge-mediary-set-sys
    (->i
      (
        [mqs mediary-quiver-sys?]
        [s (mqs) (mediary-quiver-sys-node/c mqs)]
        [t (mqs) (mediary-quiver-sys-node/c mqs)])
      [_ mediary-set-sys?])]
  [mediary-quiver-sys-edge/c
    (->i
      (
        [mqs mediary-quiver-sys?]
        [s (mqs) (mediary-quiver-sys-node/c mqs)]
        [t (mqs) (mediary-quiver-sys-node/c mqs)])
      [_ contract?])]
  [make-mediary-quiver-sys-impl-from-mediary-set-systems
    (->
      (-> mediary-quiver-sys? mediary-set-sys?)
      (->i
        (
          [mqs mediary-quiver-sys?]
          [s (mqs) (mediary-quiver-sys-node/c mqs)]
          [t (mqs) (mediary-quiver-sys-node/c mqs)])
        [_ mediary-set-sys?])
      mediary-quiver-sys-impl?)]
  [makeshift-mediary-quiver-sys
    (->i
      (
        [n mediary-set-sys?]
        [e (n)
          (->
            (mediary-set-sys-element/c n)
            (mediary-set-sys-element/c n)
            mediary-set-sys?)])
      [_ mediary-quiver-sys?])])

; TODO: Export these from `lathe-morphisms/in-fp/mediary/category`
; once we need them.
(provide
  category-object-good-behavior)
(provide #/contract-out
  [category-object-good-behavior? (-> any/c boolean?)]
  [category-object-good-behavior-getter-of-value
    (-> category-object-good-behavior? (-> any/c))]
  [category-object-good-behavior-value
    (-> category-object-good-behavior? any/c)]
  [category-object-good-behavior-getter-of-accepts/c
    (->i ([object category-object-good-behavior?])
      [_ (object)
        (->
          (flat-contract-accepting/c
            (category-object-good-behavior-value object)))])]
  [category-object-good-behavior-getter-of-identity-morphism
    (-> category-object-good-behavior?
      (-> category-morphism-good-behavior?))]
  [category-object-good-behavior-with-value/c
    (-> contract? contract?)]
  [category-object-good-behavior-for-mediary-quiver-sys/c
    (-> mediary-quiver-sys? contract?)]
  [category-object-good-behavior-for-mediary-category-sys/c
    (-> mediary-category-sys? contract?)])

; TODO: Export these from `lathe-morphisms/in-fp/mediary/category`
; once we need them.
(provide #/contract-out
  [atomic-category-object-sys? (-> any/c boolean?)]
  [atomic-category-object-sys-impl? (-> any/c boolean?)]
  [prop:atomic-category-object-sys
    (struct-type-property/c atomic-category-object-sys-impl?)]
  [atomic-category-object-sys-uncoverer-of-good-behavior
    (-> atomic-category-object-sys?
      (-> atomic-category-object-sys?
        category-object-good-behavior?))]
  [atomic-category-object-sys-replace-uncoverer-of-good-behavior
    (->
      atomic-category-object-sys?
      (-> atomic-category-object-sys? category-object-good-behavior?)
      atomic-category-object-sys?)]
  [atomic-category-object-sys-good-behavior
    (-> atomic-category-object-sys? category-object-good-behavior?)]
  [atomic-category-object-sys-accepts/c
    (->i ([object atomic-category-object-sys?])
      [_ (object) (flat-contract-accepting/c object)])]
  [atomic-category-object-sys-identity-morphism-good-behavior
    (-> atomic-category-object-sys? category-morphism-good-behavior?)]
  [make-atomic-category-object-sys-impl-from-good-behavior
    (->
      (-> atomic-category-object-sys?
        (-> atomic-category-object-sys?
          category-object-good-behavior?))
      (->
        atomic-category-object-sys?
        (-> atomic-category-object-sys?
          category-object-good-behavior?)
        atomic-category-object-sys?)
      atomic-category-object-sys-impl?)])

; TODO: Export these from `lathe-morphisms/in-fp/mediary/category`
; once we need them.
(provide
  category-morphism-good-behavior)
(provide #/contract-out
  [category-morphism-good-behavior? (-> any/c boolean?)]
  [category-morphism-good-behavior-getter-of-value
    (-> category-morphism-good-behavior? (-> any/c))]
  [category-morphism-good-behavior-value
    (-> category-morphism-good-behavior? any/c)]
  [category-morphism-good-behavior-getter-of-accepts/c
    (->i ([morphism category-morphism-good-behavior?])
      [_ (morphism)
        (->
          (flat-contract-accepting/c
            (category-morphism-good-behavior-value morphism)))])]
  [category-morphism-good-behavior-with-value/c
    (-> contract? contract?)]
  [category-morphism-good-behavior-for-mediary-quiver-sys/c
    (->i
      (
        [mqs mediary-quiver-sys?]
        [source (mqs) (mediary-quiver-sys-node/c mqs)]
        [target (mqs) (mediary-quiver-sys-node/c mqs)])
      [_ contract?])]
  [category-morphism-good-behavior-for-mediary-category-sys/c
    (->i
      (
        [mcs mediary-category-sys?]
        [source (mcs) (mediary-category-sys-object/c mcs)]
        [target (mcs) (mediary-category-sys-object/c mcs)])
      [_ contract?])])

; TODO: Export these from `lathe-morphisms/in-fp/mediary/category`
; once we need them.
(provide #/contract-out
  [atomic-category-morphism-sys? (-> any/c boolean?)]
  [atomic-category-morphism-sys-impl? (-> any/c boolean?)]
  [prop:atomic-category-morphism-sys
    (struct-type-property/c atomic-category-morphism-sys-impl?)]
  [atomic-category-morphism-sys-source
    (-> atomic-category-morphism-sys? any/c)]
  [atomic-category-morphism-sys-replace-source
    (-> atomic-category-morphism-sys? any/c
      atomic-category-morphism-sys?)]
  [atomic-category-morphism-sys-target
    (-> atomic-category-morphism-sys? any/c)]
  [atomic-category-morphism-sys-replace-target
    (-> atomic-category-morphism-sys? any/c
      atomic-category-morphism-sys?)]
  [atomic-category-morphism-sys-uncoverer-of-good-behavior
    (-> atomic-category-morphism-sys?
      (-> atomic-category-morphism-sys?
        category-morphism-good-behavior?))]
  [atomic-category-morphism-sys-replace-uncoverer-of-good-behavior
    (->
      atomic-category-morphism-sys?
      (-> atomic-category-morphism-sys?
        category-morphism-good-behavior?)
      atomic-category-morphism-sys?)]
  [atomic-category-morphism-sys-good-behavior
    (-> atomic-category-morphism-sys?
      category-morphism-good-behavior?)]
  [atomic-category-morphism-sys-accepts/c
    (->i ([morphism atomic-category-morphism-sys?])
      [_ (morphism) (flat-contract-accepting/c morphism)])]
  [make-atomic-category-morphism-sys-impl-from-good-behavior
    (->
      (-> atomic-category-morphism-sys? any/c)
      (-> atomic-category-morphism-sys? any/c
        atomic-category-morphism-sys?)
      (-> atomic-category-morphism-sys? any/c)
      (-> atomic-category-morphism-sys? any/c
        atomic-category-morphism-sys?)
      (-> atomic-category-morphism-sys?
        (-> atomic-category-morphism-sys?
          category-morphism-good-behavior?))
      (->
        atomic-category-morphism-sys?
        (-> atomic-category-morphism-sys?
          category-morphism-good-behavior?)
        atomic-category-morphism-sys?)
      atomic-category-morphism-sys-impl?)]
  [atomic-category-morphism-sys/c (-> contract? contract? contract?)])

; TODO: Export these from `lathe-morphisms/in-fp/mediary/category`
; once we need them.
(provide #/contract-out
  [mediary-category-sys? (-> any/c boolean?)]
  [mediary-category-sys-impl? (-> any/c boolean?)]
  [prop:mediary-category-sys
    (struct-type-property/c mediary-category-sys-impl?)]
  [mediary-category-sys-object-mediary-set-sys
    (-> mediary-category-sys? mediary-set-sys?)]
  [mediary-category-sys-object/c (-> mediary-category-sys? contract?)]
  [mediary-category-sys-morphism-mediary-set-sys
    (->i
      (
        [mcs mediary-category-sys?]
        [s (mcs) (mediary-category-sys-object/c mcs)]
        [t (mcs) (mediary-category-sys-object/c mcs)])
      [_ mediary-set-sys?])]
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
  [mediary-category-sys-morphism-good-behavior-chain-two
    (->i
      (
        [mcs mediary-category-sys?]
        [a (mcs) (mediary-category-sys-object/c mcs)]
        [b (mcs) (mediary-category-sys-object/c mcs)]
        [c (mcs) (mediary-category-sys-object/c mcs)]
        [ab (mcs a b)
          (category-morphism-good-behavior-for-mediary-category-sys/c
            mcs a b)]
        [bc (mcs b c)
          (category-morphism-good-behavior-for-mediary-category-sys/c
            mcs b c)])
      [_ (mcs a c)
        (category-morphism-good-behavior-for-mediary-category-sys/c
          mcs a c)])]
  [make-mediary-category-sys-impl-from-chain-two
    (->
      (-> mediary-category-sys? mediary-set-sys?)
      (->i
        (
          [mcs mediary-category-sys?]
          [s (mcs) (mediary-category-sys-object/c mcs)]
          [t (mcs) (mediary-category-sys-object/c mcs)])
        [_ mediary-set-sys?])
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
          [ab (mcs a b)
            (category-morphism-good-behavior-for-mediary-category-sys/c
              mcs a b)]
          [bc (mcs b c)
            (category-morphism-good-behavior-for-mediary-category-sys/c
              mcs b c)])
        [_ (mcs a c)
          (category-morphism-good-behavior-for-mediary-category-sys/c
            mcs a c)])
      mediary-category-sys-impl?)])

; TODO: Export this from `lathe-morphisms/in-fp/mediary/quiver` or
; `lathe-morphisms/in-fp/mediary/category` once we need it.
(provide #/contract-out
  [mediary-category-sys-mediary-quiver-sys
    (-> mediary-category-sys? mediary-quiver-sys?)])

(provide #/contract-out
  [category-sys? (-> any/c boolean?)]
  [category-sys-impl? (-> any/c boolean?)]
  [prop:category-sys (struct-type-property/c category-sys-impl?)]
  [category-sys-object-set-sys (-> category-sys? set-sys?)]
  [category-sys-object/c (-> category-sys? contract?)]
  [category-sys-morphism-set-sys
    (->i
      (
        [cs category-sys?]
        [s (cs) (category-sys-object/c cs)]
        [t (cs) (category-sys-object/c cs)])
      [_ set-sys?])]
  [category-sys-morphism/c
    (->i
      (
        [cs category-sys?]
        [s (cs) (category-sys-object/c cs)]
        [t (cs) (category-sys-object/c cs)])
      [_ contract?])]
  [category-sys-object-identity-morphism
    (->i ([cs category-sys?] [object (cs) (category-sys-object/c cs)])
      [_ (cs object) (category-sys-morphism/c cs object object)])]
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
  [make-category-sys-impl-from-chain-two
    (->
      (-> category-sys? set-sys?)
      (->i
        (
          [cs category-sys?]
          [s (cs) (category-sys-object/c cs)]
          [t (cs) (category-sys-object/c cs)])
        [_ set-sys?])
      (->i
        ([cs category-sys?] [object (cs) (category-sys-object/c cs)])
        [_ (cs object) (category-sys-morphism/c cs object object)])
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
  [prop:functor-sys (struct-type-property/c functor-sys-impl?)]
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
        [a (fs) (category-sys-object/c #/functor-sys-source fs)]
        [b (fs) (category-sys-object/c #/functor-sys-source fs)]
        [ab (fs a b)
          (category-sys-morphism/c (functor-sys-source fs) a b)])
      [_ (fs a b)
        (category-sys-object/c (functor-sys-target fs)
          (functor-sys-apply-to-object fs a)
          (functor-sys-apply-to-object fs b))])]
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
          [a (fs) (category-sys-object/c #/functor-sys-source fs)]
          [b (fs) (category-sys-object/c #/functor-sys-source fs)]
          [ab (fs a b)
            (category-sys-morphism/c (functor-sys-source fs) a b)])
        [_ (fs a b)
          (category-sys-morphism/c (functor-sys-target fs)
            (functor-sys-apply-to-object fs a)
            (functor-sys-apply-to-object fs b))])
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
      [_ (s t) (functor-sys/c (ok/c s) (ok/c t))])]
  [functor-sys-identity
    (->i ([endpoint category-sys?])
      [_ (endpoint) (functor-sys/c (ok/c endpoint) (ok/c endpoint))])]
  [functor-sys-chain-two
    (->i
      (
        [ab functor-sys?]
        [bc (ab)
          (functor-sys/c (ok/c #/functor-sys-target ab) any/c)])
      [_ (ab bc)
        (functor-sys/c
          (ok/c #/functor-sys-source ab)
          (ok/c #/functor-sys-target bc))])])

(provide #/contract-out
  [natural-transformation-sys? (-> any/c boolean?)]
  [natural-transformation-sys-impl? (-> any/c boolean?)]
  [prop:natural-transformation-sys
    (struct-type-property/c natural-transformation-sys-impl?)]
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
    (-> natural-transformation-sys? flat-contract?)]
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
  [natural-transformation-sys-apply-to-morphism
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
      [_ (nts a b)
        (category-sys-morphism/c
          (natural-transformation-sys-endpoint-target nts)
          (functor-sys-apply-to-object
            (natural-transformation-sys-source nts)
            a)
          (functor-sys-apply-to-object
            (natural-transformation-sys-target nts)
            b))])]
  [make-natural-transformation-sys-impl-from-apply
    (->
      (-> natural-transformation-sys? category-sys?)
      (-> natural-transformation-sys? category-sys?
        natural-transformation-sys?)
      (-> natural-transformation-sys? category-sys?)
      (-> natural-transformation-sys? category-sys?
        natural-transformation-sys?)
      (->i ([nts natural-transformation-sys?])
        [_ (nts) (natural-transformation-sys-endpoint/c nts)])
      (->i
        (
          [nts natural-transformation-sys?]
          [s (nts) (natural-transformation-sys-endpoint/c nts)])
        [_ natural-transformation-sys?])
      (->i ([nts natural-transformation-sys?])
        [_ (nts) (natural-transformation-sys-endpoint/c nts)])
      (->i
        (
          [nts natural-transformation-sys?]
          [s (nts) (natural-transformation-sys-endpoint/c nts)])
        [_ natural-transformation-sys?])
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
        [_ (nts a b)
          (category-sys-morphism/c
            (natural-transformation-sys-endpoint-target nts)
            (functor-sys-apply-to-object
              (natural-transformation-sys-source nts)
              a)
            (functor-sys-apply-to-object
              (natural-transformation-sys-target nts)
              b))])
      natural-transformation-sys-impl?)]
  [natural-transformation-sys/c
    (-> contract? contract? contract? contract? contract?)]
  [makeshift-natural-transformation-sys
    (->i
      (
        [es category-sys?]
        [et category-sys?]
        [s (es et) (functor-sys/c (ok/c es) (ok/c et))]
        [t (es et) (functor-sys/c (ok/c es) (ok/c et))]
        [apply-to-morphism (es et s t)
          (->i
            (
              [a (category-sys-object/c es)]
              [b (category-sys-object/c es)]
              [ab (a b) (category-sys-morphism/c es a b)])
            [_ (a b)
              (category-sys-morphism/c et
                (functor-sys-apply-to-object s a)
                (functor-sys-apply-to-object t b))])])
      [_ (es et s t)
        (natural-transformation-sys/c
          (ok/c es)
          (ok/c et)
          (ok/c s)
          (ok/c t))])]
  [natural-transformation-sys-identity
    (->i ([endpoint functor-sys?])
      [_ (endpoint)
        (natural-transformation-sys/c
          (ok/c #/functor-sys-source endpoint)
          (ok/c #/functor-sys-target endpoint)
          (ok/c endpoint)
          (ok/c endpoint))])]
  [natural-transformation-sys-chain-two
    (->i
      (
        [ab natural-transformation-sys?]
        [bc (ab)
          (natural-transformation-sys/c
            (ok/c #/natural-transformation-sys-endpoint-source ab)
            (ok/c #/natural-transformation-sys-endpoint-target ab)
            (ok/c #/natural-transformation-sys-target ab)
            any/c)])
      [_ (ab bc)
        (natural-transformation-sys/c
          (ok/c #/natural-transformation-sys-endpoint-source ab)
          (ok/c #/natural-transformation-sys-endpoint-target ab)
          (ok/c #/natural-transformation-sys-source ab)
          (ok/c #/natural-transformation-sys-target bc))])]
  [natural-transformation-sys-chain-two-along-end
    (->i
      (
        [ab natural-transformation-sys?]
        [bc (ab)
          (natural-transformation-sys/c
            (ok/c #/natural-transformation-sys-endpoint-target ab)
            any/c
            any/c
            any/c)])
      [_ (ab bc)
        (natural-transformation-sys/c
          (ok/c #/natural-transformation-sys-endpoint-source ab)
          (ok/c #/natural-transformation-sys-endpoint-target bc)
          (ok/c #/functor-sys-chain-two
            (natural-transformation-sys-source ab)
            (natural-transformation-sys-source bc))
          (ok/c #/functor-sys-chain-two
            (natural-transformation-sys-target ab)
            (natural-transformation-sys-target bc)))])])


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
; Simpson's conjecture suggests that as long as there are weak
; unitors, nothing is lost by having strict composition. If true, this
; might mean we don't have to have to worry about associators and
; interchange at all.
;
; Anyway, the benefit of having a mediary category is that it can be
; considered an open definition: Any well-behaved enough new objects
; and morphisms can be added onto it.
;
; And the reason we've bothered to explore it is because we already
; have a use for defining open sets. Although the "in-fp" collection's
; version of category theory doesn't involve explicit proof witnesses
; for equality, we still care about equality of set elements enough to
; let them specify flat contracts for recognizing themselves
; (`...-accepts/c`). So the kind of value that can recognize itself
; corresponds directly to what we'd call here a *well-behaved set
; element*, where the set it's actually an element of doesn't matter.
;
; Namely, we call that interface `atomic-set-element-sys?`. Outside of
; the "in-fp" collection, there may be similar things called
; `atomic-set-element-sys?` that also deal with proof witnesses, but
; here we treat the lack of witnesses as being implied by the "in-fp"
; module path.
;
; We use the term "atomic" to convey that this is a well-behaved
; *atom* for some medial system. In this case, that medial system is
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

; NOTE:
;
; We export or intend to export the definitions of this file from a
; few different public modules:
;
;   lathe-morphisms/in-fp/set (since it's a common base case)
;   lathe-morphisms/in-fp/quiver (once we need it)
;   lathe-morphisms/in-fp/category
;   lathe-morphisms/in-fp/mediary/set
;   lathe-morphisms/in-fp/mediary/quiver (once we need it)
;   lathe-morphisms/in-fp/mediary/category (once we need it)
;
; Here, the "mediary" directory is like a "generalized sublibrary" or
; "specialized sublibrary" (as discussed in README.md), since they're
; a pretty unusual experiment that involves defining variants of most
; of the other abstractions. Although we do separate these into a
; subdirectory where we reuse the module names, we nevertheless keep
; the `mediary-...` prefix on those systems' exported identifiers,
; since it signals the fact that an important part of the system
; resides in the corresponding `atomic-...` and `...-good-behavior`
; types.
;
; Note that since mediary categories are awfully complicated (and
; could easily be a broken or unstable design), and this complexity is
; not likely to help illuminate category theory ideas (nor functional
; programming ideas), we don't use `mediary-category-sys?` in the
; representation of `category-sys?`. People who use `category-sys?`
; generally shouldn't have to think about `mediary-category-sys?`.

; TODO: If we decide to extrapolate these things to arbitrarily higher
; dimensions, we should probably start an "n-dimensional" or
; "globular" generalized sublibrary for that.


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
    #/
      (if (and (flat-contract? source/c) (flat-contract? target/c))
        make-flat-contract
        make-contract)
      
      #:name name
      
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
          (w- replace-if-not-flat
            (fn c c-projection replace get v
              (w- c-projection (c-projection (get v) missing-party)
              #/if (flat-contract? c)
                v
                (replace v c-projection)))
          #/w- v
            (replace-if-not-flat
              source/c source/c-projection
              morphism-sys-replace-source morphism-sys-source v)
          #/w- v
            (replace-if-not-flat
              target/c target/c-projection
              morphism-sys-replace-target morphism-sys-target v)
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
    #/
      (if
        (and
          (flat-contract? endpoint-source/c)
          (flat-contract? endpoint-target/c)
          (flat-contract? source/c)
          (flat-contract? target/c))
        make-flat-contract
        make-contract)
      
      #:name name
      
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
          (w- replace-if-not-flat
            (fn c c-projection replace get v
              (w- c-projection (c-projection (get v) missing-party)
              #/if (flat-contract? c)
                v
                (replace v c-projection)))
          #/w- v
            (replace-if-not-flat
              endpoint-source/c endpoint-source/c-projection
              cell-sys-replace-endpoint-source
              cell-sys-endpoint-source
              v)
          #/w- v
            (replace-if-not-flat
              endpoint-target/c endpoint-target/c-projection
              cell-sys-replace-endpoint-target
              cell-sys-endpoint-target
              v)
          #/w- v
            (replace-if-not-flat
              source/c source/c-projection
              cell-sys-replace-source cell-sys-source v)
          #/w- v
            (replace-if-not-flat
              target/c target/c-projection
              cell-sys-replace-target cell-sys-target v)
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
    morphism-sys-apply-to-guest
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
                      #'(morphism-sys-apply-to-guest ...)))])
              #'(-> any/c any/c any/c))
        any/c)
    #:name "structure type property implementation constructor")
  
  #:declare morphism-sys-source
  (expr/c #'(-> any/c any/c) #:name "source accessor")
  
  #:declare morphism-sys-target
  (expr/c #'(-> any/c any/c) #:name "target accessor")
  
  #:declare morphism-sys-apply-to-guest
  (expr/c #'(unconstrained-domain-> any/c)
    #:name "an application behavior function")
  
  #:with (ap ...)
  (generate-temporaries #'(morphism-sys-apply-to-guest ...))
  
  #:with (contracted-morphism-sys-apply-to-guest ...)
  (generate-temporaries #'(ap ...))
  
  #:with (makeshift-morphism-sys-apply-to-guest ...)
  (generate-temporaries #'(ap ...))
  
  #:with (identity ...)
  (for/list ([arg/c (in-list (syntax->list #'(ap ...)))])
    #'(lambda endpoints-and-guest
        (dissect (reverse endpoints-and-guest)
          (cons guest rev-endpoints)
          guest)))
  
  (begin
    (define contracted-makeshift-morphism-sys-name
      makeshift-morphism-sys-name.c)
    (define contracted-prop-morphism-sys prop-morphism-sys.c)
    (define contracted-make-morphism-sys-impl-from-apply
      make-morphism-sys-impl-from-apply.c)
    (define contracted-morphism-sys-source morphism-sys-source.c)
    (define contracted-morphism-sys-target morphism-sys-target.c)
    (define contracted-morphism-sys-apply-to-guest
      morphism-sys-apply-to-guest.c)
    ...
    (define-imitation-simple-struct
      (makeshift-morphism-sys?
        makeshift-morphism-sys-source
        makeshift-morphism-sys-target
        makeshift-morphism-sys-apply-to-guest
        ...)
      unguarded-makeshift-morphism-sys
      contracted-makeshift-morphism-sys-name (current-inspector)
      (#:prop contracted-prop-morphism-sys
        (contracted-make-morphism-sys-impl-from-apply
          ; morphism-sys-source
          (dissectfn (unguarded-makeshift-morphism-sys s t ap ...) s)
          ; morphism-sys-replace-source
          (fn ms new-s
            (dissect ms (unguarded-makeshift-morphism-sys s t ap ...)
            #/unguarded-makeshift-morphism-sys new-s t ap ...))
          ; morphism-sys-target
          (dissectfn (unguarded-makeshift-morphism-sys s t ap ...) t)
          ; morphism-sys-replace-target
          (fn ms new-t
            (dissect ms (unguarded-makeshift-morphism-sys s t ap ...)
            #/unguarded-makeshift-morphism-sys s new-t ap ...))
          ; morphism-sys-apply-to-guest
          (fn ms guest
            ( (makeshift-morphism-sys-apply-to-guest ms) guest))
          ...)))
    (define (makeshift-morphism-sys s t ap ...)
      (unguarded-makeshift-morphism-sys s t ap ...))
    (define (morphism-sys-identity endpoint)
      (makeshift-morphism-sys endpoint endpoint identity ...))
    (define (morphism-sys-chain-two ab bc)
      (makeshift-morphism-sys
        (contracted-morphism-sys-source ab)
        (contracted-morphism-sys-target bc)
        (lambda endpoints-and-guest
          (dissect (reverse endpoints-and-guest)
            (cons guest rev-endpoints)
          #/w- endpoints (reverse rev-endpoints)
          #/apply contracted-morphism-sys-apply-to-guest bc
            (append endpoints
              (apply contracted-morphism-sys-apply-to-guest ab
                endpoints-and-guest))))
        ...))))

(define-simple-macro
  (define-makeshift-2-cell
    makeshift-cell-sys:id
    cell-sys-identity:id
    cell-sys-chain-two:id
    cell-sys-chain-two-along-end:id
    makeshift-cell-sys-name
    prop-cell-sys
    make-cell-sys-impl-from-apply
    endpoint-replace-source
    endpoint-replace-target
    endpoint-chain-two
    cell-sys-endpoint-source
    cell-sys-endpoint-target
    cell-sys-source
    cell-sys-target
    (#:guest
      endpoint-endpoint-guest-identity
      endpoint-endpoint-guest-chain-two
      endpoint-apply-to-guest-endpoint
      endpoint-apply-to-guest
      cell-sys-apply-to-guest)
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
                    (syntax->list #'(cell-sys-apply-to-guest ...)))])
              #'(-> any/c any/c any/c))
        any/c)
    #:name "structure type property implementation constructor")
  
  #:declare endpoint-replace-source
  (expr/c #'(-> any/c any/c any/c)
    #:name "endpoint system's source replacer")
  
  #:declare endpoint-replace-target
  (expr/c #'(-> any/c any/c any/c)
    #:name "endpoint system's target replacer")
  
  #:declare endpoint-chain-two
  (expr/c #'(-> any/c any/c any/c)
    #:name "composition function for endpoint systems")
  
  #:declare cell-sys-endpoint-source
  (expr/c #'(-> any/c any/c) #:name "endpoint source accessor")
  
  #:declare cell-sys-endpoint-target
  (expr/c #'(-> any/c any/c) #:name "endpoint target accessor")
  
  #:declare cell-sys-source
  (expr/c #'(-> any/c any/c) #:name "source accessor")
  
  #:declare cell-sys-target
  (expr/c #'(-> any/c any/c) #:name "target accessor")
  
  #:declare endpoint-endpoint-guest-identity
  (expr/c #'(unconstrained-domain-> any/c)
    #:name "one of the identity functions of an endpoint system's endpoint system")
  
  #:declare endpoint-endpoint-guest-chain-two
  (expr/c #'(unconstrained-domain-> any/c)
    #:name "one of the sequencing functions of an endpoint system's endpoint system")
  
  #:declare endpoint-apply-to-guest-endpoint
  (expr/c #'(unconstrained-domain-> any/c)
    #:name "one of the application behavior functions of an endpoint system taking an endpoint")
  
  #:declare endpoint-apply-to-guest
  (expr/c #'(unconstrained-domain-> any/c)
    #:name "one of the application behavior functions of an endpoint system")
  
  #:declare cell-sys-apply-to-guest
  (expr/c #'(unconstrained-domain-> any/c)
    #:name "an application behavior function")
  
  #:with (ap ...)
  (generate-temporaries #'(endpoint-endpoint-guest-identity ...))
  
  #:with (contracted-endpoint-endpoint-guest-identity ...)
  (generate-temporaries #'(ap ...))
  
  #:with (contracted-endpoint-endpoint-guest-chain-two ...)
  (generate-temporaries #'(ap ...))
  
  #:with (contracted-endpoint-apply-to-guest-endpoint ...)
  (generate-temporaries #'(ap ...))
  
  #:with (contracted-endpoint-apply-to-guest ...)
  (generate-temporaries #'(ap ...))
  
  #:with (contracted-cell-sys-apply-to-guest ...)
  (generate-temporaries #'(ap ...))
  
  #:with (makeshift-cell-sys-apply-to-guest ...)
  (generate-temporaries #'(ap ...))
  
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
    (define contracted-endpoint-chain-two endpoint-chain-two.c)
    (define contracted-cell-sys-endpoint-source
      cell-sys-endpoint-source.c)
    (define contracted-cell-sys-endpoint-target
      cell-sys-endpoint-target.c)
    (define contracted-cell-sys-source cell-sys-source.c)
    (define contracted-cell-sys-target cell-sys-target.c)
    (define contracted-endpoint-endpoint-guest-identity
      endpoint-endpoint-guest-identity.c)
    ...
    (define contracted-endpoint-endpoint-guest-chain-two
      endpoint-endpoint-guest-chain-two.c)
    ...
    (define contracted-endpoint-apply-to-guest-endpoint
      endpoint-apply-to-guest-endpoint.c)
    ...
    (define contracted-endpoint-apply-to-guest
      endpoint-apply-to-guest.c)
    ...
    (define contracted-cell-sys-apply-to-guest
      cell-sys-apply-to-guest.c)
    ...
    (define-imitation-simple-struct
      (makeshift-cell-sys?
        makeshift-cell-sys-endpoint-source
        makeshift-cell-sys-endpoint-target
        makeshift-cell-sys-source
        makeshift-cell-sys-target
        makeshift-cell-sys-apply-to-guest
        ...)
      unguarded-makeshift-cell-sys
      contracted-makeshift-cell-sys-name (current-inspector)
      (#:prop contracted-prop-cell-sys
        (contracted-make-cell-sys-impl-from-apply
          ; cell-sys-endpoint-source
          (dissectfn (unguarded-makeshift-cell-sys es et s t ap ...)
            es)
          ; cell-sys-replace-endpoint-source
          (fn ms new-es
            (dissect ms
              (unguarded-makeshift-cell-sys es et s t ap ...)
            #/unguarded-makeshift-cell-sys new-es et
              (contracted-endpoint-replace-source s new-es)
              (contracted-endpoint-replace-source t new-es)
              ap
              ...))
          ; cell-sys-endpoint-target
          (dissectfn (unguarded-makeshift-cell-sys es et s t ap ...)
            et)
          ; cell-sys-replace-endpoint-target
          (fn ms new-et
            (dissect ms
              (unguarded-makeshift-cell-sys es et s t ap ...)
            #/unguarded-makeshift-cell-sys es new-et
              (contracted-endpoint-replace-target s new-et)
              (contracted-endpoint-replace-target t new-et)
              ap
              ...))
          ; cell-sys-source
          (dissectfn (unguarded-makeshift-cell-sys es et s t ap ...)
            s)
          ; cell-sys-replace-source
          (fn ms new-s
            (dissect ms
              (unguarded-makeshift-cell-sys es et s t ap ...)
            #/unguarded-makeshift-cell-sys es et new-s t ap ...))
          ; cell-sys-target
          (dissectfn (unguarded-makeshift-cell-sys es et s t ap ...)
            t)
          ; cell-sys-replace-target
          (fn ms new-t
            (dissect ms
              (unguarded-makeshift-cell-sys es et s t ap ...)
            #/unguarded-makeshift-cell-sys es et s new-t ap ...))
          ; cell-sys-apply-to-guest
          (fn ms cell
            ( (makeshift-cell-sys-apply-to-guest ms) cell))
          ...)))
    (define (makeshift-cell-sys es et s t ap ...)
      (unguarded-makeshift-cell-sys es et s t ap ...))
    (define (cell-sys-identity endpoint)
      (makeshift-cell-sys
        (contracted-cell-sys-endpoint-source endpoint)
        (contracted-cell-sys-endpoint-target endpoint)
        endpoint
        endpoint
        (lambda endpoints-and-cell
          (apply contracted-endpoint-apply-to-guest endpoint
            endpoints-and-cell))
        ...))
    (define (cell-sys-chain-two ab bc)
      (w- es (contracted-cell-sys-endpoint-source ab)
      #/w- et (contracted-cell-sys-endpoint-target ab)
      #/w- a (contracted-cell-sys-source ab)
      #/w- b (contracted-cell-sys-target ab)
      #/w- c (contracted-cell-sys-target bc)
      #/makeshift-cell-sys es et a c
        (lambda endpoints-and-guest
          (dissect (reverse endpoints-and-guest)
            (list* guest guest-t guest-s rev-endpoints)
          #/w- endpoints (reverse rev-endpoints)
          #/apply contracted-endpoint-endpoint-guest-chain-two
            et
            (append endpoints
              (list
                (apply contracted-endpoint-apply-to-guest-endpoint a
                  (append endpoints (list guest-s)))
                (apply contracted-endpoint-apply-to-guest-endpoint b
                  (append endpoints (list guest-s)))
                (apply contracted-endpoint-apply-to-guest-endpoint c
                  (append endpoints (list guest-t)))
                (apply contracted-endpoint-apply-to-guest ab
                  (append endpoints
                    (list guest-s guest-t
                      (apply
                        contracted-endpoint-endpoint-guest-identity
                        es
                        (append endpoints (list guest-s))))))
                (apply contracted-endpoint-apply-to-guest bc
                  endpoints-and-guest)))))
        ...))
    (define (cell-sys-chain-two-along-end ab bc)
      (makeshift-cell-sys
        (contracted-cell-sys-endpoint-source ab)
        (contracted-cell-sys-endpoint-target bc)
        (contracted-endpoint-chain-two
          (contracted-cell-sys-source ab)
          (contracted-cell-sys-source bc))
        (contracted-endpoint-chain-two
          (contracted-cell-sys-target ab)
          (contracted-cell-sys-target bc))
        (lambda endpoints-and-guest
          (dissect (reverse endpoints-and-guest)
            (cons guest rev-endpoints)
          #/w- endpoints (reverse rev-endpoints)
          #/apply contracted-cell-sys-apply-to-guest bc
            (append endpoints
              (apply contracted-cell-sys-apply-to-guest ab
                endpoints-and-guest))))
        ...))))


(define-imitation-simple-struct
  (set-element-good-behavior?
    
    ;   [set-element-good-behavior-getter-of-value
    ;     (-> set-element-good-behavior? (-> any/c))]
    set-element-good-behavior-getter-of-value
    
    ;   [set-element-good-behavior-getter-of-accepts/c
    ;     (->i ([element set-element-good-behavior?])
    ;       [_ (element)
    ;         (->
    ;           (flat-contract-accepting/c
    ;             (set-element-good-behavior-value element)))])]
    set-element-good-behavior-getter-of-accepts/c)
  
  unguarded-set-element-good-behavior
  'set-element-good-behavior (current-inspector)
  (auto-write)
  (auto-equal))
; TODO: We have a dilemma. The `define/contract` version of
; `attenuated-set-element-good-behavior` will give less precise source
; location information in its errors, and it won't catch applications
; with incorrect arity. On the other hand, the
; `define-match-expander-attenuated` version can't express a fully
; precise contract for `getter-of-accepts/c`, namely
; `(-> #/flat-contract-accepting/c #/getter-of-value)`. Dependent
; contracts would be difficult to make matchers for, but perhaps we
; could implement an alternative to `define-match-expander-attenuated`
; that just defined the function-like side and not actually the match
; expander.
(define attenuated-set-element-good-behavior
  (let ()
    (define/contract
      (set-element-good-behavior getter-of-value getter-of-accepts/c)
      (->i
        (
          [getter-of-value (-> any/c)]
          [getter-of-accepts/c (getter-of-value)
            (-> #/flat-contract-accepting/c #/getter-of-value)])
        [_ set-element-good-behavior?])
      (unguarded-set-element-good-behavior
        getter-of-value getter-of-accepts/c))
    set-element-good-behavior))
#;
(define-match-expander-attenuated
  attenuated-set-element-good-behavior
  unguarded-set-element-good-behavior
  [getter-of-value (-> any/c)]
  [getter-of-accepts/c (-> flat-contract?)]
  #t)
(define-match-expander-from-match-and-make
  set-element-good-behavior
  unguarded-set-element-good-behavior
  attenuated-set-element-good-behavior
  attenuated-set-element-good-behavior)

(define (set-element-good-behavior-value element-gb)
  ( #/set-element-good-behavior-getter-of-value element-gb))

(define (set-element-good-behavior-with-value/c value/c)
  (rename-contract
    (match/c set-element-good-behavior (-> value/c) any/c)
    `(set-element-good-behavior-with-value/c
       ,(value-name-for-contract value/c))))

(define (set-element-good-behavior-for-mediary-set-sys/c mss)
  (rename-contract
    (set-element-good-behavior-with-value/c
      (mediary-set-sys-element/c mss))
    `(set-element-good-behavior-for-mediary-set-sys/c
       ,(value-name-for-contract mss))))

(define-imitation-simple-generics
  atomic-set-element-sys? atomic-set-element-sys-impl?
  (#:method atomic-set-element-sys-good-behavior (#:this))
  prop:atomic-set-element-sys
  make-atomic-set-element-sys-impl-from-good-behavior
  'atomic-set-element-sys 'atomic-set-element-sys-impl (list))

(define (atomic-set-element-sys-accepts/c es)
  ( #/set-element-good-behavior-getter-of-accepts/c
    (atomic-set-element-sys-good-behavior es)))

(define (make-atomic-set-element-sys-impl-from-contract accepts/c)
  (make-atomic-set-element-sys-impl-from-good-behavior
    ; atomic-set-element-sys-good-behavior
    (fn es
      (set-element-good-behavior
        ; set-element-good-behavior-getter-for-value
        (fn es)
        ; set-element-good-behavior-getter-for-accepts/c
        (fn #/accepts/c es)))))

(define-imitation-simple-generics
  mediary-set-sys? mediary-set-sys-impl?
  (#:method mediary-set-sys-element/c (#:this))
  prop:mediary-set-sys make-mediary-set-sys-impl-from-contract
  'mediary-set-sys 'mediary-set-sys-impl (list))

(define (ok/c example)
  (if (atomic-set-element-sys? example)
    (atomic-set-element-sys-accepts/c example)
    any/c))

(define-imitation-simple-generics
  set-sys? set-sys-impl?
  (#:method set-sys-element/c (#:this))
  (#:method set-sys-element-accepts/c (#:this) ())
  prop:set-sys make-set-sys-impl-from-contract
  'set-sys 'set-sys-impl (list))

(define-imitation-simple-struct
  (makeshift-set-sys?
    makeshift-set-sys-element/c
    makeshift-set-sys-element-accepts/c)
  unguarded-makeshift-set-sys
  'makeshift-set-sys (current-inspector)
  (#:prop prop:set-sys
    (make-set-sys-impl-from-contract
      ; set-sys-element/c
      (dissectfn
        (unguarded-makeshift-set-sys element/c element-accepts/c)
        (element/c))
      ; set-sys-element-accepts/c
      (fn ss element
        (dissect ss
          (unguarded-makeshift-set-sys element/c element-accepts/c)
        #/element-accepts/c element)))))

(define (makeshift-set-sys-from-contract element/c element-accepts/c)
  (unguarded-makeshift-set-sys element/c element-accepts/c))

; TODO: See if we should have functions between mediary sets too, i.e.
; `mediary-function-sys?`. A `mediary-function-sys?` would have a
; method for transforming an element of the source mediary set to an
; element of the target mediary set, and it would have a more specific
; method for transforming a `set-element-good-behavior?` of the source
; to a `set-element-good-behavior?` of the target.
;
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

; NOTE:
;
; A quiver is a kind of directed graph that specifically allows for
; loops and parallel edges, just like a category allows for
; endomorphisms and parallel morphisms. (The term "digraph" is often
; used for directed graphs which don't allow for these things.)
;
; We don't use quivers to define `mediary-category-sys?` or
; `category-sys?`. Instead, we define them solely to be passed into
; `category-object-good-behavior-for-mediary-quiver-sys/c` and
; `category-morphism-good-behavior-for-mediary-quiver-sys/c`. In
; general, the coherence information for no-proof-witness
; N-dimensional categories will need to be something like an
; (N-1)-dimensional category enriched in a quiver. That is, it will be
; some kind of N-dimensional quiver whose cells have compositional
; structure at all dimensions less than N. The composition operations
; will be needed to express the sources and targets of the
; N-dimensional category's unitor cells.
;
; Since we're not using this as infrastructure, we don't bother to
; define `atomic-quiver-node-sys?`, `atomic-quiver-edge-sys?`, or
; `quiver-sys?`. The `atomic-quiver-node-sys?` and
; `atomic-quiver-edge-sys?` interfaces would likely be equivalent to
; `atomic-set-element-sys?` anyway.
;
(define-imitation-simple-generics
  mediary-quiver-sys? mediary-quiver-sys-impl?
  (#:method mediary-quiver-sys-node-mediary-set-sys (#:this))
  (#:method mediary-quiver-sys-edge-mediary-set-sys (#:this) () ())
  prop:mediary-quiver-sys
  make-mediary-quiver-sys-impl-from-mediary-set-systems
  'mediary-quiver-sys 'mediary-quiver-sys-impl (list))

(define (mediary-quiver-sys-node/c mcs)
  (mediary-set-sys-element/c
    (mediary-quiver-sys-node-mediary-set-sys mcs)))

(define (mediary-quiver-sys-edge/c mcs s t)
  (mediary-set-sys-element/c
    (mediary-quiver-sys-edge-mediary-set-sys mcs s t)))

(define-imitation-simple-struct
  (makeshift-mediary-quiver-sys?
    makeshift-mediary-quiver-sys-node-mediary-set-sys
    makeshift-mediary-quiver-sys-edge-mediary-set-sys-family)
  unguarded-makeshift-mediary-quiver-sys
  'makeshift-mediary-quiver-sys (current-inspector)
  (#:prop prop:mediary-quiver-sys
    (make-mediary-quiver-sys-impl-from-mediary-set-systems
      ; mediary-quiver-sys-node-mediary-set-sys
      (dissectfn (unguarded-makeshift-mediary-quiver-sys n e) n)
      ; mediary-quiver-sys-edge-mediary-set-sys
      (fn mqs s t
        (dissect mqs (unguarded-makeshift-mediary-quiver-sys n e)
        #/e s t)))))

(define (makeshift-mediary-quiver-sys n e)
  (unguarded-makeshift-mediary-quiver-sys n e))

(define-imitation-simple-struct
  (category-object-good-behavior?
    
    ;   [category-object-good-behavior-getter-of-value
    ;     (-> category-object-good-behavior? (-> any/c))]
    category-object-good-behavior-getter-of-value
    
    ;   [category-object-good-behavior-getter-of-accepts/c
    ;     (->i ([object category-object-good-behavior?])
    ;       [_ (object)
    ;         (->
    ;           (flat-contract-accepting/c
    ;             (category-object-good-behavior-value object)))])]
    category-object-good-behavior-getter-of-accepts/c
    
    ;   [category-object-good-behavior-getter-of-identity-morphism
    ;     (-> category-object-good-behavior?
    ;       (-> category-morphism-good-behavior?))]
    category-object-good-behavior-getter-of-identity-morphism)
  
  unguarded-category-object-good-behavior
  'category-object-good-behavior (current-inspector)
  (auto-write)
  (auto-equal))

(define (category-object-good-behavior-value object-gb)
  ( #/category-object-good-behavior-getter-of-value object-gb))

(define (category-object-good-behavior-with-value/c value/c)
  (rename-contract
    (match/c category-object-good-behavior (-> value/c) any/c any/c)
    `(category-object-good-behavior-with-value/c
       ,(value-name-for-contract value/c))))

(define (category-object-good-behavior-for-mediary-quiver-sys/c mqs)
  (rename-contract
    (and/c
      (match/c category-object-good-behavior
        (-> #/mediary-quiver-sys-node/c mqs)
        any/c
        any/c)
      (by-own-method/c good-behavior
      #/w- object (category-object-good-behavior-value good-behavior)
      #/match/c category-object-good-behavior
        any/c
        any/c
        (->
          (category-morphism-good-behavior-for-mediary-quiver-sys/c
            mqs object object))))
    `(category-object-good-behavior-for-mediary-quiver-sys/c
       ,(value-name-for-contract mqs))))

(define (category-object-good-behavior-for-mediary-category-sys/c mcs)
  (rename-contract
    (category-object-good-behavior-for-mediary-quiver-sys/c
      (mediary-category-sys-mediary-quiver-sys mcs))
    `(category-object-good-behavior-for-mediary-category-sys/c
       ,(value-name-for-contract mcs))))

(define-imitation-simple-generics
  atomic-category-object-sys? atomic-category-object-sys-impl?
  (#:method atomic-category-object-sys-uncoverer-of-good-behavior
    (#:this))
  (#:method
    atomic-category-object-sys-replace-uncoverer-of-good-behavior
    (#:this)
    ())
  prop:atomic-category-object-sys
  make-atomic-category-object-sys-impl-from-good-behavior
  'atomic-category-object-sys 'atomic-category-object-sys-impl (list))

(define (atomic-category-object-sys-good-behavior os)
  ( (atomic-category-object-sys-uncoverer-of-good-behavior os) os))

(define (atomic-category-object-sys-accepts/c os)
  ( #/category-object-good-behavior-getter-of-accepts/c
    (atomic-category-object-sys-good-behavior os)))

(define
  (atomic-category-object-sys-identity-morphism-good-behavior os)
  ( #/category-object-good-behavior-getter-of-identity-morphism
    (atomic-category-object-sys-good-behavior os)))

(define-imitation-simple-struct
  (category-morphism-good-behavior?
    
    ;   [category-morphism-good-behavior-getter-of-value
    ;     (-> category-morphism-good-behavior? (-> any/c))]
    category-morphism-good-behavior-getter-of-value
    
    ;   [category-morphism-good-behavior-getter-of-accepts/c
    ;     (->i ([morphism category-morphism-good-behavior?])
    ;       [_ (morphism)
    ;         (->
    ;           (flat-contract-accepting/c
    ;             (category-morphism-good-behavior-value
    ;               morphism)))])]
    category-morphism-good-behavior-getter-of-accepts/c)
  
  unguarded-category-morphism-good-behavior
  'category-morphism-good-behavior (current-inspector)
  (auto-write)
  (auto-equal))
; TODO: We have a dilemma. The `define/contract` version of
; `attenuated-category-morphism-good-behavior` will give less precise
; source location information in its errors, and it won't catch
; applications with incorrect arity. On the other hand, the
; `define-match-expander-attenuated` version can't express a fully
; precise contract for `getter-of-accepts/c`, namely
; `(-> #/flat-contract-accepting/c #/getter-of-value)`. Dependent
; contracts would be difficult to make matchers for, but perhaps we
; could implement an alternative to `define-match-expander-attenuated`
; that just defined the function-like side and not actually the match
; expander.
(define attenuated-category-morphism-good-behavior
  (let ()
    (define/contract
      (category-morphism-good-behavior
        getter-of-value getter-of-accepts/c)
      (->i
        (
          [getter-of-value (-> any/c)]
          [getter-of-accepts/c (getter-of-value)
            (-> #/flat-contract-accepting/c #/getter-of-value)])
        [_ category-morphism-good-behavior?])
      (unguarded-category-morphism-good-behavior
        getter-of-value getter-of-accepts/c))
    category-morphism-good-behavior))
#;
(define-match-expander-attenuated
  attenuated-category-morphism-good-behavior
  unguarded-category-morphism-good-behavior
  [getter-of-value (-> any/c)]
  [getter-of-accepts/c (-> flat-contract?)]
  #t)
(define-match-expander-from-match-and-make
  category-morphism-good-behavior
  unguarded-category-morphism-good-behavior
  attenuated-category-morphism-good-behavior
  attenuated-category-morphism-good-behavior)

; TODO: We have a dilemma. The `define/contract` version of
; `attenuated-category-object-good-behavior` will give less precise
; source location information in its errors, and it won't catch
; applications with incorrect arity. On the other hand, the
; `define-match-expander-attenuated` version can't express a fully
; precise contract for `getter-of-accepts/c`, namely
; `(-> #/flat-contract-accepting/c #/getter-of-value)`. Dependent
; contracts would be difficult to make matchers for, but perhaps we
; could implement an alternative to `define-match-expander-attenuated`
; that just defined the function-like side and not actually the match
; expander.
(define attenuated-category-object-good-behavior
  (let ()
    (define/contract
      (category-object-good-behavior
        getter-of-value
        getter-of-accepts/c
        getter-of-identity-morphism)
      (->i
        (
          [getter-of-value (-> any/c)]
          [getter-of-accepts/c (getter-of-value)
            (-> #/flat-contract-accepting/c #/getter-of-value)]
          [getter-of-identity-morphism
            (-> category-morphism-good-behavior?)])
        [_ category-object-good-behavior?])
      (unguarded-category-object-good-behavior
        getter-of-value
        getter-of-accepts/c
        getter-of-identity-morphism))
    category-object-good-behavior))
#;
(define-match-expander-attenuated
  attenuated-category-object-good-behavior
  unguarded-category-object-good-behavior
  [getter-of-value (-> any/c)]
  [getter-of-accepts/c (-> flat-contract?)]
  [getter-of-identity-morphism (-> category-morphism-good-behavior?)]
  #t)
(define-match-expander-from-match-and-make
  category-object-good-behavior
  unguarded-category-object-good-behavior
  attenuated-category-object-good-behavior
  attenuated-category-object-good-behavior)

(define (category-morphism-good-behavior-value morphism-gb)
  ( #/category-morphism-good-behavior-getter-of-value morphism-gb))

(define (category-morphism-good-behavior-with-value/c value/c)
  (rename-contract
    (match/c category-morphism-good-behavior
      (-> value/c)
      (-> contract?))
    `(category-morphism-good-behavior-with-value/c
       ,(value-name-for-contract value/c))))

(define
  (category-morphism-good-behavior-for-mediary-quiver-sys/c
    mqs source target)
  (rename-contract
    (category-morphism-good-behavior-with-value/c
      (mediary-quiver-sys-edge/c mqs source target))
    `(category-morphism-good-behavior-for-mediary-quiver-sys/c
       ,(value-name-for-contract mqs)
       ,(value-name-for-contract source)
       ,(value-name-for-contract target))))

(define
  (category-morphism-good-behavior-for-mediary-category-sys/c
    mcs source target)
  (rename-contract
    (category-morphism-good-behavior-for-mediary-quiver-sys/c
      (mediary-category-sys-mediary-quiver-sys mcs)
      source
      target)
    `(category-morphism-good-behavior-for-mediary-category-sys/c
       ,(value-name-for-contract mcs)
       ,(value-name-for-contract source)
       ,(value-name-for-contract target))))

(define-imitation-simple-generics
  atomic-category-morphism-sys? atomic-category-morphism-sys-impl?
  
  ; NOTE:
  ;
  ; Most of the functionality here is comprised of the fields of the
  ; `category-morphism-good-behavior?` result of
  ; `atomic-category-morphism-sys-uncoverer-of-good-behavior`, which
  ; correspond to various particular methods of `category-sys?`. The
  ; `atomic-category-morphism-sys-source`,
  ; `atomic-category-morphism-sys-replace-source`,
  ; `atomic-category-morphism-sys-target`, and
  ; `atomic-category-morphism-sys-replace-target` methods don't follow
  ; the pattern; they don't correspond to `category-sys?` methods
  ; named `category-sys-morphism-source`,
  ; `category-sys-morphism-replace-source`,
  ; `category-sys-morphism-target`, and
  ; `category-sys-morphism-replace-target` as one might expect.
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
  (#:method atomic-category-morphism-sys-replace-source (#:this) ())
  (#:method atomic-category-morphism-sys-target (#:this))
  (#:method atomic-category-morphism-sys-replace-target (#:this) ())
  (#:method atomic-category-morphism-sys-uncoverer-of-good-behavior
    (#:this))
  (#:method
    atomic-category-morphism-sys-replace-uncoverer-of-good-behavior
    (#:this)
    ())
  prop:atomic-category-morphism-sys
  make-atomic-category-morphism-sys-impl-from-good-behavior
  'atomic-category-morphism-sys 'atomic-category-morphism-sys-impl
  (list))

(define (atomic-category-morphism-sys-good-behavior ms)
  ( (atomic-category-morphism-sys-uncoverer-of-good-behavior ms) ms))

(define (atomic-category-morphism-sys-accepts/c ms)
  ( #/category-morphism-good-behavior-getter-of-accepts/c
    (atomic-category-morphism-sys-good-behavior ms)))

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
; `make-atomic-category-morphism-sys-impl-from-good-behavior` isn't a
; property implementation constructor with that signature format. We
; would simply have to define it without the help of the
; `define-makeshift-morphism` abstraction.


(define-imitation-simple-generics
  mediary-category-sys? mediary-category-sys-impl?
  (#:method mediary-category-sys-object-mediary-set-sys (#:this))
  (#:method mediary-category-sys-morphism-mediary-set-sys
    (#:this)
    ()
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
  ; (and, if this were a higher-dimensional category or a category
  ; with proof witnesses of morphism equality, unitor laws for those
  ; cells to obey). However, if all the generating objects and
  ; morphisms really are well-behaved, then the whole
  ; `mediary-category-sys?` ought to be as well-behaved as a
  ; `category-sys?`, so we ought to find that the composition
  ; morphisms are well-behaved like the others.
  ;
  ; We can ensure this by making it so the composition of any two
  ; morphisms that are well-behaved is well-behaved in turn. This also
  ; allows small parts of a `mediary-category-sys?` to be poorly
  ; behaved without interfering with the usefulness of well-behaved
  ; subsystems.
  ;
  ;   [mediary-category-sys-morphism-good-behavior-chain-two
  ;     (->i
  ;       (
  ;         [mcs mediary-category-sys?]
  ;         [a (mcs) (mediary-category-sys-object/c mcs)]
  ;         [b (mcs) (mediary-category-sys-object/c mcs)]
  ;         [c (mcs) (mediary-category-sys-object/c mcs)]
  ;         [ab (mcs a b)
  ;           (category-morphism-good-behavior-for-mediary-category-sys/c
  ;             mcs a b)]
  ;         [bc (mcs b c)
  ;           (category-morphism-good-behavior-for-mediary-category-sys/c
  ;             mcs b c)])
  ;       [_ (mcs a c)
  ;         (category-morphism-good-behavior-for-mediary-category-sys/c
  ;           mcs a c)])]
  ;
  (#:method mediary-category-sys-morphism-good-behavior-chain-two
    (#:this)
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
    (mediary-category-sys-morphism-mediary-set-sys mcs s t)))

(define (mediary-category-sys-mediary-quiver-sys mcs)
  (makeshift-mediary-quiver-sys
    (mediary-category-sys-object-mediary-set-sys mcs)
    (fn s t #/mediary-category-sys-morphism-mediary-set-sys mcs s t)))

(define-imitation-simple-generics
  category-sys? category-sys-impl?
  (#:method category-sys-object-set-sys (#:this))
  (#:method category-sys-morphism-set-sys (#:this) () ())
  (#:method category-sys-object-identity-morphism (#:this) ())
  (#:method category-sys-morphism-chain-two (#:this) () () () () ())
  prop:category-sys make-category-sys-impl-from-chain-two
  'category-sys 'category-sys-impl (list))

(define (category-sys-object/c cs)
  (set-sys-element/c #/category-sys-object-set-sys cs))

(define (category-sys-morphism/c cs s t)
  (set-sys-element/c #/category-sys-morphism-set-sys cs s t))

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
  (#:method natural-transformation-sys-apply-to-morphism
    (#:this)
    ()
    ()
    ())
  prop:natural-transformation-sys
  make-natural-transformation-sys-impl-from-apply
  'natural-transformation-sys 'natural-transformation-sys-impl (list))

(define (natural-transformation-sys-endpoint/c nts)
  (rename-contract
    (functor-sys/c
      (ok/c #/natural-transformation-sys-endpoint-source nts)
      (ok/c #/natural-transformation-sys-endpoint-target nts))
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
  natural-transformation-sys-chain-two-along-end
  'makeshift-natural-transformation-sys
  prop:natural-transformation-sys
  make-natural-transformation-sys-impl-from-apply
  functor-sys-replace-source
  functor-sys-replace-target
  functor-sys-chain-two
  natural-transformation-sys-endpoint-source
  natural-transformation-sys-endpoint-target
  natural-transformation-sys-source
  natural-transformation-sys-target
  (#:guest
    category-sys-object-identity-morphism
    category-sys-morphism-chain-two
    functor-sys-apply-to-object
    functor-sys-apply-to-morphism
    natural-transformation-sys-apply-to-morphism))
