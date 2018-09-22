#lang parendown racket/base

; lathe-morphisms/private/logic
;
; Interfaces for logics, especially classical logic. Even if the logic
; itself is classical, the way we construct proofs or derivations can
; still be constructive.

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


; TODO: This file is still a work in progress. Uncomment it all once
; it's ready to run without errors. We'll probably be reconsidering
; the way we factor this out so that it'll be more like a category
; theory/calculus of structures design, as discussed in these papers:
;
;
; A paper outlining the local SKS proof system in the calculus of
; structures style, made up of a switch rule, a medial rule, and three
; dual pairs of rules for the atoms (introduction, contraction, and
; weakening):
;
;   Deep Inference and Symmetry in Classical Proofs
;   Kai Brünnler
;   http://cs.bath.ac.uk/ag/kai/phd.pdf
;
; I consider it valuable to isolate the atoms so that if and when our
; logics need more complicated propositions (like formulas), the
; designs of the extensions which define those propositions can be
; guided by specific goals (defining introduction, contraction, and
; weakening).
;
;
; A paper which bridges the gap from there to the terminology of
; category theory:
;
;   Deep Inference Proof Theory Equals Categorical Proof Theory Minus Coherence
;   Dominic Hughes 2004
;   http://boole.stanford.edu/~dominic/papers/di/di.pdf
;
;
; A paper which looks in depth at what coherence conditions we might
; impose on SKS if it were a category where equalities between
; morphisms mattered:
;
;   On the Axiomatisation of Boolean Categories with and without Medial
;   Lutz Straßburger 2006-2007
;   https://www.lix.polytechnique.fr/~lutz/papers/medial.pdf
;
; In our case, distinguishing between derivations of the same formulas
; can matter to us for a few reasons:
;
;   * Different derivations may have different performance
;     characteristics.
;
;   * We anticipate a pure functional style, but different derivations
;     may be visibly different when user-supplied code violates this
;     style.
;
;   * We may want to keep track of whether a derivation depends on
;     something like the law of excluded middle. For instance, we
;     could treat the law of excluded middle as a side effect in an
;     effect typing system, while maintaining the property that the
;     system is still classical logic when we erase the effect type
;     annotations.
;
;   * Different derivations may call for displaying different error
;     messages when they go wrong.
;
; However, the classical logic systems we develop in this file are
; intended only to let us develop a definition of categories where the
; equalities are classical rather than constructive in content. Some
; instances of classical logics will let us do nothing constructive
; with them except to promote unsoundness in the logic (a derivation
; of false) to unsoundness in the host language (raising an error), so
; the abstraction we make here won't always have all the extra power
; of distinguishing one derivation from another anyway.
;
; (On the other hand, that triviality is exactly why it's tricky to
; decide on a design. We don't really have distinct use cases yet.)
;
; The paper's approach is summarized at the start of section 8,
; "Beyond medial," on page 47. The paper proceeds through a series of
; designs for categories which have more coherence laws but which
; don't have quite so many that they become trivial:
;
;   * Categories with two monoidal structures (`and` & `or`).
;
;   * The laws of *-autonomous categories to determine that the two
;     monoidal structures are related to each other by a isomorphism
;     that acts as the negation operator.
;
;   * The specification that there exists a monoid on `or` and a
;     comonoid on `and`. While the two monoidal structures of the
;     category are what allows `and` and `or` to be operators at the
;     formula level, these two (co)monoids specify that derivations
;     can be equal to each other even if they're built by using
;     multiple instances of contraction in different orders. The paper
;     calls this a "B1-category."
;
;   * "[...] the structure of B2-categories allows the [or]-monoidal
;     structure to go well with the [or]-monoids and the
;     [and]-monoidal structure to go well with the [and]-comonoids."
;
;   * "[...] the structure of B4-categories ensures that both monoidal
;     structures go well with the [or]-monoids *and* the
;     [and]-comonoids."
;
;   * B5-categories deal with "how the [or]-monoids and the
;     [and]-comonoids go along with each other." A distinction is
;     made between "weakly flat" and "flat" conditions here: If the
;     (co)monoids get along perfectly, the system becomes "flat,"
;     losing a finitely generating cut rule because we can't
;     distinguish how many times contraction is used next to a cut
;     rule (or something like that).
;
;   * Along the way, the paper introduces a few other conditions it
;     keeps separate from its progression of categories: Besides
;     "weakly flat" and "flat," "single-mixed" is another important
;     one. The example they give of a single-mixed category is a
;     derivation system that's decorated with atomic flows that join
;     up at nodes (instances of mix: A and B |- A or B) and separate
;     again. Presumably in a similar category which does not enforce
;     the single-mix condition on its derivations of
;     (A and B |- A or B), its atomic flows would not have nodes but
;     instead braids or something.

#|

(provide #/all-defined-out)



; ===== Miscellaneous definitions that haven't been sorted yet =======

(struct-easy
  (logic-with-impl-rep
    make-wff-impl
    modus-ponens
    internal-modus-ponens
    internal-flipped-modus-ponens))

(define/contract
  (make-logic-with-impl
    make-wff-impl
    modus-ponens
    internal-modus-ponens
    internal-flipped-modus-ponens)
  (->
    (-> any/c any/c any/c)
    (-> any/c any/c any/c any/c any/c)
    (-> any/c any/c any/c any/c any/c)
    (-> any/c any/c any/c any/c any/c)
    logic-with-impl?)
  (logic-with-impl-rep
    make-wff-impl
    modus-ponens
    internal-modus-ponens
    internal-flipped-modus-ponens))

; Given formulas `A` and `B`, returns the formula `A -> B`.
(define/contract (logic-with-impl-make-wff-impl logic a b)
  (-> logic-with-impl? any/c any/c any/c)
  ((logic-with-impl-rep-make-wff-impl logic) a b))

; Given formulas `A` and `B` and proofs of `A -> B` and `A`, returns a
; proof of `B`.
(define/contract (logic-with-impl-modus-ponens logic a b abpf apf)
  (-> logic-with-impl? any/c any/c any/c any/c any/c)
  ((logic-with-impl-rep-modus-ponens logic) a b abpf apf))

; Given formulas `A1`, `A2`, `B1`, and `B2`, returns a proof of
; `(A1 -> A2) -> ((B1 -> B2) -> ((A2 -> B1) -> (A1 -> B2)))`.
(define/contract
  (logic-with-impl-internal-modus-ponens logic a1 a2 b1 b2)
  (-> logic-with-impl? any/c any/c any/c any/c any/c)
  ((logic-with-impl-rep-internal-modus-ponens logic) a1 a2 b1 b2))

; Given formulas `A1`, `A2`, `B1`, and `B2`, returns a proof of
; `(A1 -> A2) -> ((B1 -> B2) -> (A1 -> ((A2 -> B1) -> B2)))`.
(define/contract
  (logic-with-impl-internal-flipped-modus-ponens logic a1 a2 b1 b2)
  (-> logic-with-impl? any/c any/c any/c any/c any/c)
  ( (logic-with-impl-rep-internal-flipped-modus-ponens logic)
    a1 a2 b1 b2))


(struct-easy (formula-unknown a))
(struct-easy (formula-impl t:a t:b))
(struct-easy (tagged t:a pf:a))

; Given a known type tag `A`, returns the formula `A`.
(define/contract
  (logic-with-impl-interpret-formula logic interpret-unknown t:a)
  (-> logic-with-impl? (-> any/c any/c) any/c any/c)
  (mat t:a (formula-impl t:a t:b)
    (logic-with-impl-make-wff-impl logic
      (logic-with-impl-interpret-formula logic interpret-unknown t:a)
      (logic-with-impl-interpret-formula logic interpret-unknown t:b))
  #/interpret-unknown t:a))

; Given a type-tagged proof of `A -> B` and an untagged proof of `A`,
; returns a type-tagged proof of `B`.
(define/contract
  (logic-with-impl-tagged-modus-ponens logic interpret-unknown
    tpf:->ab pf:a)
  (-> logic-with-impl? (-> any/c any/c) tagged? any/c tagged?)
  (dissect tpf:->ab (tagged t:->ab pf:->ab)
  #/expect t:->ab (formula-impl t:a t:b)
    (error "Expected an implication proof")
  #/logic-with-impl-modus-ponens logic
    (logic-with-impl-interpret-formula logic interpret-unknown t:a)
    (logic-with-impl-interpret-formula logic interpret-unknown t:b)
    pf:->ab
    pf:a))

; Given type-tagged proofs of `A1 -> A2` and `B1 -> B2`, returns a
; type-tagged proof of `(A2 -> B1) -> (A1 -> B2)`.
(define/contract
  (logic-with-impl-tagged-internal-modus-ponens
    logic interpret-unknown tpf:->a1a2 tpf:->b1b2)
  (-> logic-with-impl? (-> any/c any/c) tagged? tagged? tagged?)
  (dissect tpf:->a1a2 (tagged t:->a1a2 pf:->a1a2)
  #/expect t:->a1a2 (formula-impl t:a1 t:a2)
    (error "Expected an implication proof")
  #/dissect tpf:->b1b2 (tagged t:->b1b2 pf:->b1b2)
  #/expect t:->b1b2 (formula-impl t:b1 t:b2)
    (error "Expected an implication proof")
  #/w- -> tagged-impl
  #/logic-with-impl-tagged-modus-ponens logic interpret-unknown
    (logic-with-impl-tagged-modus-ponens logic interpret-unknown
      (tagged
        (-> t:->a1a2 #/-> t:->b1b2 #/-> (-> t:a2 t:b1) (-> t:a1 t:b2))
      #/logic-with-impl-internal-modus-ponens logic
        (logic-with-impl-interpret-formula logic interpret-unknown
          t:a1)
        (logic-with-impl-interpret-formula logic interpret-unknown
          t:a2)
        (logic-with-impl-interpret-formula logic interpret-unknown
          t:b1)
        (logic-with-impl-interpret-formula logic interpret-unknown
          t:b2))
      pf:->a1a2)
    pf:->b1b2))

; Given type-tagged proofs of `A1 -> A2` and `B1 -> B2`, returns a
; type-tagged proof of `A1 -> ((A2 -> B1) -> B2)`.
(define/contract
  (logic-with-impl-tagged-flipped-modus-ponens
    logic interpret-unknown tpf:->a1a2 tpf:->b1b2)
  (-> logic-with-impl? (-> any/c any/c) tagged? tagged? tagged?)
  (dissect tpf:->a1a2 (tagged t:->a1a2 pf:->a1a2)
  #/expect t:->a1a2 (formula-impl t:a1 t:a2)
    (error "Expected an implication proof")
  #/dissect tpf:->b1b2 (tagged t:->b1b2 pf:->b1b2)
  #/expect t:->b1b2 (formula-impl t:b1 t:b2)
    (error "Expected an implication proof")
  #/w- -> tagged-impl
  #/logic-with-impl-tagged-modus-ponens logic interpret-unknown
    (logic-with-impl-tagged-modus-ponens logic interpret-unknown
      (tagged
        (-> t:->a1a2 #/-> t:->b1b2 #/-> t:a1 #/-> (-> t:a2 t:b1) t:b2)
      #/logic-with-impl-internal-flipped-modus-ponens logic
        (logic-with-impl-interpret-formula logic interpret-unknown
          t:a1)
        (logic-with-impl-interpret-formula logic interpret-unknown
          t:a2)
        (logic-with-impl-interpret-formula logic interpret-unknown
          t:b1)
        (logic-with-impl-interpret-formula logic interpret-unknown
          t:b2))
      pf:->a1a2)
    pf:->b1b2))

; Given a type tag `A` with a known axiom `A -> A`, returns that
; type-tagged proof of `A -> A`.
(define/contract
  (logic-with-impl-axiom logic interpret-unknown axiom-unknown t:a)
  (-> logic-with-impl? (-> any/c any/c) (-> any/c tagged?) any/c
    tagged?)
  (mat t:a (formula-impl t:a t:b)
    (logic-with-impl-tagged-modus-ponens logic interpret-unknown
      (logic-with-impl-axiom logic interpret-unknown axiom-unknown
        t:a)
      (logic-with-impl-axiom logic interpret-unknown axiom-unknown
        t:b))
  #/axiom-unknown t:a))

; Given a type-tagged proof of `A -> (B -> C)` where `B` and `C` have
; known axioms `B -> B` and `C -> C`, returns a type-tagged proof of
; `B -> (A -> C)`.
;
; We do this by first constructing this result of the internal
; flipped modus ponens:
;
;   B -> ((B -> C) -> C)
;
; Then, we use the internal modus ponens (which gives us functoriality
; for the `->` connective) twice to apply the `A -> (B -> C)` two
; levels deep in that formula in a negative position, giving us:
;
;   B -> (A -> C)
;
; Both these steps rely on `B` and `C` being type tags with known
; axioms `B -> B` and `C -> C`.
;
(define/contract
  (logic-with-impl-flip logic interpret-unknown axiom-unknown
    tpf:->a->bc)
  (-> logic-with-impl? (-> any/c any/c) (-> any/c tagged?) tagged?
    tagged?)
  (dissect tpf:->a->bc (tagged t:->a->bc pf:->a->bc)
  #/expect t:->a->bc (tagged-impl t:a #/tagged-impl t:b t:c)
    (error "Expected the given proof to be tagged with a type of the form A -> (B -> C)")
  #/w- tpf:->bb
    (logic-with-impl-axiom logic interpret-unknown axiom-unknown t:b)
  #/w- tpf:->cc
    (logic-with-impl-axiom logic interpret-unknown axiom-unknown t:c)
  #/w- tpf:->b->->bcc
    (logic-with-impl-tagged-flipped-modus-ponens logic
      interpret-unknown
      tpf:->bb
      tpf:->cc)
  #/logic-with-impl-tagged-modus-ponens logic interpret-unknown
    (logic-with-impl-tagged-internal-modus-ponens logic
      interpret-unknown
      tpf:->bb
      (logic-with-impl-tagged-internal-modus-ponens logic
        interpret-unknown
        tpf:->a->bc
        tpf:->cc))
    tpf:->b->->bcc))


(struct-easy
  (logic-with-false-rep logic-with-impl make-wff-false absurd))

(define/contract
  (make-logic-with-false logic-with-impl make-wff-false absurd)
  (-> logic-with-impl? (-> any/c) (-> any/c any/c) logic-with-false?)
  (logic-with-false-rep logic-with-impl make-wff-false absurd))

(define/contract (logic-with-false-logic-with-impl logic)
  (-> logic-with-false? logic-with-impl?)
  (logic-with-false-rep-logic-with-impl logic))

; Returns the formula `f`.
(define/contract (logic-with-false-make-wff-false logic)
  (-> logic-with-false? any/c)
  (#/logic-with-false-rep-make-wff-false logic))

; Given a formula `A`, returns a proof of `f -> A`.
(define/contract (logic-with-false-absurd logic a)
  (-> logic-with-false? any/c any/c)
  ((logic-with-false-rep-absurd logic) a))


(struct-easy (formula-false))

; Given a known type tag `A`, returns the formula `A`.
(define/contract
  (logic-with-false-interpret-formula logic interpret-unknown t:a)
  (-> logic-with-false? (-> any/c any/c) any/c any/c)
  (w- logic-with-impl (logic-with-false-logic-with-impl logic)
  #/mat t:a (formula-false)
    (logic-with-false-make-wff-false logic)
  #/logic-with-impl-interpret-formula logic interpret-unknown t:a))

; Given a type tag `A`, returns a type-tagged proof of `f -> A`.
(define/contract
  (logic-with-false-tagged-absurd logic interpret-unknown t:a)
  (-> logic-with-false? (-> any/c any/c) any/c tagged?)
  (w- a
    (logic-with-false-interpret-formula logic interpret-unknown t:a)
  #/tagged (tagged-impl (tagged-false) t:a)
  #/logic-with-false-absurd logic a))

; Given a type tag `A` with a known axiom `A -> A`, returns that
; type-tagged proof of `A -> A`.
(define/contract
  (logic-with-false-axiom logic interpret-unknown axiom-unknown t:a)
  (-> logic-with-false? (-> any/c any/c) (-> any/c tagged?) any/c
    tagged?)
  (w- logic-with-impl (logic-with-false-logic-with-impl logic)
  #/mat t:a (formula-false)
    (logic-with-false-tagged-absurd logic interpret-unknown
    #/tagged-false)
  #/logic-with-impl-axiom logic interpret-unknown axiom-unknown t:a))


; TODO: From here. (Well, not from here, because we're going to take a
; calculus of structures approach instead; see above.)
;
; The next function below hit a snag as I was implementing it. So I
; didn't finish implementing it, I changed the comment to reflect a
; new design I was going to try, and then I realized this design was
; a tautology for all values of `f`... so I went back to the above and
; started to introduce an `f -> A` axiom schema instead of the "prove
; weakening (`f -> A` and `A -> t`) for every connective and atom
; separately" approach I had been taking. Then I got a bit stuck doing
; that, especially with the thought that if I had a rule `f -> A` for
; arbitrary `A`, I might as well have a rule `A -> A` as well... so I
; went back and tried to remind myself how the calculus of structures
; system SKS did what I was trying to do here -- separating weakening,
; contraction, and introduction into atomic rules.
;
; Based on that study, I wrote the long comment above and decided it
; was time to commit this. This file is an interesting body of code,
; but it's about to be scrapped, and the new approach is going to have
; a lot more operations to juggle (associativity laws, commutativity
; laws, unit laws, explicit De Morgan rules...). By the time I finish
; that, I might be missing this old small-and-tidy-set-of-axioms
; system already.
;
; There are a bunch of comments below the next function, describing
; the sets of axioms I was considering. Like a lot of my notes, these
; have been written in chunks from the bottom up. (When I want a clean
; slate to start a new draft of an idea, but my old draft is still too
; valuable as reference to simply delete, I push the old stuff down
; and start again above it.)



; Given formulas `A` and `B`, returns a proof of
;
;   (A -> (f -> f)) -> ((f -> B) -> (f -> (A -> B)))
;
(define/contract
  (logic-with-false-absurd-impl logic a b pf:->at pf:->fb)
  (-> logic-with-false? any/c any/c)
  (w- f (logic-with-false-make-wff-false logic)
  #/w- pf:t (logic-with-false-get-false-axiom logic)
  #/w- logic (logic-with-false-logic-with-impl logic)
  #/w- ->
    (fn a b #/logic-with-impl-make-wff-impl logic a b)
  #/w- mp
    (fn a b pf:->ab pf:a
      (logic-with-impl-modus-ponens logic a b pf:->ab pf:a))
  #/w- imp
    (fn a1 a2 b1 b2
      (logic-with-impl-internal-modus-ponens logic a1 a2 b1 b2))
  #/w- fmp
    (fn a1 a2 b1 b2
      (logic-with-impl-internal-flipped-modus-ponens logic
        a1 a2 b1 b2))
  #/w- imp-- (fn a b #/fmp a a b b)
  #/w- imp--!
    (fn a b pf:->aa
      (mp (-> a a) (-> (-> b b) #/-> (-> a b) (-> a b))
        (imp-- a b)
        pf:->aa))
  #/w- imp--!!
    (fn a b pf:->aa pf:->bb
      (mp (-> b b) (-> (-> a b) (-> a b))
        (imp--! a b pf:->aa)
        pf:->bb))
  #/w- fmp-- (fn a b #/fmp a a b b)
  #/w- t (-> f f)
  #/w- pf:->->tff
    (mp t (-> (-> t f) f)
      (mp t (-> t #/-> (-> t f) f)
        (mp (-> t t) (-> t #/-> t #/-> (-> t f) f)
          (fmp-- t f)
          (imp--!! f f pf:t pf:t))
        pf:t)
      pf:t)
  #/w- pf:->->tf->ab
    (mp (-> f b) (-> (-> t f) (-> a b))
      (mp (-> a t) (-> (-> f b) #/-> (-> t f) (-> a b))
        (fmp a t f b)
        pf:->at)
      pf:->fb)
  (#/logic-with-false-rep-get-false-axiom logic))

X -> ((X -> ((A -> B) -> (A -> B))) -> (A -> B) -> (A -> B))

; from A -> B and A derive B
; from nothing derive (A -> A') -> ((B -> B') -> ((A' -> B) -> (A -> B')))
; from nothing derive (A -> A') -> ((B -> B') -> (A -> ((A' -> B) -> B')))
; from f derive a contradiction
; from nothing derive f -> f
; derivable: from A -> (f -> f) and f -> B we can derive ((f -> f) -> f) -> (A -> B) using the functoriality axioms, and then we can apply the functoriality axiom again to get f -> (A -> B) by instantiating out-of-order internal modus ponens A -> ((A -> B) -> B) with A = (f -> f) and b = f and applying modus ponens to get (((f -> f) -> f) -> f).

; from nothing derive f 

; from (A' -> A) and (B -> B') derive (A -> B) -> (A' -> B')
; from ((A -> B) -> B) and (C -> (A -> C)) derive (B -> C) -> ((A -> B) -> (A -> C))


; from nothing derive A -> A
; from nothing derive (A -> B) -> ((B -> C) -> (A -> C))
; from nothing derive (B -> C) -> ((A -> B) -> (A -> C))
; from A -> B and A derive B
; from nothing derive (A -> B) -> (A -> B)
; from nothing derive A -> ((A -> B) -> B)
; from (A' -> A) and (B -> B') derive (A -> B) -> (A' -> B')
; from nothing derive (A' -> A) -> ((B -> B') -> ((A -> B) -> (A' -> B')))
; from nothing derive (B -> B') -> ((A' -> A) -> ((A -> B) -> (A' -> B')))

; from nothing derive t -> t
; from nothing derive f -> f
; from nothing derive t
; from nothing derive t -> t
; from a contradiction derive t
; from nothing derive f -> t
; from a contradiction derive f
; from nothing derive f -> f
; from a contradiction derive (A -> B)
; from nothing derive (f -> t) -> t
; from nothing derive f -> (t -> f)
; from (f -> A) and (B -> (f -> f)) derive f -> (A -> B)
;   we can usually derive ((f -> f) -> f) -> (A -> B)
; from

; from f derive a contradiction
; from 


; from nothing derive (C1 -> (A -> B)) -> ((C2 -> A) -> (C1 -> (C2 -> B)))
;
; from t derive nothing
; from nothing derive (C -> t) -> t
; from nothing derive t
; from nothing derive C -> t
;   (The first, "from t derive nothing," is trivial.)
;   (The second is an instance of the fourth.)
;   (The third follows from the fourth by instantiating the fourth with C = t and C = (t -> t) and using modus ponens.)
;
; from f derive a contradiction
; from nothing derive (C -> f) -> (C -> A)
; from a contradiction derive f
; from nothing derive f -> (C -> f)
;   (The third, "from a contradiction derive f," is trivial.)
;  (
;
; from f -> A and B -> t derive (A -> B) -> t
; from nothing derive t -> t
; from nothing derive f -> t
;
; from f -> A and B -> t derive f -> (A -> B)
; from nothing derive f -> t
; from nothing derive f -> f
;



;
; from (C1 -> (C2 -> A)) derive (C2 -> (C1 -> A))


; `make-wff-impl`: Given two formulas `P` and `Q`, return a formula
;   `(P -> Q)`.
;
; `axiom`: Given a formula `P`, return a proof of `(P -> P)`.
;
; `bimap-impl`: Given proofs of `(P' -> P)` and `(Q -> Q')`, return a
; proof of `(P -> Q) -> (P' -> Q')`.
;
(define/contract (make-logic-with-impl make-wff-impl axiom bimap-impl)
  (->
    (-> any/c any/c any/c)
    (-> any/c any/c)
    (-> any/c any/c any/c any/c)
    logic-with-impl?)
  (logic-with-impl make-wff-impl axiom bimap-impl))


; How do we prove: (A -> (B -> A))?
; How do we prove: (C -> (A -> B)) -> ((C -> A) -> (C -> B))?


(struct-easy (logic-with-cut logic-with-impl interpret-impl))

(define/contract (make-logic-with-cut logic interpret-impl)
  (-> logic-with-impl? (-> any/c (-> any/c any/c)) logic-with-cut?)
  (logic-with-cut logic interpret-wff-impl))


|#
