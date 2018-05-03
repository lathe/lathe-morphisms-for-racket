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

(require #/only-in lathe-comforts
  dissect dissectfn expect fn mat w- w-loop)
(require #/only-in lathe-comforts/maybe just maybe/c nothing)
(require #/only-in lathe-comforts/list
  list-each list-foldl list-foldr list-map nat->maybe)
(require #/only-in lathe-comforts/struct struct-easy)

; TODO: Document all of these exports.
(provide
  (rename-out
    [-onum? onum?]
    [-onum-base-omega-expansion onum-base-omega-expansion]
  )
  onum-compare onum<? onum>? onum<=? onum>=?
  onum-zero onum-one onum-omega nat->onum onum-plus1
  onum-plus-list onum-plus
  onum-drop1
  onum-drop
  onum-times-list onum-times
  onum-untimes
  onum-pow-list onum-pow
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
(define/contract onum-one onum? (onum #/list #/list onum-zero 1))
(define/contract onum-omega onum? (onum #/list #/list onum-one 1))

(define/contract (nat->onum n)
  (-> natural? onum?)
  (mat n 0 onum-zero
  #/onum #/list #/list onum-zero n))

; This is increment by way of addition on the left. We're finding
; `(onum-plus onum-one n)`.
(define/contract (onum-plus1 n)
  (-> onum? onum?)
  (dissect n (onum n)
  #/expect (reverse n) (cons last rev-past) onum-one
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
; value `result` such that `(equal? (onum-plus onum-one result) n)`,
; if it exists. It exists as long as `onum-one` is less than or equal
; to `n`.
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

(define/contract (onum-times-binary a b)
  (-> onum? onum? onum?)
  (dissect a (onum a)
  #/dissect b (onum b)
  #/expect a (cons a-first a-rest) onum-zero
  #/dissect a-first (list a-power a-coefficient)
  #/onum-plus-list
  #/list-map b #/dissectfn (list b-power b-coefficient)
    (onum #/cons
      (list
        (onum-plus-binary a-power b-power)
        (if (equal? onum-zero b-power)
          (* a-coefficient b-coefficient)
          b-coefficient))
      a-rest)))

(define/contract (onum-times-list ns)
  (-> (listof onum?) onum?)
  (list-foldr ns onum-one #/fn a b #/onum-times-binary a b))

(define/contract (onum-times . ns)
  (->* () #:rest (listof onum?) onum?)
  (onum-times-list ns))

; TODO: All the procedures in this module need to be tested, but this
; one is especially tricky. Be sure to test this one.
;
; TODO: See if there's a better name for this than `onum-untimes`.
; Names connoting division would be great, but the order of arguments
; is the opposite as it usually is for division notation.
;
; This is left division. We're finding the value
; `(list quotient remainder)` such that `(onum<? remainder amount)`
; and `(equal? (onum-plus (onum-times amount quotient) remainder) n)`,
; if it exists. It exists as long as `amount` is nonzero.
(define/contract (onum-untimes amount n)
  (-> onum? onum? #/maybe/c #/list/c onum? onum?)
  (dissect amount (onum amount-expansion)
  #/expect amount-expansion (cons amount-first amount-rest) (nothing)
  #/dissect amount-first (list amount-power amount-coefficient)
  #/if (onum<? n amount) (just #/list onum-zero n)
  #/dissect n (onum #/cons (list n-power n-coefficient) n-rest)
  
  ; OPTIMIZATION: If both ordinals are finite, we can use Racket's
  ; `quotient/remainder` on the corresponding Racket integers.
  ;
  ; TODO: Test this without the optimization in place, for confidence
  ; that it's not changing the behavior.
  ;
  #/if (equal? onum-zero n-power)
    (let ()
      (define-values (q r)
        (quotient/remainder n-coefficient amount-coefficient))
      (just #/list (nat->onum q) (nat->onum r)))
  
  #/dissect
    (if (equal? amount-power n-power)
      (w- q-first-1 (quotient n-coefficient amount-coefficient)
      #/dissect (nat->maybe q-first-1) (just q-first-2)
      #/list q-first-1 q-first-2)
      (w- q-first
        (onum #/list (onum-drop amount-power n-power) n-coefficient)
      ; NOTE: The second element of this list doesn't matter because
      ; the first one is guaranteed to multiply to a value less than
      ; `n`.
      #/list q-first q-first))
    (list q-first-1 q-first-2)
  #/dissect
    
    ; We use a long division method where we divide the most
    ; significant digits, attempt to use that quotient of the digits
    ; as the most significant digit of the overall quotient, and if
    ; that's too big, we fall back to using the value one less than
    ; that.
    ;
    ; We don't have to worry about what "one less" means for infinite
    ; ordinals: If the quotient of the digits is infinite (because the
    ; digits are associated with different powers of omega), the first
    ; guess will always be small enough to work in the overall
    ; quotient. Specifically, the digit quotient is equal to the digit
    ; taken from `n`, and when it's multiplied by the `amount` digit
    ; on the left, nothing will happen; hence the subtraction will
    ; just remove that digit from `n`.
    ;
    (mat (onum-drop (onum-times-binary amount q-first-1) n)
      (just n-rest-1)
      (list q-first-1 n-rest-1)
    #/dissect (onum-drop (onum-times-binary amount q-first-2) n)
      (just n-rest-2)
      (list q-first-2 n-rest-2))
    (list q-first n-rest)
  #/dissect (onum-untimes amount n-rest) (just #/list q-rest r)
  #/just #/list (onum-plus-binary q-first q-rest) r))

(define/contract (onum-pow-by-nat base exponent)
  (-> onum? natural? onum?)
  (mat exponent 0 onum-one
  #/mat exponent 1 base
  ; We proceed by the method of exponentiation by parts: We recur on
  ; half the exponent and use that result twice in order to save on
  ; the overall number of multiplications performed.
  #/let-values
    ([(half-exponent parity) (quotient/remainder exponent 2)])
  #/w- sqrt-near-result (onum-pow-by-nat half-exponent)
  #/w- near-result
    (onum-times-binary sqrt-near-result sqrt-near-result)
  #/mat parity 0
    near-result
    (onum-times base near-result)))

; TODO: This one's also tricky. Let's make sure to test this.
(define/contract (onum-pow-binary base exponent)
  (-> onum? onum? onum?)
  (dissect base (onum base-expansion)
  #/dissect exponent (onum exponent-expansion)
  #/if (equal? onum-zero exponent) onum-one
  #/expect base-expansion (cons base-first base-rest) onum-zero
  #/dissect base-first (list base-first-power base-first-coefficient)
  #/dissect (onum-untimes onum-omega exponent)
    (just #/list exponent-limit-part-div-omega exponent-finite-part)
  #/dissect (onum->maybe-nat exponent-finite-part)
    (just exponent-finite-part)
  #/w- exponent-limit-part
    (onum-times onum-omega exponent-limit-part-div-omega)
  #/onum-times
    (onum
    #/list #/list (onum-times base-first-power exponent-limit-part) 1)
    (onum-pow-by-nat base exponent-finite-part)))

(define/contract (onum-pow-list ns)
  (-> (listof onum?) onum?)
  (list-foldr ns onum-one #/fn a b #/onum-pow-binary a b))

(define/contract (onum-pow . ns)
  (->* () #:rest (listof onum?) onum?)
  (onum-pow-list ns))

; TODO: See if we can define an `onum-log` operation that's related to
; `onum-pow` the way `onum-untimes` is related to `onum-times` and
; `onum-drop` is related to `onum-plus`. This operation would find
; the value `(list exponent factor term)` that solves
;
;   (equal? n
;     (onum-plus (onum-times (onum-pow amount exponent) factor) term))
;
; for a given `amount` and a given `n`, such that
; `(onum<? factor amount)` and
; `(onum<? term (onum-pow amount exponent))`.
