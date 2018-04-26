#lang parendown racket/base

; lathe-morphisms/private2
;
; More implementation details.

;   Copyright 2018 The Lathe Authors
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


(require #/only-in racket/contract/base -> ->* any any/c cons/c)
(require #/only-in racket/contract/region define/contract)

(require #/only-in lathe-comforts dissect dissectfn expect fn)
(require #/only-in lathe-comforts/list list-foldl list-foldr)
(require #/only-in lathe-comforts/struct struct-easy)

(provide #/all-defined-out)



; ===== Miscellaneous definitions that haven't been sorted yet =======


; These definitions are based on the docummented signatures in
; private.rkt. We're using an encoding where all those signatures are
; thought of as a dependent sum at the top level, and:
;
;  - A dependent sum or binary product is represented as a cons cell
;    if both of its elements have run time content, with no run time
;    content at all if neither does, and as only the value that has
;    run time content if there's only one.
;  - A dependent product is represented as a function if both its
;    domain and codomain have run time content, with no run time
;    content at all if the codomain doesn't have run time content, and
;    as only a codomain value if that one has run time content and the
;    domain doesn't.
;  - A type has no run time content.
;  - An equivalence has no run time content.
;  - A value in layer 1 has no run time content.
;  - A value in layer 2 does have run time content, and this run time
;    content is a value that is completely unverified. As we reason
;    about equivalences on these run time values, these values are
;    considered equivalent when they lead to pretty much the same
;    observations, with some exceptions so that `eq?` observations and
;    other unsafe observations don't disturb equivalences that would
;    otherwise hold just fine.
;  - At the outermost level, if the entire type has no run time
;    content but we must represent its values anyway, we represent
;    them as an empty list.


(struct-easy (category rep))

(define/contract (make-category id compose)
  (-> any/c (-> (cons/c any/c any/c) any) category?)
  (category #/cons id #/dissectfn (cons g f) #/compose g f))

(define/contract (category-compose-list c args)
  (-> category? list? any)
  (expect c (category #/cons id compose)
    (error "Expected a category based on the morphisms-as-values theories")
  #/list-foldr id args #/fn g f
    (compose #/cons g f)))

(define/contract (category-compose c . args)
  (->* (category?) #:rest list? any)
  (category-compose-list c args))

(define/contract (category-seq-list c args)
  (-> category? list? any)
  (expect c (category #/cons id compose)
    (error "Expected a category based on the morphisms-as-values theories")
  #/list-foldl id args #/fn f g
    (compose #/cons g f)))

(define/contract (category-seq c . args)
  (->* (category?) #:rest list? any)
  (category-seq-list c args))


(struct-easy (functor rep))

(define/contract (make-functor map)
  (-> (-> any/c any) functor?)
  (functor #/fn morphism #/map morphism))

(define/contract (functor-map ftr morphism)
  (-> functor? any/c any)
  (dissect ftr (functor map)
  #/map morphism))

(define/contract (functor-id)
  (-> functor?)
  (make-functor #/fn morphism morphism))

(define/contract (functor-compose g f)
  (-> functor? functor? functor?)
  (make-functor #/fn morphism
    (functor-map g #/functor-map f morphism)))

; TODO: Can we also represent horizontal functor composition?


(struct-easy (natural-transformation rep))

(define/contract (make-natural-transformation component)
  (-> any/c natural-transformation?)
  (natural-transformation component))

(define/contract (natural-transformation-component nt)
  (-> natural-transformation? any/c)
  (dissect nt (natural-transformation component)
    component))


(struct-easy (terminal-object rep))

(define/contract (make-terminal-object terminal-map)
  (-> any/c terminal-object?)
  (terminal-object terminal-map))

(define/contract (terminal-object-terminal-map t)
  (-> terminal-object? any/c)
  (dissect t (terminal-object terminal-map)
    terminal-map))


(struct-easy (particular-binary-product rep))

(define/contract (make-particular-binary-product fst snd pair)
  (-> any/c any/c (-> any/c any/c any/c) particular-binary-product?)
  (particular-binary-product #/list* fst snd #/dissectfn (cons sa sb)
    (pair sa sb)))

(define/contract (particular-binary-product-fst p)
  (-> particular-binary-product? any/c)
  (dissect p (particular-binary-product #/list* fst snd pair)
    fst))

(define/contract (particular-binary-product-snd p)
  (-> particular-binary-product? any/c)
  (dissect p (particular-binary-product #/list* fst snd pair)
    snd))

(define/contract (particular-binary-product-pair p sa sb)
  (-> particular-binary-product? any/c any/c any/c)
  (dissect p (particular-binary-product #/list* fst snd pair)
  #/pair #/cons sa sb))


(struct-easy (binary-products rep))

(define/contract (make-binary-products fst snd pair)
  (-> any/c any/c (-> any/c any/c any/c) binary-products?)
  (binary-products #/list* fst snd #/dissectfn (cons sa sb)
    (pair sa sb)))

(define/contract (binary-products-fst p)
  (-> binary-products? any/c)
  (dissect p (binary-products #/list* fst snd pair)
    fst))

(define/contract (binary-products-snd p)
  (-> binary-products? any/c)
  (dissect p (binary-products #/list* fst snd pair)
    snd))

(define/contract (binary-products-pair p sa sb)
  (-> binary-products? any/c any/c any/c)
  (dissect p (binary-products #/list* fst snd pair)
  #/pair #/cons sa sb))


(define/contract (general-to-particular-binary-product bp)
  (-> binary-products? particular-binary-product?)
  (dissect bp (binary-products rep)
  #/particular-binary-product rep))


(struct-easy (particular-pullback rep))

(define/contract (make-particular-pullback at bt fst snd pair)
  (-> any/c any/c any/c any/c (-> any/c any/c any/c)
    particular-pullback?)
  (particular-pullback #/list* at bt fst snd #/dissectfn (cons sa sb)
    (pair sa sb)))

(define/contract (particular-pullback-at p)
  (-> particular-pullback? any/c)
  (dissect p (particular-pullback #/list* at bt fst snd pair)
    at))

(define/contract (particular-pullback-bt p)
  (-> particular-pullback? any/c)
  (dissect p (particular-pullback #/list* at bt fst snd pair)
    bt))

(define/contract (particular-pullback-fst p)
  (-> particular-pullback? any/c)
  (dissect p (particular-pullback #/list* at bt fst snd pair)
    fst))

(define/contract (particular-pullback-snd p)
  (-> particular-pullback? any/c)
  (dissect p (particular-pullback #/list* at bt fst snd pair)
    snd))

(define/contract (particular-pullback-pair p sa sb)
  (-> particular-pullback? any/c any/c any/c)
  (dissect p (particular-pullback #/list* at bt fst snd pair)
  #/pair #/cons sa sb))


(struct-easy (pullbacks rep))

(define/contract (make-pullbacks fst snd pair)
  (->
    (-> any/c any/c any/c)
    (-> any/c any/c any/c)
    (-> any/c any/c any/c any/c any/c)
    pullbacks?)
  (pullbacks #/list*
    (dissectfn (cons at bt) #/fst at bt)
    (dissectfn (cons at bt) #/snd at bt)
    (dissectfn (list* at bt sa sb) #/pair at bt sa sb)))

(define/contract (pullbacks-fst p at bt)
  (-> pullbacks? any/c any/c any/c)
  (dissect p (pullbacks #/list* fst snd pair)
  #/fst #/cons at bt))

(define/contract (pullbacks-snd p at bt)
  (-> pullbacks? any/c any/c any/c)
  (dissect p (pullbacks #/list* fst snd pair)
  #/snd #/cons at bt))

(define/contract (pullbacks-pair p at bt sa sb)
  (-> pullbacks? any/c any/c any/c any/c any/c)
  (dissect p (pullbacks #/list* fst snd pair)
  #/pair #/list* at bt sa sb))


(define/contract (general-to-particular-pullback p at bt)
  (-> pullbacks? any/c any/c particular-pullback?)
  (make-particular-pullback
    (pullbacks-fst p at bt)
    (pullbacks-snd p at bt)
    (fn sa sb #/pullbacks-pair p at bt sa sb)))
