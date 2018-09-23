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
;   Kai Brünnler 2004
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

(define/contract (issym sym)
  (-> symbol? #/-> any/c boolean?)
  (fn v #/eq? sym v))

(define-simple-macro
  (define-matchable-syntax name:id on-expr:expr on-match:expr)
  (define-syntax name
    (let ([on-expr-result on-expr] [on-match-result on-match])
      (struct name ()
        #:property prop:procedure
        (fn self stx #/on-expr-result stx)
        #:property prop:match-expander
        (fn self stx #/on-match-result stx))
      (name))))

(define-simple-macro
  (struct-with-contracts
    internal-name:id
    faux-predicate?:id
    faux-unmatchable-constructor:id
    faux-constructor:id
    [field:id field/c:expr]
    ...)
  (begin
    (struct-easy (internal-name field ...))
    
    (define/contract (faux-predicate? v)
      (-> any/c boolean?)
      ( (struct-predicate internal-name) v))
    
    (define faux-unmatchable-constructor
      (let ()
        (define/contract (faux-constructor field ...)
          (-> field/c ... faux-predicate?)
          (internal-name field ...))
        faux-constructor))
    
    (define-matchable-syntax faux-constructor
      (fn stx
        (syntax-parse stx #/ (_ arg:expr ...)
        #/syntax-protect
          #'(faux-unmatchable-constructor arg ...)))
      (fn stx
        (syntax-parse stx #/ (_ arg:expr ...)
        #/syntax-protect
          #'(internal-name arg ...))))))

(define-simple-macro
  (struct-of-procedures
    internal-name:id
    faux-predicate?:id
    faux-unmatchable-constructor:id
    faux-constructor:id
    [field:id field-method:id [arg:id arg/c:expr] ... result/c:expr]
    ...)
  (begin
    (struct-with-contracts
      internal-name
      faux-predicate?
      faux-unmatchable-constructor
      faux-constructor
      [field result/c]
      ...)
    
    (define/contract (field-method self arg ...)
      (-> faux-predicate? arg/c ... result/c)
      ( (struct-accessor-by-name internal-name field)
        arg ...))
    ...))


(define
  (interpret-formula-via-without-progress
    delegate formula delegate-delegate)
  (dissect (delegate delegate-delegate)
    (list interpret-formula interpret-deduction)
  #/interpret-formula formula))

(define
  (interpret-deduction-via-without-progress
    delegate deduction delegate-delegate)
  (dissect (delegate delegate-delegate)
    (list interpret-formula interpret-deduction)
  #/interpret-deduction deduction))


(struct-of-procedures
  deductive-system-rep
  deductive-system?
  unmatchable-make-deductive-system
  make-deductive-system
  
  ; given A. |- A => A
  [id deductive-system-id [a any/c] any/c]
  
  ; given A B C. A => B, B => C |- A => B
  [chain deductive-system-chain
    [a any/c]
    [b any/c]
    [c any/c]
    [ab any/c]
    [bc any/c]
    any/c])

(struct-with-contracts
  deductive-system-language-rep
  deductive-system-language?
  unmatchable-make-deductive-system-language
  make-deductive-system-language
  [id-sym symbol?]
  [chain-sym symbol?])

(define/contract (transparent-deductive-system lang)
  (-> deductive-system-language? deductive-system?)
  (dissect lang (make-deductive-system-language id-sym chain-sym)
  #/make-deductive-system
    (fn a
      (list id-sym a))
    (fn a b c ab bc
      (list chain-sym a b c ab bc))))

(define/contract (deductive-system-interpreter lang system)
  (-> deductive-system-language? deductive-system?
    (fix/c interpreter #/-> interpreter any/c any/c))
  (dissect lang (make-deductive-system-language id-sym chain-sym)
  #/loopfn self delegate expr
    (mat expr (list (? #/issym id-sym) a)
      (deductive-system-id a)
    #/mat expr (list (? #/issym chain-sym) a b c ab bc)
      (deductive-system-chain a b c ab bc)
    #/delegate self expr)))

(struct-of-procedures
  binary-connective-rep
  binary-connective?
  make-binary-connective
  
  [deductive-system binary-connective-deductive-system
    deductive-system?]
  
  ; given A B. (A * B) formula
  [wff-connect binary-connective-wff-connect
    [left any/c]
    [right any/c]
    any/c]
  
  ; given A A' B B'. A => A', B => B' |- (A * B) => (A' * B')
  [connect-bimap binary-connective-connect-bimap
    [a1 any/c]
    [a2 any/c]
    [b1 any/c]
    [b2 any/c]
    [a1a2 any/c]
    [b1b2 any/c]
    any/c])

(struct-with-contracts
  binary-connective-formula-language-rep
  binary-connective-formula-language?
  unmatchable-make-binary-connective-formula-language
  make-binary-connective-formula-language
  [connect-sym symbol?])

(struct-with-contracts
  binary-connective-deduction-language-rep
  binary-connective-deduction-language?
  unmatchable-make-binary-connective-deduction-language
  make-binary-connective-deduction-language
  [deductive-system-lang deductive-system-language?]
  [connect-bimap-sym symbol?])

(define/contract
  (transparent-binary-connective formula-lang deduction-lang)
  (->
    binary-connective-formula-language?
    binary-connective-deduction-language?
    binary-connective?)
  (dissect formula-lang
    (make-binary-connective-formula-language connect-sym)
  #/dissect deduction-lang
    (make-binary-connective-deduction-language
      deductive-system-lang connect-bimap-sym)
  #/make-binary-connective
    (fn #/transparent-deductive-system deductive-system-lang)
    (fn a b
      (list connect-sym a b))
    (fn a1 a2 b1 b2 on-a on-left on-right
      (list connect-bimap-sym a1 a2 b1 b2 a1a2 b1b2))))

(define/contract
  (binary-connective-interpreter formula-lang deduction-lang system)
  (->
    binary-connective-formula-language?
    binary-connective-deduction-language?
    binary-connective?
    (fix/c interpreter #/-> interpreter #/list/c
      (-> any/c any/c)
      (-> any/c any/c)))
  (dissect formula-lang
    (make-binary-connective-formula-language connect-sym)
  #/dissect deduction-lang
    (make-binary-connective-deduction-language
      deductive-system-lang connect-bimap-sym)
  #/w- ds-terp
    (deductive-system-interpreter deductive-system-lang
      (binary-connective-deductive-system system))
  #/loopfn self delegate
    
    (define (interpret-formula formula)
      (mat formula (list (? #/issym connect-sym) a b)
        (binary-connective-wff-connect
          (interpret-formula a)
          (interpret-formula b))
      #/dissect (delegate self)
        (list interpret-formula interpret-deduction)
      #/interpret-formula formula))
    
    (define (interpret-deduction deduction)
      (mat deduction
        (list (? #/issym connect-bimap-sym) a1 a2 b1 b2 a1a2 b1b2)
        (binary-connective-connect-bimap
          (interpret-formula a1)
          (interpret-formula a2)
          (interpret-formula b1)
          (interpret-formula b2)
          (interpret-deduction a1a2)
          (interpret-deduction b1b2))
      #/ds-terp deduction #/fn after-progress-delegate
      #/dissect (delegate self)
        (list interpret-formula interpret-deduction)
      #/interpret-deduction deduction))
    
    (list interpret-formula interpret-deduction)))

(struct-of-procedures
  monoidal-connective-rep
  monoidal-connective?
  make-monoidal-connective
  
  ; (1) formula
  [wff-unit monoidal-connective-wff-unit any/c]
  
  ; (given A B. A * B) binary
  [times monoidal-connective-times binary-connective?]
  
  ; given A B C. |- A * (B * C) <=> (A * B) * C
  [assocr monoidal-connective-assocl [a any/c] [b any/c] [c any/c]
    (list/c any/c any/c)]
  
  ; given A. |- 1 * A <=> A
  [uniteliml monoidal-connective-uniteliml [a any/c]
    (list/c any/c any/c)]
  
  ; given A. |- A * 1 <=> A
  [unitelimr monoidal-connective-unitelimr [a any/c]
    (list/c any/c any/c)])

(struct-with-contracts
  monoidal-connective-formula-language-rep
  monoidal-connective-formula-language?
  unmatchable-make-monoidal-connective-formula-language
  make-monoidal-connective-formula-language
  [one-sym symbol?]
  [times-lang binary-connective-language?])

(struct-with-contracts
  monoidal-connective-deduction-language-rep
  monoidal-connective-deduction-language?
  unmatchable-make-monoidal-connective-deduction-language
  make-monoidal-connective-deduction-language
  [times-lang binary-connective-deduction-language?]
  [assocl-syms (list/c symbol? symbol?)]
  [uniteliml-syms (list/c symbol? symbol?)]
  [unitelimr-syms (list/c symbol? symbol?)])

(define/contract
  (transparent-monoidal-connective formula-lang deduction-lang)
  (->
    monoidal-connective-formula-language?
    monoidal-connective-deduction-language?
    monoidal-connective?)
  (dissect formula-lang
    (make-monoidal-connective-formula-language
      one-sym times-formula-lang)
  #/dissect deduction-lang
    (make-monoidal-connective-deduction-language
      times-deduction-lang
      (list assocl-sym assocr-sym)
      (list uniteliml-sym unitintrol-sym)
      (list unitelimr-sym unitintror-sym))
  #/make-monoidal-connective
    (fn
      (transparent-binary-connective
        times-formula-lang times-deduction-lang))
    (fn a b c
      (list (list assocl-sym a b c) (list assocr-sym a b c)))
    (fn a
      (list (list uniteliml-sym a) (list unitintrol-sym a)))
    (fn a
      (list (list unitelimr-sym a) (list unitintror-sym a)))))

(define/contract
  (monoidal-connective-interpreter formula-lang deduction-lang system)
  (->
    monoidal-connective-formula-language?
    monoidal-connective-deduction-language?
    monoidal-connective?
    (fix/c interpreter #/-> interpreter #/list/c
      (-> any/c any/c)
      (-> any/c any/c)))
  (dissect formula-lang
    (make-monoidal-connective-formula-language
      one-sym times-formula-lang)
  #/dissect deduction-lang
    (make-monoidal-connective-deduction-language
      times-deduction-lang
      (list assocl-sym assocr-sym)
      (list uniteliml-sym unitintrol-sym)
      (list unitelimr-sym unitintror-sym))
  #/w- times-terp
    (binary-connective-interpreter
      times-formula-lang times-deduction-lang
      (monoidal-connective-times system))
  #/loopfn self delegate
    
    (define (interpret-formula formula)
      (mat formula (list (? #/issym one-sym))
        (binary-connective-wff-one)
      #/interpret-formula-via-without-progress times-terp formula
      #/fn delegate-after-progress
      #/interpret-formula-via-without-progress delegate self))
    
    (define (interpret-deduction deduction)
      (mat deduction (list (? #/issym assocl-sym) a b c)
        (dissect
          (monoidal-connective-assocl
            (interpret-formula a)
            (interpret-formula b)
            (interpret-formula c))
          (list assocl assocr)
          assocl)
      #/mat deduction (list (? #/issym assocr-sym) a b c)
        (dissect
          (monoidal-connective-assocl
            (interpret-formula a)
            (interpret-formula b)
            (interpret-formula c))
          (list assocl assocr)
          assocr)
      #/mat deduction (list (? #/issym uniteliml-sym) a)
        (dissect (monoidal-connective-assocl (interpret-formula a))
          (list uniteliml unitintrol)
          uniteliml)
      #/mat deduction (list (? #/issym unitintrol-sym) a)
        (dissect (monoidal-connective-assocl (interpret-formula a))
          (list uniteliml unitintrol)
          unitintrol)
      #/mat deduction (list (? #/issym unitelimr-sym) a)
        (dissect (monoidal-connective-assocr (interpret-formula a))
          (list unitelimr unitintror)
          unitelimr)
      #/mat deduction (list (? #/issym unitintrol-sym) a)
        (dissect (monoidal-connective-assocr (interpret-formula a))
          (list unitelimr unitintror)
          unitintror)
      #/interpret-deduction-via-without-progress times-terp formula
      #/fn delegate-after-progress
      #/interpret-deduction-via-without-progress delegate self))
    
    (list interpret-formula interpret-deduction)))

; TODO: Use the above interpreter infrastructure to make a
; "formula interpreter" that takes a formula like
; `(* (* (one) (_ A)) (* (_ B) (_ C)))` and returns a derivation that
; sorts formulas of this form into cons lists:
;
;   (1 * A) * (B * C) => A * (B * (C * 1))
;
; Or, using this s-expression notation instead:
;
;   (* (* (one) (_ A)) (* (_ B) (_ C)))
;   =>
;   (* (_ A) (* (_ B) (* (_ C) (one))))
;
; The values A, B, and C should be allowed to be any formulas for the
; monoidal connective for which we're building this deduction.
;
; Of course, we'll probably want another interpreter that constructs
; the inverses of these deductions, and then we can put them together
; to make a single interpreter that composes two of these deductions.
;
; What if they don't match? Well, then we might want a deduction
; interpreter that detects errors occurring inside the deduction...
; and we might want a deduction format that contains source locations
; so that we can offer helpful error messages. With the open recursion
; approach we're taking, it seems like it should be straightforward
; to build these extensions on top of what we've built here, rather
; than having to add in ad hoc support throughout this code.


(struct-of-procedures
  symmetric-monoidal-connective-rep
  symmetric-monoidal-connective?
  make-symmetric-monoidal-connective
  
  ; (1) (given A B. A * B) monoidal
  [times symmetric-monoidal-connective-times monoidal-connective?]
  
  ; given A B. |- A * B => B * A
  [commute symmetric-monoidal-connective-commute [a any/c] [b any/c]
    any/c])

(struct-with-contracts
  symmetric-monoidal-connective-deduction-language-rep
  symmetric-monoidal-connective-deduction-language?
  unmatchable-make-symmetric-monoidal-connective-deduction-language
  make-symmetric-monoidal-connective-deduction-language
  [times-lang monoidal-connective-deduction-language?]
  [commute-sym symbol?])

(define/contract
  (transparent-symmetric-monoidal-connective
    formula-lang deduction-lang)
  (->
    monoidal-connective-formula-language?
    symmetric-monoidal-connective-deduction-language?
    symmetric-monoidal-connective?)
  (dissect deduction-lang
    (make-symmetric-monoidal-connective-deduction-language
      times-deduction-lang commute-sym)
  #/make-symmetric-monoidal-connective
    (fn
      (transparent-monoidal-connective
        formula-lang times-deduction-lang))
    (fn a b
      (list commute-sym a b))))

(define/contract
  (symmetric-monoidal-connective-interpreter
    formula-lang deduction-lang system)
  (->
    monoidal-connective-formula-language?
    symmetric-monoidal-connective-deduction-language?
    symmetric-monoidal-connective?
    (fix/c interpreter #/-> interpreter #/list/c
      (-> any/c any/c)
      (-> any/c any/c)))
  (dissect deduction-lang
    (make-symmetric-monoidal-connective-deduction-language
      times-deduction-lang commute-sym)
  #/w- times-terp
    (monoidal-connective-interpreter
      formula-lang times-deduction-lang
      (symmetric-monoidal-connective-times system))
  #/loopfn self delegate
    
    (define (interpret-formula formula)
      (interpret-formula-via-without-progress times-terp formula
      #/fn delegate-after-progress
      #/interpret-formula-via-without-progress delegate self))
    
    (define (interpret-deduction deduction)
      (mat deduction (list (? #/issym commute-sym) a b)
        (symmetric-monoidal-connective-commute
          (interpret-formula a)
          (interpret-formula b))
      #/interpret-deduction-via-without-progress times-terp formula
      #/fn delegate-after-progress
      #/interpret-deduction-via-without-progress delegate self))
    
    (list interpret-formula interpret-deduction)))

; TODO: Once we have a convenient interpreter-based system for
; deducing complex associations of monoidal connectives, develop a
; similar system for deducing permutations of symmetric monoidal
; connectives. This time around, we'll probably want to use a sorted
; heap as an intermediate representation.
;
; We'll probably want to deal with errors a little more eagerly this
; time, too, so that we know if the user's put a different set of
; orderable labels on the input than they have on the output. We can
; take a first pass with a formula interpreter to assemble the set of
; labels on the input, and we can take another pass to assemble the
; set of labels on the output, and then we can check that they're the
; same.


; Multiplicative Linear Logic (MLL) without atoms or a notation for
; negation. Without guaranteed atoms or guaranteed negation, it's not
; really MLL so much as it's the proof-theoretical analogue of a
; linearly distributive category, so we're referring to it as a
; linearly distributive logic.
;
; If any extensions provide new atoms or new connectives and want to
; continue to treat this as MLL, they should make sure to supply their
; own De Morgan duals (keeping up the ability to treat negation
; notation as a syntactic sugar rather than part of the system
; proper), and they sould make sure these other deduction rules
; remain possible to compute with:
;
;   ; introduction (aka axiom)
;   given A. |- one => ~A par A
;
;   ; cut
;   given A. |- ~A times A => bot
;
; As long as negation, axiom, and cut are available like this, we can
; keep up the illusion that this is just an extensible version of MLL.
;
; (If the cut rule is not available for immediate computation, a cut
; elimination procedure for MLL should mean that it's still possible
; to add cut to any deduction as long as we're able to apply a
; transformation to that deduction's source code. That is, it won't
; always be possible to tack cut onto any given deduction, but if the
; deduction comes from one of our "transparent" instances of these
; interfaces, we should be able to use a transparent cut rule and then
; apply a cut-supporting interpreter to compile that deduction to a
; non-cut-supporting deduction system.)
;
; TODO:
;
; Implement extensible interpreters that compute De Morgan duals of
; formulas, that compute nonlocal introduction and cut rules when
; given local ones, and that compute an asymmetrical derivation (one
; that avoids the cut rule) from a symmetrical one. If we provide
; these things, it will be easier for clients to extend these logics
; while preserving the idea that they're MLL.
;
; On second thought, maybe we should actually provide an "MLL"
; interface where the axiom and cut rules are explicit rules
; rather than just derivable. If we write that interpreter that acts
; on a proof-with-cut to make a proof-without-cut, that's the kind of
; system it would have to be an interpreter *for* anyway.
;
(struct-of-procedures
  linearly-distributive-logic-rep
  linearly-distributive-logic?
  make-linearly-distributive-logic
  
  ; Our two monoidal connectives could provide us with two deductive
  ; systems. For the sake of reducing the ambiguity, we instead
  ; specify a single deductive system, and we express the two monoidal
  ; connectives as functions that take a deductive system. The
  ; functionality we define here will never pass those functions a
  ; deductive system except the one obtained here. As long as clients'
  ; extensions continue with this policy, there won't be any need for
  ; their clients to worry that a single
  ; `linearly-distributive-logic?` value could use a bizarre mix of
  ; deductive systems.
  
  [deductive-system deductive-system?]
  
  ; (one) (A and B) monoidal
  [times linearly-distributive-logic-times
    [deductive-system deductive-system?]
    monoidal-connective?]
  ; (bot) (A or B) monoidal
  [par linearly-distributive-logic-par
    [deductive-system deductive-system?]
    monoidal-connective?]
  
  ; given A B C. |- A and (B or C) => (A and B) or C
  [switch linearly-distributive-logic-switch any/c])

; TODO: Implement languages, transparent instances, and interpreters
; for the `linearly-distributive-logic?` interface.


; This system nearly corresponds to KS, a presentation of classical
; logic ("K") in the calculus of structures ("S"). The difference is
; that this system doesn't have atoms or negation. That makes it
; related to classical logic the same way our "linearly distributive
; logics" are related to MLL.
;
; We're dubbing this system a "classically medial logic" since the
; feature it introduces is the medial rule, but it uses the medial
; rule in a particular way: Not all calculus of structures systems
; that offer a medial rule (or several of them) offer it on the same
; connectives that are already linearly distributive.
;
; For instance, system ALLS (additive linear logic (ALL) in the
; calculus of structures (S)) has medial rules acting on four
; different pairs of the four monoidal connectives in that logic, but
; since none of those pairs acts on the two multiplicative connectives
; (much less in the particular direction this does), it doesn't cause
; the multiplicative connectives to form a classical logic on their
; own.
;
; System ALLS (and the symmetric system SKS which is no more potent,
; as well as many other systems up to classical linear logic with
; quantifiers) is discussed here:
;
;   A Local System for Linear Logic
;   Lutz Straßburger 2002
;   https://www.lix.polytechnique.fr/~lutz/papers/lls.pdf
;
; System KS (and the symmetric system SKS which is no more potent) is
; discussed here:
;
;   Deep Inference and Symmetry in Classical Proofs
;   Kai Brünnler 2004
;   http://cs.bath.ac.uk/ag/kai/phd.pdf
;
(struct-of-procedures
  classically-medial-logic-rep
  classically-medial-logic?
  make-classically-medial-logic
  
  ; (true) (A and B) (false) (A or B) linearly-distributive
  [switch classically-medial-logic-switch
    linearly-distributive-logic?]
  
  ; given A B C D. |- (A and B) or (C and D) => (A or C) and (B or D)
  [medial classically-medial-logic-medial any/c]
  
  
  (a00 and a01) => (a00) and (a01)
  
  ; In this system we can consider the medial rule to be a special
  ; case of a multiary medial rule commutativity between the two
  ; monoidal structures. These are the other three cases:
  ;
  ; |- false => true
  ; |- false => false and false
  ; |- true or true => true
  ;
  ; The last two are duals of each other, so we only need to show the
  ; deduction of one of them. All three proofs only need to use the
  ; unit rules a few times and the (binary) medial rule once:
  ;
  ;    false
  ;    false           or           false
  ;   (false and true) or (true and false)
  ;   -- medial rule --
  ;   (false or true) and (true or false)
  ;             true  and  true
  ;             true
  ;
  ;    false
  ;    false           and           true
  ;   (false or false) and (false or true)
  ;   -- medial rule --
  ;   (false and false) or (false and true)
  ;   (false and false) or  false
  ;    false and false
  ;
  ;
  ; That gives us a multiplication table where four slots have been
  ; filled in:
  ;
  ;     0 1 2 ...
  ;   0 *   *
  ;   1
  ;   2 *   *
  ;   ...
  ;
  ; The remaining nullary medial rules are all straightforward
  ; consequences of what we have...
  ;
  ;   |- true => true
  ;   |- false => false
  ;
  ;   |- true or true or true => true
  ;   |- false => false and false and false
  ;   |- true or true or true or true => true
  ;   |- false => false and false and false and false
  ;   ...
  ;
  ; And the unary rules are even more trivial than that:
  ;
  ;   given A. |- A => A
  ;   given A B. |- (A and B) => (A) and (B)
  ;   given A B. |- (A) or (B) => (A or B)
  ;   given A B C. |- (A and B and C) => (A) and (B) and (C)
  ;   given A B C. |- (A) or (B) or (C) => (A or B or C)
  ;   ...
  ;
  ; Let's do induction to get the rest. We want to show this for some
  ; dimensions M and N:
  ;
  ;   given A00 A01 ... A10 A11 ... ... .
  ;   |- (A00 and A01 and ...) or (A10 and A11 and ...) or ...
  ;   => (A00 or A10 or ...) and (A01 or A11 or ...) and ...
  ;
  ; We can apply any switch rule smaller than this one. All it takes
  ; is two:
  ;
  ;   (A00 and A01 and ...) or (A10 and A11 and ...) or ...
  ;
  ;   -- add parentheses --
  ;
  ;   (A00 and A01 and ...
  ;   ) or ((A10 and A11 and ...) or (A20 and A21 and ...) or ...))
  ;
  ;   -- apply (M - 1) by N switch rule on the second term --
  ;
  ;   (A00 and A01 and ...
  ;   ) or ((A10 or A20 or ...) and (A11 or A21 or ...) and ...)
  ;
  ;   -- apply 2 by N switch rule on the whole formula --
  ;
  ;   (A00 or (A10 or A20 or ...)
  ;   ) or (A01 or (A11 or A21 or ...)
  ;   ) or ...
  ;
  ;   -- remove parentheses --
  ;
  ;   (A00 or A10 or ...) or (A01 or A11 or ...) or ...
  ;
  ; It's interesting that none of these proofs rely on having
  ; commutativity of `and`, commutativity of `or`, linear
  ; distributivity. All we've used here are the unit laws, the 2 by 2
  ; medial rule, and... well, we used associativity so we could choose
  ; where to add parentheses.
  ;
  ; If we take away associativity, we have to think about things like
  ; ((1 + 1) + (1 + 1)) by (1 + (1 + (1 + 1))) switch rules, but I
  ; think the above argument continues to apply: To get the
  ; (M1 + M2) by N switch rule, compose the M2 by N switch rule with
  ; the (M1 + 1) by N switch rule.
  ;
  ; And we only needed the unit laws for the nullary case. Switch is
  ; an interesting property of a category with two binary functors
  ; even if those functors aren't monoidal!
  ;
  ; At least in the monoidal case (which indeed is the case for the
  ; interface I'm writing a big comment at the end of), it seems to be
  ; known as a "duoidal category." A duoidal category doesn't
  ; necessarily have linear distributivity, so that's where we differ.
  ;
  ; (TODO: Let's make a `duoidal-logic?` interface and then represent
  ; this interface using a `linearly-distributive-logic?` and a
  ; `duoidal-logic?` that share the same two `monoidal-connective?`
  ; instances that share the same `deductive-system?` instance.)
  
  )

; TODO: Implement languages, transparent instances, and interpreters
; for the `classically-medial-logic?` interface.


; This is an expression of full classical logic in the SKS style.
; (That's the symmetric version of the KS presentation of classical
; logic.) This version is not concerned with enforcing
; proof-theoretical properties at the deduction level, such as cut
; eliminnation or the ability to translate from SKS derivations to KS
; derivations. However, it does enforce similar properties at the
; formula level, like the ability to negate every formula and the
; ability to deduce intro, weakening, and contraction rules for every
; formula.
;
; The similarity is that cut elimination is an algorithm that would
; apply to every derivation, and these are operations that apply to
; every formula. If they're not enforced, they can just be upheld on a
; good-faith basis. But this interface finally enforces them at the
; formula level.
;
; Enforcing the properties at the proof-theoretic level would require
; us to have been keeping track of more structure and properties at
; dimension one (operations on and properties of deductions),
; essentially making this proper category theory. It's category theory
; we're interested in in the first place, but we need classical logic
; to express deductions involving (clasical) category-theoretic
; properties, so our logical interfaces here are specifically set up
; to not demand higher-dimensional structure.
;
; It's possible many of the things we do with categories will only
; rely on weaker deductive systems. The `classically-medial-logic?` is
; probably all we need, since categories can supply introduction,
; contraction, and weakening rules for their own identity and
; apartness relations.
;
(struct-of-procedures
  classical-logic-rep
  classical-logic?
  make-classical-logic
  
  ; (true) (A and B) (false) (A or B) classically-medial
  [medial classical-logic-medial classically-medial-logic?]
  
  ; forall A. ~A formula
  [wff-not classical-logic-not [a any/c] any/c]
  
  ; forall A B. |- ~(A and B) <=> ~A or ~B
  [and-de-morgan classical-logic [a any/c] [b any/c]
    (list/c any/c any/c)]
  
  ; forall A B. |- ~(A or B) <=> ~A and ~B
  [or-de-morgan classical-logic [a any/c] [b any/c]
    (list/c any/c any/c)]
  
  ; forall A B. |- ~true <=> false
  [true-de-morgan classical-logic (list/c any/c any/c)]
  
  ; forall A B. |- ~false <=> true
  [false-de-morgan classical-logic (list/c any/c any/c)]
  
  ; NOTE: We have to make a choice when we dualize this negation. We
  ; choose to put the negation to the left of an `or` and to the right
  ; of an `and`, to make it as convenient as possible to treat these
  ; as classical implications (as in, `~A or B` is `A implies B`, and
  ; `A and ~B` is `~(A implies B)`).
  ;
  ; forall A. |- true => (~A or A)
  ; forall A. |- (A and ~A) => false
  [intro classical-logic-intro (list any/c any/c)]
  
  ; forall A. |- false => A
  ; forall A. |- A => true
  [weakening classical-logic-weakening (list any/c any/c)]
  
  ; forall A. |- (A and A) => A
  ; forall A. |- A => (A or A)
  [contraction classical-logic-contraction (list any/c any/c)])



; TODO: Everything after this point is old. Let's remove it when we're
; sure we don't need it.


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
