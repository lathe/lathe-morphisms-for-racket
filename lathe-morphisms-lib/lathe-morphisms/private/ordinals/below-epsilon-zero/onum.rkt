#lang parendown racket/base

; lathe-morphisms/private/ordinals/under-epsilon-zero/onum
;
; Cantor normal form numerals (in base omega) for computing on ordinal
; numbers less than epsilon zero. Epsilon zero is equal to omega
; raised to epsilon zero, and it's the first ordinal number with this
; property. Omega is the first infinite ordinal.

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


(require #/only-in racket/contract/base
  -> ->* any/c list/c listof or/c)
(require #/only-in racket/contract/region define/contract)
(require #/only-in racket/math natural?)

(require #/only-in lathe-comforts dissect expect fn mat w- w-loop)
(require #/only-in lathe-comforts/maybe just maybe/c nothing)
(require #/only-in lathe-comforts/list
  list-each list-foldl list-foldr)
(require #/only-in lathe-comforts/struct struct-easy)

; TODO: Document all of these exports.
(provide
  (rename-out
    [-onum? onum?]
    [-onum-base-omega-expansion onum-base-omega-expansion]
  )
  onum-compare onum<? onum>? onum<=? onum>=?
  onum-zero nat->onum onum-plus1
  onum-plus-list onum-plus
  onum-drop1
  onum-drop
  ; TODO: So far, the user of this module can't construct any infinite
  ; ordinals. Fix this. We'll probably want exports called
  ; `onum-omega`, `onum-times-list`, `onum-times`, `onum-pow-list`,
  ; and `onum-pow`.
)



(struct-easy (onum base-omega-expansion) #:equal
  (#:guard-easy
    (unless (list? base-omega-expansion)
      (error "Expected base-omega-expansion to be a list"))
    (list-each base-omega-expansion #/fn term
      (expect term (list power coefficient)
        (error "Expected each term to be a two-element list")
      #/begin
        (unless (onum? power)
          (error "Expected each power to be an onum"))
        (unless (exact-positive-integer? coefficient)
          (error "Expected each coefficient to be an exact positive integer"))))
    (list-foldl (nothing) base-omega-expansion #/fn prev-power term
      (dissect term (list power coefficient)
      #/expect prev-power (just prev-power) (just power)
      #/expect (onum-compare prev-power power) '>
        (error "Expected each power to be strictly less than the last")
      #/just power))))

; NOTE: This is just like `onum?` except for its interaction with
; `struct-predicate-procedure?`.
(define/contract (-onum? x)
  (-> any/c boolean?)
  (onum? x))

; NOTE: This is just like `onum?` except for its interaction with
; `struct-accessor-procedure?`.
(define/contract (-onum-base-omega-expansion n)
  (-> onum? #/listof #/list/c onum? exact-positive-integer?)
  (dissect n (onum n)
    n))

; TODO: Put this in Lathe Comforts.
(define/contract (nat-compare a b)
  (-> natural? natural? #/or/c '< '= '>)
  (if (< a b) '<
  #/if (= a b) '=
    '>))

(define/contract (onum-compare a b)
  (-> onum? onum? #/or/c '< '= '>)
  (dissect a (onum a)
  #/dissect b (onum b)
  #/w-loop next a a b b
    (expect a (cons a-first a-rest) (mat b (list) '= '<)
    #/expect b (cons b-first b-rest) '>
    #/dissect a-first (list a-power a-coefficient)
    #/dissect b-first (list b-power b-coefficient)
    #/w- power-comparison (onum-compare a-power b-power)
    #/expect power-comparison '= power-comparison
    #/w- coefficient-comparison
      (nat-compare a-coefficient b-coefficient)
    #/expect coefficient-comparison '= coefficient-comparison
    #/next a-rest b-rest)))

(define/contract (onum<? a b)
  (-> onum? onum? boolean?)
  (eq? '< #/onum-compare a b))

(define/contract (onum>? a b)
  (-> onum? onum? boolean?)
  (eq? '> #/onum-compare a b))

(define/contract (onum<=? a b)
  (-> onum? onum? boolean?)
  (not #/onum>? a b))

(define/contract (onum>=? a b)
  (-> onum? onum? boolean?)
  (not #/onum<? a b))

(define/contract onum-zero onum? (onum #/list))

(define/contract (nat->onum n)
  (-> natural? onum?)
  (mat n 0 onum-zero
  #/onum #/list #/list onum-zero n))

; This is increment by way of addition on the left. We're finding
; `(onum-plus (nat->onum 1) n)`.
(define/contract (onum-plus1 n)
  (-> onum? onum?)
  (dissect n (onum n)
  #/expect (reverse n) (cons last rev-past)
    (nat->onum 1)
  #/dissect last (list power coefficient)
  #/if (equal? onum-zero power)
    (onum #/reverse #/cons (list power #/add1 coefficient) rev-past)
    (onum #/reverse #/list* (list onum-zero 1) last rev-past)))

; TODO: Put this in Lathe Comforts.
(define/contract (list-rev-onto source target)
  (-> list? any/c any/c)
  (expect source (cons first rest) target
  #/list-rev-onto rest #/cons first target))

(define/contract (onum-plus-binary a b)
  (-> onum? onum? onum?)
  (dissect a (onum a-expansion)
  #/dissect b (onum b-expansion)
  #/expect b-expansion (cons b-first b-rest) a
  #/dissect b-first (list b-power b-coefficient)
  #/w-loop next rev-a (reverse a-expansion)
    (expect rev-a (cons rev-a-first rev-a-rest) b
    #/dissect rev-a-first (list a-power a-coefficient)
    #/w- comparison (onum-compare a-power b-power)
    #/mat comparison '< (next rev-a-rest)
    #/mat comparison '> (onum #/list-rev-onto rev-a b-expansion)
    #/onum
    #/list-rev-onto rev-a-rest
    #/cons (list b-power #/+ a-coefficient b-coefficient) b-rest)))

(define/contract (onum-plus-list ns)
  (-> (listof onum?) onum?)
  (list-foldr ns onum-zero #/fn a b #/onum-plus-binary a b))

(define/contract (onum-plus . ns)
  (->* () #:rest (listof onum?) onum?)
  (onum-plus-list ns))

; This is decrement by way of left subtraction. We're finding the
; value `result` such that
; `(equal? (onum-plus (nat->onum 1) result) n)`, if it exists. It
; exists as long as `(nat->onum 1)` is less than or equal to `n`.
(define/contract (onum-drop1 n)
  (-> onum? #/maybe/c onum?)
  (dissect n (onum n-expansion)
  #/expect (reverse n-expansion) (cons last rev-past) (nothing)
  #/dissect last (list power coefficient)
  #/expect (equal? onum-zero power) #t (just n)
  #/w- coefficient (sub1 coefficient)
  #/just #/onum #/reverse
  #/mat coefficient 0 rev-past
  #/cons (list power coefficient) rev-past))

; This is left subtraction. We're finding the value `result` such that
; `(equal? (onum-plus amount result) n)`, if it exists. It exists as
; long as `amount` is less than or equal to `n`.
(define/contract (onum-drop amount n)
  (-> onum? onum? #/maybe/c onum?)
  (dissect amount (onum amount-expansion)
  #/dissect n (onum n-expansion)
  #/w-loop next
    amount-expansion amount-expansion
    n-expansion n-expansion
    
    (expect n-expansion (cons n-first n-rest)
      (mat amount-expansion (list) (just onum-zero)
      #/nothing)
    #/dissect n-first (list n-power n-coefficient)
    #/expect amount-expansion (cons amount-first amount-rest)
      (just #/onum n-expansion)
    #/dissect amount-first (list amount-power amount-coefficient)
    #/w- power-comparison (onum-compare amount-power n-power)
    #/mat power-comparison '> (nothing)
    #/mat power-comparison '< (next amount-rest n-expansion)
    #/w- coefficient-comparison
      (nat-compare amount-coefficient n-coefficient)
    #/mat coefficient-comparison '> (nothing)
    #/mat coefficient-comparison '= (next amount-rest n-rest)
    #/onum
    #/cons (list n-power #/- n-coefficient amount-coefficient)
      n-rest)))
