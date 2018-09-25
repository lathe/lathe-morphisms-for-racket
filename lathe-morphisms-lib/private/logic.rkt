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
      [field (-> arg/c ... result/c)]
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
    (list interpret-formula interpret-derivation)
  #/interpret-formula formula))

(define
  (interpret-derivation-via-without-progress
    delegate derivation delegate-delegate)
  (dissect (delegate delegate-delegate)
    (list interpret-formula interpret-derivation)
  #/interpret-derivation derivation))


; What we call a "mediary deductive system" is like a deductive system
; in that it has a way to compose derivations, but it doesn't
; necessarily offer a way to derive a formula from itself. The idea is
; that it *intermediates* between what we'll call "deductive formulas"
; (those formulas which can be derived from themselves) to let them
; interact with each other in a way that completes a deductive system.
;
; This means a mediary deductive system is like a semicategory. A
; semicategory has compositions of morphisms but not necessarily an
; identity morphism for every object. Once we get aroud to building
; interfaces for category theory, we'll likely have an interface for
; semicategories we call "mediary category theory." (TODO: See if we
; do call it that, and update this comment.)
;
; This is the first of a few "mediary" proof-theoretic structures we
; have here.
;
; We don't call our systems "semi" because semicategories got their
; name from algebras that lacked identity elements. Our mediary
; systems do have some identity elements, and some of the things they
; exclude aren't identity elements (such as contraction and weakening
; rules for atomic formulae).
;
; Instead we're guided by the way local systems in the calculus of
; structures can reduce some of their inference rules to atomic form,
; which often results in instances of the same kind of "medial rule"
; showing up in the system. If we set things up so that all our atoms
; carry their own atomic rules with them, then all we need in between
; is a system that carries certain rules like these instances of the
; medial rule -- a mediary system.
;
(struct-of-procedures
  mediary-deductive-system-rep
  mediary-deductive-system?
  unmatchable-make-mediary-deductive-system
  make-mediary-deductive-system
  
  ; A, B, C formula; A => B, B => C |- A => B
  [chain mediary-deductive-system-chain
    [a any/c]
    [b any/c]
    [c any/c]
    [ab any/c]
    [bc any/c]
    any/c])

(struct-with-contracts
  mediary-deductive-system-language-rep
  mediary-deductive-system-language?
  unmatchable-make-mediary-deductive-system-language
  make-mediary-deductive-system-language
  [chain-sym symbol?])

(define/contract (transparent-mediary-deductive-system lang)
  (-> mediary-deductive-system-language? mediary-deductive-system?)
  (dissect lang (make-mediary-deductive-system-language chain-sym)
  #/make-mediary-deductive-system
    (fn a b c ab bc
      (list chain-sym a b c ab bc))))

(define/contract (mediary-deductive-system-interpreter lang system)
  (-> mediary-deductive-system-language? mediary-deductive-system?
    (fix/c interpreter #/-> interpreter any/c any/c))
  (dissect lang (make-mediary-deductive-system-language chain-sym)
  #/loopfn self delegate expr
    (mat expr (list (? #/issym chain-sym) a b c ab bc)
      (mediary-deductive-system-chain a b c ab bc)
    #/delegate self expr)))


; We use the term "deductive formula" to refer to a formula (`A`) that
; comes bundled with a way to derive it from itself (`A => A`). If all
; the formulas that are used with a mediary deductive system are
; deductive formulas, then the derivations `A => A` act as the
; identity element for the system's derivation composition operation.
;
(struct-with-contracts
  deductive-formula-rep
  deductive-formula?
  unmatchable-deductive-formula
  make-deductive-formula
  [a any/c]
  [aa any/c])


; Unlike a `mediary-deductive-system?`, a `deductive-system?` has an
; identity deduction for any given formula.
;
(struct-of-procedures
  deductive-system-rep
  deductive-system?
  unmatchable-make-deductive-system
  make-deductive-system
  
  ; (A => B) mediary-deductive-system
  ; i.e.
  ; A, B, C formula; A => B, B => C |- A => B
  [mediary deductive-system-mediary mediary-deductive-system?]
  
  ; A formula; |- A => A
  [id deductive-system-id [a any/c] any/c])

(struct-with-contracts
  deductive-system-language-rep
  deductive-system-language?
  unmatchable-make-deductive-system-language
  make-deductive-system-language
  [mediary-lang mediary-deductive-system-language?]
  [id-sym symbol?])

(define/contract (transparent-deductive-system derivation-lang)
  (-> deductive-system-language? deductive-system?)
  (dissect derivation-lang
    (make-deductive-system-language mediary-lang id-sym)
  #/make-deductive-system
    (fn #/mediary-deductive-system mediary-lang)
    (fn a
      (list id-sym a))))

(define/contract (deductive-system-interpreter derivation-lang system)
  (-> deductive-system-language? deductive-system?
    (fix/c interpreter #/-> interpreter any/c any/c))
  (dissect derivation-lang
    (make-deductive-system-language mediary-lang id-sym)
  #/w- mediary-terp
    (mediary-deductive-system-interpreter mediary-lang
      (deductive-system-mediary system))
  #/loopfn self delegate expr
    (mat expr (list (? #/issym id-sym) a)
      (deductive-system-id a)
    #/mediary-terp expr #/fn delegate-after-progress
    #/delegate self expr)))

(struct-of-procedures
  nullary-connective-rep
  nullary-connective?
  make-nullary-connective
  
  [mediary-deductive-system
    nullary-connective-mediary-deductive-system
    mediary-deductive-system?]
  
  ; (*) formula
  [wff-connect nullary-connective-wff-connect any/c]
  
  ; |- * => *
  [connect-map nullary-connective-connect-map any/c])

(struct-with-contracts
  nullary-connective-formula-language-rep
  nullary-connective-formula-language?
  unmatchable-make-nullary-connective-formula-language
  make-nullary-connective-formula-language
  [connect-sym symbol?])

(struct-with-contracts
  nullary-connective-derivation-language-rep
  nullary-connective-derivation-language?
  unmatchable-make-nullary-connective-derivation-language
  make-nullary-connective-derivation-language
  [mediary-deductive-system-lang mediary-deductive-system-language?]
  [connect-map-sym symbol?])

(define/contract
  (transparent-nullary-connective formula-lang derivation-lang)
  (->
    nullary-connective-formula-language?
    nullary-connective-derivation-language?
    nullary-connective?)
  (dissect formula-lang
    (make-nullary-connective-formula-language connect-sym)
  #/dissect derivation-lang
    (make-nullary-connective-derivation-language
      mediary-deductive-system-lang connect-map-sym)
  #/make-nullary-connective
    (fn
      (transparent-mediary-deductive-system
        mediary-deductive-system-lang))
    (fn
      (list connect-sym))
    (fn
      (list connect-map-sym))))

(define/contract
  (nullary-connective-interpreter formula-lang derivation-lang system)
  (->
    nullary-connective-formula-language?
    nullary-connective-derivation-language?
    nullary-connective?
    (fix/c interpreter #/-> interpreter #/list/c
      (-> any/c any/c)
      (-> any/c any/c)))
  (dissect formula-lang
    (make-nullary-connective-formula-language connect-sym)
  #/dissect derivation-lang
    (make-nullary-connective-derivation-language
      mediary-deductive-system-lang connect-map-sym)
  #/w- ds-terp
    (mediary-deductive-system-interpreter
      mediary-deductive-system-lang
      (nullary-connective-mediary-deductive-system system))
  #/loopfn self delegate
    
    (define (interpret-formula formula)
      (mat formula (list #/? #/issym connect-sym)
        (nullary-connective-wff-connect)
      #/interpret-formula-via-without-progress delegate formula self))
    
    (define (interpret-derivation derivation)
      (mat derivation (list #/? #/issym connect-map-sym)
        (nullary-connective-connect-map)
      #/ds-terp derivation #/fn delegate-after-progress
      #/interpret-derivation-via-without-progress delegate derivation
        self))
    
    (list interpret-formula interpret-derivation)))

(struct-of-procedures
  contra-unary-connective-rep
  contra-unary-connective?
  make-contra-unary-connective
  
  [mediary-deductive-system
    contra-unary-connective-mediary-deductive-system
    mediary-deductive-system?]
  
  ; (~A) formula
  [wff-connect contra-unary-connective-wff-connect [a any/c] any/c]
  
  ; A, A' formula; A => A' |- A' => ~A
  [connect-map contra-unary-connective-connect-map
    [a1 any/c]
    [a2 any/c]
    [a1a2 any/c]
    any/c])

(struct-with-contracts
  contra-unary-connective-formula-language-rep
  contra-unary-connective-formula-language?
  unmatchable-make-contra-unary-connective-formula-language
  make-contra-unary-connective-formula-language
  [connect-sym symbol?])

(struct-with-contracts
  contra-unary-connective-derivation-language-rep
  contra-unary-connective-derivation-language?
  unmatchable-make-contra-unary-connective-derivation-language
  make-contra-unary-connective-derivation-language
  [mediary-deductive-system-lang mediary-deductive-system-language?]
  [connect-map-sym symbol?])

(define/contract
  (transparent-contra-unary-connective formula-lang derivation-lang)
  (->
    contra-unary-connective-formula-language?
    contra-unary-connective-derivation-language?
    contra-unary-connective?)
  (dissect formula-lang
    (make-contra-unary-connective-formula-language connect-sym)
  #/dissect derivation-lang
    (make-contra-unary-connective-derivation-language
      mediary-deductive-system-lang connect-map-sym)
  #/make-contra-unary-connective
    (fn
      (transparent-mediary-deductive-system
        mediary-deductive-system-lang))
    (fn a
      (list connect-sym a))
    (fn a1 a2 a1a2
      (list connect-map-sym a1 a2 a1a2))))

(define/contract
  (contra-unary-connective-interpreter
    formula-lang derivation-lang system)
  (->
    contra-unary-connective-formula-language?
    contra-unary-connective-derivation-language?
    contra-unary-connective?
    (fix/c interpreter #/-> interpreter #/list/c
      (-> any/c any/c)
      (-> any/c any/c)))
  (dissect formula-lang
    (make-contra-unary-connective-formula-language connect-sym)
  #/dissect derivation-lang
    (make-contra-unary-connective-derivation-language
      mediary-deductive-system-lang connect-map-sym)
  #/w- ds-terp
    (mediary-deductive-system-interpreter
      mediary-deductive-system-lang
      (contra-unary-connective-mediary-deductive-system system))
  #/loopfn self delegate
    
    (define (interpret-formula formula)
      (mat formula (list (? #/issym connect-sym) a)
        (contra-unary-connective-wff-connect (interpret-formula a))
      #/interpret-formula-via-without-progress delegate formula self))
    
    (define (interpret-derivation derivation)
      (mat derivation (list (? #/issym connect-map-sym) a1 a2 a1a2)
        (contra-unary-connective-connect-map
          (interpret-formula a1)
          (interpret-formula a2)
          (interpret-connective a1a2))
      #/ds-terp derivation #/fn delegate-after-progress
      #/interpret-derivation-via-without-progress delegate derivation
        self))
    
    (list interpret-formula interpret-derivation)))

(struct-of-procedures
  binary-connective-rep
  binary-connective?
  make-binary-connective
  
  [mediary-deductive-system binary-connective-mediary-deductive-system
    mediary-deductive-system?]
  
  ; (A * B) formula
  [wff-connect binary-connective-wff-connect
    [left any/c]
    [right any/c]
    any/c]
  
  ; A, A', B, B' formula; A => A', B => B' |- (A * B) => (A' * B')
  [connect-map binary-connective-connect-map
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
  binary-connective-derivation-language-rep
  binary-connective-derivation-language?
  unmatchable-make-binary-connective-derivation-language
  make-binary-connective-derivation-language
  [mediary-deductive-system-lang mediary-deductive-system-language?]
  [connect-map-sym symbol?])

(define/contract
  (transparent-binary-connective formula-lang derivation-lang)
  (->
    binary-connective-formula-language?
    binary-connective-derivation-language?
    binary-connective?)
  (dissect formula-lang
    (make-binary-connective-formula-language connect-sym)
  #/dissect derivation-lang
    (make-binary-connective-derivation-language
      mediary-deductive-system-lang connect-map-sym)
  #/make-binary-connective
    (fn
      (transparent-mediary-deductive-system
        mediary-deductive-system-lang))
    (fn a b
      (list connect-sym a b))
    (fn a1 a2 b1 b2 on-a on-left on-right
      (list connect-map-sym a1 a2 b1 b2 a1a2 b1b2))))

(define/contract
  (binary-connective-interpreter formula-lang derivation-lang system)
  (->
    binary-connective-formula-language?
    binary-connective-derivation-language?
    binary-connective?
    (fix/c interpreter #/-> interpreter #/list/c
      (-> any/c any/c)
      (-> any/c any/c)))
  (dissect formula-lang
    (make-binary-connective-formula-language connect-sym)
  #/dissect derivation-lang
    (make-binary-connective-derivation-language
      mediary-deductive-system-lang connect-map-sym)
  #/w- ds-terp
    (mediary-deductive-system-interpreter
      mediary-deductive-system-lang
      (binary-connective-mediary-deductive-system system))
  #/loopfn self delegate
    
    (define (interpret-formula formula)
      (mat formula (list (? #/issym connect-sym) a b)
        (binary-connective-wff-connect
          (interpret-formula a)
          (interpret-formula b))
      #/interpret-formula-via-without-progress delegate formula self))
    
    (define (interpret-derivation derivation)
      (mat derivation
        (list (? #/issym connect-map-sym) a1 a2 b1 b2 a1a2 b1b2)
        (binary-connective-connect-map
          (interpret-formula a1)
          (interpret-formula a2)
          (interpret-formula b1)
          (interpret-formula b2)
          (interpret-derivation a1a2)
          (interpret-derivation b1b2))
      #/ds-terp derivation #/fn delegate-after-progress
      #/interpret-derivation-via-without-progress delegate derivation
        self))
    
    (list interpret-formula interpret-derivation)))


; NOTE:
;
; In the following logics, we start to combine rules from multiple
; logics that came before, and this can cause some duplication. When a
; logic contains a `nullary-connective?` logic and a
; `binary-connective?` logic, they each have a
; `mediary-deductive-system?`. When we have diamond dependencies like
; this, we usually choose a design that reduces ambiguity by
; specifying a particular unambiguous value for that dependency and
; then expressing the other two dependencies as functions of it.
;
; For instance, a `linearly-distributive-logic?` has a method that
; returns a `mediary-deductive-system?`, and it has two methods that
; each *takes* a `mediary-deductive-system?` and returns a
; `monoidal-connective?`.
;
; Sometimes we treat one of the dependencies as being more essential
; than another, in which case only the less essential dependency is
; expressed as a function. For instance, a `mediary-classical-logic?`
; is made up of a `mediary-mll?` and a `duoidal-logic?` that share a
; `mediary-deductive-system?` and two `monoidal-connective?` logics,
; but we only express the `duoidal-logic?` as a function of those
; things. We consider the `mediary-mll?` to be where those things
; come from.
;
; When the functionality we define here has to access a dependency
; that's expressed as a function this way, it'll always pass in the
; indirect dependency it gets from the appropriate method of the
; logic; it won't pass in a value from somewhere else. Likewise, the
; interpreters we define here will attempt to delegate to the indirect
; dependency *before* attempting to delegate to a more direct
; dependency that depends on it.
;
; When the functionality we define here *constructs* a logic, it won't
; always use the passed-in indirect dependency to construct the direct
; dependency. Sometimes it'll just trust that the passed-in value is
; the same as what it constructed for that indirect dependency.
;
; As long as all users use this kind of discipline to access these
; dependencies, there shouldn't be any need for users to worry that
; they're invoking a mismatched mix of subsystems when they compute
; with a logic.


(struct-of-procedures
  monoidal-connective-rep
  monoidal-connective?
  make-monoidal-connective
  
  [mediary-deductive-system mediary-deductive-system?]
  
  ; (1) formula
  [one monoidal-connective-one
    [mediary-deductive-system mediary-deductive-system?]
    nullary-connective?]
  
  ; (A * B) binary
  [times monoidal-connective-times
    [mediary-deductive-system mediary-deductive-system?]
    binary-connective?]
  
  ; A, B, C deductive-formula; |- A * (B * C) <=> (A * B) * C
  [assocr monoidal-connective-assocl
    [a deductive-formula?]
    [b deductive-formula?]
    [c deductive-formula?]
    (list/c any/c any/c)]
  
  ; A deductive-formula; |- 1 * A <=> A
  [uniteliml monoidal-connective-uniteliml [a deductive-formula?]
    (list/c any/c any/c)]
  
  ; A deductive-formula; |- A * 1 <=> A
  [unitelimr monoidal-connective-unitelimr [a deductive-formula?]
    (list/c any/c any/c)])

(struct-with-contracts
  monoidal-connective-formula-language-rep
  monoidal-connective-formula-language?
  unmatchable-make-monoidal-connective-formula-language
  make-monoidal-connective-formula-language
  [one-lang nullary-connective-language?]
  [times-lang binary-connective-language?])

(struct-with-contracts
  monoidal-connective-derivation-language-rep
  monoidal-connective-derivation-language?
  unmatchable-make-monoidal-connective-derivation-language
  make-monoidal-connective-derivation-language
  [mediary-deductive-system-lang mediary-deductive-system-language?]
  [one-lang
    (-> mediary-deductive-system-language?
      nullary-connective-derivation-language?)]
  [times-lang
    (-> mediary-deductive-system-language?
      binary-connective-derivation-language?)]
  [assocl-syms (list/c symbol? symbol?)]
  [uniteliml-syms (list/c symbol? symbol?)]
  [unitelimr-syms (list/c symbol? symbol?)])

(define/contract
  (transparent-monoidal-connective formula-lang derivation-lang)
  (->
    monoidal-connective-formula-language?
    monoidal-connective-derivation-language?
    monoidal-connective?)
  (dissect formula-lang
    (make-monoidal-connective-formula-language
      one-formula-lang times-formula-lang)
  #/dissect derivation-lang
    (make-monoidal-connective-derivation-language
      mediary-deductive-system-lang
      one-derivation-lang
      times-derivation-lang
      (list assocl-sym assocr-sym)
      (list uniteliml-sym unitintrol-sym)
      (list unitelimr-sym unitintror-sym))
  #/make-monoidal-connective
    (fn
      (transparent-mediary-deductive-system
        mediary-deductive-system-lang))
    (fn mediary-deductive-system
      (transparent-nullary-connective
        one-formula-lang
        (one-derivation-lang mediary-deductive-system-lang)))
    (fn mediary-deductive-system
      (transparent-binary-connective
        times-formula-lang
        (times-derivation-lang mediary-deductive-system-lang)))
    (fn a b c
      (list (list assocl-sym a b c) (list assocr-sym a b c)))
    (fn a
      (list (list uniteliml-sym a) (list unitintrol-sym a)))
    (fn a
      (list (list unitelimr-sym a) (list unitintror-sym a)))))

(define/contract
  (monoidal-connective-interpreter
    formula-lang derivation-lang system)
  (->
    monoidal-connective-formula-language?
    monoidal-connective-derivation-language?
    monoidal-connective?
    (fix/c interpreter #/-> interpreter #/list/c
      (-> any/c any/c)
      (-> any/c any/c)))
  (dissect formula-lang
    (make-monoidal-connective-formula-language
      one-formula-lang times-formula-lang)
  #/dissect derivation-lang
    (make-monoidal-connective-derivation-language
      mediary-deductive-system-lang
      one-derivation-lang
      times-derivation-lang
      (list assocl-sym assocr-sym)
      (list uniteliml-sym unitintrol-sym)
      (list unitelimr-sym unitintror-sym))
  #/w- one-terp
    (nullary-connective-interpreter
      one-formula-lang
      (one-derivation-lang mediary-deductive-system-lang)
      (monoidal-connective-one system))
  #/w- times-terp
    (binary-connective-interpreter
      times-formula-lang
      (times-derivation-lang mediary-deductive-system-lang)
      (monoidal-connective-times system))
  #/loopfn self delegate
    
    (define (interpret-deductive-formula a)
      (expect a (deductive-formula a aa)
        ; TODO: Improve this error reporting.
        (error "Expected a deductive formula")
      #/deductive-formula
        (interpret-formula a)
        (interpret-derivation aa)))
    
    (define (interpret-formula formula)
      (interpret-formula-via-without-progress one-terp formula
      #/fn delegate-after-progress
      #/interpret-formula-via-without-progress times-terp formula
      #/fn delegate-after-progress
      #/interpret-formula-via-without-progress delegate formula self))
    
    (define (interpret-derivation derivation)
      (mat derivation (list (? #/issym assocl-sym) a b c)
        (dissect
          (monoidal-connective-assocl
            (interpret-deductive-formula a)
            (interpret-deductive-formula b)
            (interpret-deductive-formula c))
          (list assocl assocr)
          assocl)
      #/mat derivation (list (? #/issym assocr-sym) a b c)
        (dissect
          (monoidal-connective-assocl
            (interpret-deductive-formula a)
            (interpret-deductive-formula b)
            (interpret-deductive-formula c))
          (list assocl assocr)
          assocr)
      #/mat derivation (list (? #/issym uniteliml-sym) a)
        (dissect
          (monoidal-connective-uniteliml
            (interpret-deductive-formula a))
          (list uniteliml unitintrol)
          uniteliml)
      #/mat derivation (list (? #/issym unitintrol-sym) a)
        (dissect
          (monoidal-connective-uniteliml
            (interpret-deductive-formula a))
          (list uniteliml unitintrol)
          unitintrol)
      #/mat derivation (list (? #/issym unitelimr-sym) a)
        (dissect
          (monoidal-connective-unitelimr
            (interpret-deductive-formula a))
          (list unitelimr unitintror)
          unitelimr)
      #/mat derivation (list (? #/issym unitintror-sym) a)
        (dissect
          (monoidal-connective-unitelimr
            (interpret-deductive-formula a))
          (list unitelimr unitintror)
          unitintror)
      #/interpret-derivation-via-without-progress one-terp formula
      #/fn delegate-after-progress
      #/interpret-derivation-via-without-progress times-terp formula
      #/fn delegate-after-progress
      #/interpret-derivation-via-without-progress delegate formula
        self))
    
    (list interpret-formula interpret-derivation)))

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
; monoidal connective for which we're building this derivation.
;
; Of course, we'll probably want another interpreter that constructs
; the inverses of these derivations, and then we can put them together
; to make a single interpreter that composes two of these derivations.
;
; What if they don't match? Well, then we might want a derivation
; interpreter that detects errors occurring inside the derivation...
; and we might want a derivation format that contains source locations
; so that we can offer helpful error messages. With the open recursion
; approach we're taking, it seems like it should be straightforward
; to build these extensions on top of what we've built here, rather
; than having to add in ad hoc support throughout this code.


(struct-of-procedures
  symmetric-monoidal-connective-rep
  symmetric-monoidal-connective?
  make-symmetric-monoidal-connective
  
  ; (1) (A * B) monoidal
  [times symmetric-monoidal-connective-times monoidal-connective?]
  
  ; A, B deductive-formula; |- A * B => B * A
  [commute symmetric-monoidal-connective-commute
    [a deductive-formula?]
    [b deductive-formula?]
    any/c])

(struct-with-contracts
  symmetric-monoidal-connective-derivation-language-rep
  symmetric-monoidal-connective-derivation-language?
  unmatchable-make-symmetric-monoidal-connective-derivation-language
  make-symmetric-monoidal-connective-derivation-language
  [times-lang monoidal-connective-derivation-language?]
  [commute-sym symbol?])

(define/contract
  (transparent-symmetric-monoidal-connective
    formula-lang derivation-lang)
  (->
    monoidal-connective-formula-language?
    symmetric-monoidal-connective-derivation-language?
    symmetric-monoidal-connective?)
  (dissect derivation-lang
    (make-symmetric-monoidal-connective-derivation-language
      times-derivation-lang commute-sym)
  #/make-symmetric-monoidal-connective
    (fn
      (transparent-monoidal-connective
        formula-lang times-derivation-lang))
    (fn a b
      (list commute-sym a b))))

(define/contract
  (symmetric-monoidal-connective-interpreter
    formula-lang derivation-lang system)
  (->
    monoidal-connective-formula-language?
    symmetric-monoidal-connective-derivation-language?
    symmetric-monoidal-connective?
    (fix/c interpreter #/-> interpreter #/list/c
      (-> any/c any/c)
      (-> any/c any/c)))
  (dissect derivation-lang
    (make-symmetric-monoidal-connective-derivation-language
      times-derivation-lang commute-sym)
  #/w- times-terp
    (monoidal-connective-interpreter
      formula-lang times-derivation-lang
      (symmetric-monoidal-connective-times system))
  #/loopfn self delegate
    
    (define (interpret-deductive-formula a)
      (expect a (deductive-formula a aa)
        ; TODO: Improve this error reporting.
        (error "Expected a deductive formula")
      #/deductive-formula
        (interpret-formula a)
        (interpret-derivation aa)))
    
    (define (interpret-formula formula)
      (interpret-formula-via-without-progress times-terp formula
      #/fn delegate-after-progress
      #/interpret-formula-via-without-progress delegate formula self))
    
    (define (interpret-derivation derivation)
      (mat derivation (list (? #/issym commute-sym) a b)
        (symmetric-monoidal-connective-commute
          (interpret-deductive-formula a)
          (interpret-deductive-formula b))
      #/interpret-derivation-via-without-progress
        times-terp derivation
      #/fn delegate-after-progress
      #/interpret-derivation-via-without-progress delegate derivation
        self))
    
    (list interpret-formula interpret-derivation)))

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


; A logic analogous to a linearly distributive semicategory.
; Multiplicative linear logic (MLL) is analogous to this, except that
; it has identity derivations, a negation connective, atoms, and
; commutativity of `times` and `par`.
;
; Once we add commutativity (but not the other things) to this, we
; call that variation `mediary-mll?`.
;
(struct-of-procedures
  linearly-distributive-logic-rep
  linearly-distributive-logic?
  make-linearly-distributive-logic
  
  [mediary-deductive-system mediary-deductive-system?]
  
  ; (one) (A times B) monoidal
  [times linearly-distributive-logic-times
    [mediary-deductive-system mediary-deductive-system?]
    monoidal-connective?]
  ; (bot) (A par B) monoidal
  [par linearly-distributive-logic-par
    [mediary-deductive-system mediary-deductive-system?]
    monoidal-connective?]
  
  ; A, B, C deductive-formula;
  ; |- A times (B par C) => (A times B) par C
  [switchl linearly-distributive-logic-switch
    [a deductive-formula?]
    [b deductive-formula?]
    [c deductive-formula?]
    any/c]
  
  ; A, B, C deductive-formula;
  ; |- (A par B) times C => A par (B times C)
  [switchr linearly-distributive-logic-switch
    [a deductive-formula?]
    [b deductive-formula?]
    [c deductive-formula?]
    any/c]
  
  ; The switch rules above work for binary `times` and binary `par`,
  ; but they just as easily apply to any instance of `times` or `par`
  ; with two or more subformulas:
  ;
  ;   (A0 times A1 times ...) times (B par (C0 par C1 par ...))
  ;   -- apply the binary switchl rule once --
  ;   ((A0 times A1 times ...) times B) par (C0 par C1 par ...)
  ;
  ; Note that when either of them has only one subformula, the rule
  ; trivially holds even without using the binary-binary switch rule:
  ;
  ;   (A0 times A1 times ...) times (B)
  ;   -- apply no rules --
  ;   ((A0 times A1 times ...) times B)
  ;
  ;   (B par (C0 par C1 par ...))
  ;   -- apply no rules --
  ;   (B) par (C0 par C1 par ...)
  ;
  ; This pattern doesn't extend to nullary-N-ary or N-ary-nullary
  ; switch rules since there would be no subformula `B` to pivot on.
  
  )

; TODO: Implement languages, transparent instances, and interpreters
; for the `linearly-distributive-logic?` interface.


; Multiplicative Linear Logic (MLL) without identity derivations,
; atoms, or a negation connective. Without these things, it's not
; quite MLL so much as it's the proof-theoretical analogue of a
; symmetric linearly distributive semicategory, but we're referring to
; it as "mediary MLL" to convey that it's MLL as long as the formulas
; cooperate (by having identity derivations and De Morgan duals) and
; the atoms cooperate (by having introduction and cut rules). Our use
; of the term "mediary" is described at the definition of
; `mediary-deductive-system?`.
;
; If any extensions provide new atoms or new connectives and want to
; continue to treat this as MLL, they should make sure to supply their
; own De Morgan duals (keeping up the ability to treat a negation
; connective as a syntactic sugar rather than part of the system
; proper), and they sould make sure these other inference rules remain
; possible to compute with:
;
;   ; identity derivation
;   A formula; | A => A
;
;   ; introduction (aka axiom)
;   A formula; |- one => ~A par A
;
;   ; cut
;   A formula; |- ~A times A => bot
;
; As long as identity derivations, negation, axiom, and cut are
; available like this, we can keep up the illusion that this is just
; an extensible version of MLL.
;
; (If the cut rule is not available for immediate computation, the cut
; elimination metatheory for MLL should mean that it's still possible
; to add cut to any derivation as long as we're able to apply a
; transformation to that derivation's source code. That is, it won't
; always be possible to tack cut onto any given derivation, but if the
; derivation comes from one of our "transparent" instances of these
; interfaces, we should be able to use a transparent cut rule and then
; apply a cut-supporting interpreter to compile that derivation to a
; non-cut-supporting logic.)
;
; Once we add all those missing pieces, we call the variation `mll?`,
; and it corresponds to star-autonomous categories. The missing
; identity derivations make this a semicategory. (TODO: Is there some
; variation of the term "star-autonomous" that would account for the
; other missing things?)
;
; TODO:
;
; Implement extensible interpreters that compute nonlocal identity
; derivations when given local ones, that compute nonlocal De Morgan
; duals of formulas when given local ones, and that compute nonlocal
; introduction and cut rules when given local ones. Perhaps also
; implement something that performs cut elimination on a derivation.
; If we provide these things, it will be easier for clients to extend
; the `mediary-mll?` logic while preserving the idea that it's MLL.
;
(struct-of-procedures
  mediary-mll-rep
  mediary-mll?
  make-mediary-mll
  
  [mediary-deductive-system mediary-deductive-system?]
  
  ; (one) (A times B) symmetric-monoidal
  [times mediary-mll-times
    [mediary-deductive-system mediary-deductive-system?]
    symmetric-monoidal-connective?]
  ; (bot) (A par B) symmetric-monoidal
  [par mediary-mll-par
    [mediary-deductive-system mediary-deductive-system?]
    symmetric-monoidal-connective?]
  
  ; (one) (A times B) (bot) (A par B) linearly-distributive
  ; i.e.
  ; A, B, C deductive-formula; |- A and (B or C) => (A and B) or C
  [switch mediary-mll-switch
    [mediary-deductive-system mediary-deductive-system?]
    [and monoidal-connective?]
    [or monoidal-connective?]
    linearly-distributive-logic?])

; TODO: Implement languages, transparent instances, and interpreters
; for the `mediary-mll?` interface.


; We use the term "MLLish formula" to refer to a bundle of two
; deductive formulas (`A` and its negation `~A`) that comes bundled
; with derivations for introduction (aka axiom, `one => (~A par A)`)
; and cut (`(A times ~A) => bot`).
;
; If all the formulas that are used with a `mediary-mll?` logic are
; MLLish formulas, then these bundled features act as the missing
; identity derivations, negation connective, and introduction and cut
; rules to make it full MLL.
;
(struct-with-contracts
  mllish-formula-rep
  mllish-formula?
  unmatchable-mllish-formula
  make-mllish-formula
  [a deductive-formula?]
  [not-a deductive-formula?]
  [intro (list/c any/c any/c)])


; What we're calling a "duoidal logic" is a logic that corresponds
; with a duoidal semicategory. The distinguishing feature of a duoidal
; category is that its two monoidal structures have an exchange law,
; and when logics are presented in the calculus of structures, the
; same kind of law is known as a medial law.
;
; A logic in the calculus of structures often has several medial laws.
; In that case, we'll say it has duoidal logic structure in multiple
; ways, represented by having multiple methods with `duoidal-logic?`
; return values.
;
(struct-of-procedures
  duoidal-logic-rep
  duoidal-logic?
  make-duoidal-logic
  
  [mediary-deductive-system mediary-deductive-system?]
  
  ; (0) (A + B) monoidal
  [times duoidal-logic-plus
    [mediary-deductive-system mediary-deductive-system?]
    monoidal-connective?]
  ; (top) (A & B) monoidal
  [par duoidal-logic-with
    [mediary-deductive-system mediary-deductive-system?]
    monoidal-connective?]
  
  ; A, B, C, D deductive-formula;
  ; |- (A & B) + (C & D) => (A + C) & (B + D)
  [medial duoidal-logic-medial
    [a deductive-formula?]
    [b deductive-formula?]
    [c deductive-formula?]
    [d deductive-formula?]
    any/c]
  
  ; The medial rule above works for binary `+` and binary `&`, but it
  ; can also apply to any other arities of those connectives. Let's
  ; call a medial rule "M by N" when it applies to a `+` of arity M
  ; and a `&` of arity N. Let's go over the cases.
  ;
  ; 0 by 0:
  ;
  ; We show that the rule `|- 0 => top` is deducible:
  ;
  ;    0
  ;    0        +        0
  ;   (0 & top) + (top & 0)
  ;   -- 2 by 2 medial rule --
  ;   (0 + top) & (top + 0)
  ;        top  &  top
  ;        top
  ;
  ; 0 by 1:
  ;
  ; The rule `|- 0 => 0` needs only an empty derivation.
  ;
  ; 0 by 2:
  ;
  ; We show that the rule `|- 0 => 0 & 0` is deducible:
  ;
  ;    0
  ;    0      &      top
  ;   (0 + 0) & (0 + top)
  ;   -- medial rule --
  ;   (0 & 0) + (0 & top)
  ;   (0 & 0) +  0
  ;    0 & 0
  ;
  ; 0 by N for (3 <= N):
  ;
  ; These rules can be deduced straightforwardly from the 0 by 2
  ; medial rule we've just shown:
  ;
  ;   |- 0 => 0 & 0 & 0
  ;   |- 0 => 0 & 0 & 0 & 0
  ;   ...
  ;
  ; 1 by 0:
  ;
  ; This is the dual of the 0 by 1 case. All our inference rules are
  ; dualizable if we also dualize the formulas so that `0`, `+`,
  ; `bot`, and `&` are respectively replaced with `bot`, `&`, `0`, and
  ; `+`, so that's all we need to do here.
  ;
  ; 1 by N for (1 <= N):
  ;
  ; These rules also need only empty derivations:
  ;
  ;   A deductive-formula; |- A => A
  ;   A, B deductive-formula; |- (A & B) => (A) & (B)
  ;   A, B, C deductive-formula; |- (A & B & C) => (A) & (B) & (C)
  ;   ...
  ;
  ; M by N for (M <= 1):
  ;
  ; These are duals of cases we've already shown.
  ;
  ; 2 by 2:
  ;
  ; This is the medial rule we're building the rest of these from in
  ; the first place.
  ;
  ; M by 2 for (3 <= M):
  ;
  ; What we need to show is:
  ;
  ;   A00, A10, ..., A01, A11 ... deductive-formula;
  ;   |- (A00 & A01) + (A10 & A11) + ...
  ;   => (A00 + A10 + ...) & (A01 + A11 + ...)
  ;
  ; We can use induction here, relying on the (M - 1) by 2 medial
  ; rule:
  ;
  ;   (A00 & A01) + (A10 & A11) + ...
  ;   -- add parentheses --
  ;   (A00 & A01) + ((A10 & A11) + (A20 & A21) + ...))
  ;   -- apply the (M - 1) by 2 medial rule on the second term --
  ;   (A00 & A01) + ((A10 + A20 + ...) & (A11 + A21 + ...))
  ;   -- apply the 2 by 2 medial rule on the whole formula --
  ;   (A00 + (A10 + A20 + ...)) & (A01 + (A11 + A21 + ...))
  ;   -- remove parentheses --
  ;   (A00 + A10 + ...) & (A01 + A11 + ...)
  ;
  ; 2 by N for (3 <= N):
  ;
  ; These cases are duals of the ones we've just shown.
  ;
  ; M by N for (3 <= M) and (3 <= N):
  ;
  ; This covers the remaining cases, and actually, our argument for
  ; the M by 2 case is a special case of what we'll do here. What we
  ; need to show is:
  ;
  ;   A00, A10, ..., A01, A11 ..., ... deductive-formula;
  ;   |- (A00 & A01 & ...) + (A10 & A11 & ...) + ...
  ;   => (A00 + A10 + ...) & (A01 + A11 + ...) & ...
  ;
  ; We'll use induction again, relying on the (M - 1) by N and 2 by N
  ; medial rules. Here's how we compose them to reach our goal:
  ;
  ;   (A00 & A01 & ...) + (A10 & A11 & ...) + ...
  ;
  ;   -- add parentheses --
  ;
  ;   (A00 & A01 & ...
  ;   ) + ((A10 & A11 & ...) + (A20 & A21 & ...) + ...)
  ;
  ;   -- apply the (M - 1) by N medial rule on the second term --
  ;
  ;   (A00 & A01 & ...
  ;   ) + ((A10 + A20 + ...) & (A11 + A21 + ...) & ...)
  ;
  ;   -- apply the 2 by N medial rule on the whole formula --
  ;
  ;   (A00 + (A10 + A20 + ...)) & (A01 + (A11 + A21 + ...)) & ...
  ;
  ;   -- remove parentheses --
  ;
  ;   (A00 + A10 + ...) & (A01 + A11 + ...) & ...
  ;
  ; And there we have it.
  ;
  ;
  ; It's interesting that none of these proofs rely on having
  ; commutativity of `&` or commutativity of `+`. In fact, it seems
  ; this argument might apply just as well without associativity
  ; either. The arities would be something more general than natural
  ; numbers, but we could probably still get the (M1 + M2) by N medial
  ; rule by composing the M2 by N and (M1 + 1) by N rules.
  ;
  ; We only needed the unit laws for the nullary case, too. So it's
  ; possible we don't even need monoidal structures for the medial
  ; rule to be interesting.
  
  )


; This system nearly corresponds to KS, a presentation of classical
; logic ("K") in the calculus of structures ("S"). The difference is
; that this system doesn't have identity derivations, atoms, or
; negation. That makes it related to classical logic the same way our
; "mediary MLL" is related to MLL, so we call this
; "mediary classical logic."
;
; Semi classical logic is just like mediary MLL, but it introduces a
; medial rule that lets `par` and `times` (now called `or` and `and`)
; distribute in the opposite way they distribute in MLL.
;
; Not all calculus of structures systems use this particular medial
; rule. For instance, system LLS (linear logic (LL) in the calculus
; of structures (S)) has medial rules acting on three different pairs
; of the four monoidal connectives in that logic, but since none of
; those pairs relates the two multiplicative connectives (much less
; in the same direction this system does), it doesn't cause the
; multiplicative sublanguage to form a classical logic.
;
; System LLS (and the symmetric system SLLS which reduces to it using
; a cut elimination proof) is discussed here:
;
;   A Local System for Linear Logic
;   Lutz Straßburger 2002
;   https://www.lix.polytechnique.fr/~lutz/papers/lls.pdf
;
; System KS (and the symmetric system SKS which redues to it using a
; cut elimination proof) is discussed here:
;
;   Deep Inference and Symmetry in Classical Proofs
;   Kai Brünnler 2004
;   http://cs.bath.ac.uk/ag/kai/phd.pdf
;
(struct-of-procedures
  mediary-classical-logic-rep
  mediary-classical-logic?
  make-mediary-classical-logic
  
  ; (true) (A and B) (false) (A or B) mediary-mll
  ; i.e.
  ; A, B, C deductive-formula; |- A and (B or C) => (A and B) or C
  [mll mediary-classical-logic-mll mediary-mll?]
  
  ; (false) (A or B) (true) (A and B) duoidal
  ; i.e.
  ; A, B, C, D deductive-formula;
  ; |- (A and B) or (C and D) => (A or C) and (B or D)
  [medial mediary-classical-logic-medial
    [mediary-deductive-system mediary-deductive-system?]
    [or monoidal-connective?]
    [and monoidal-connective?]
    duoidal-logic?]
  
  )

; TODO: Implement languages, transparent instances, and interpreters
; for the `mediary-classical-logic?` interface.


; We use the term "classical formula" to refer to a bundle of an
; MLLish formula (bundling `A` and its negation `~A`) that comes also
; bundled with derivations for:
;
;   ; Weakening
;   false => A
;
;   ; Co-weakening
;   A => true
;
;   ; Contraction
;   (A and A) => A
;
;   ; Co-contraction
;   A => (A or A)
;
; And likewise for `~A`.
;
; If all the formulas that are used with a `mediary-classical-logic?`
; are classical formulas, then these bundled features act as the
; missing identity derivations, negation connective, and introduction,
; cut, (co-)weakening, and (co-)contraction rules to make it full
; classical logic.
;
(struct-with-contracts
  classical-formula-rep
  classical-formula?
  unmatchable-classical-formula
  make-classical-formula
  [a classical-formula?]
  [a-weakening (list/c any/c any/c)]
  [a-contraction (list/c any/c any/c)]
  [not-a-weakening (list/c any/c any/c)]
  [not-a-contraction (list/c any/c any/c)])


; The full logic of MLL as presented in the calculus of structures,
; including identity derivations, a negation connective, and rules for
; atoms.
;
; Note that instances of this interface must allow deep inference over
; the negation connective, which means some derivations will be
; applied in reverse. This might be something that not every
; `mediary-mll?` instance can be extended to do. In fact, the
; `mediary-mll?` instance this interface exposes must be one that
; expresses `bot` and `A par B` in terms of the negation connective as
; `~1` and `~(~A * ~B)`. To convert another `mediary-mll?` instance to
; this style, it may be necessary to work with explicit De Morgan
; laws.
;
; The categories analogous to this logic are the star-autonomous
; categories.
;
(struct-of-procedures
  mll-rep
  mll?
  make-mll
  
  ; (A => B) deductive-system
  ; i.e.
  ; A, B, C formula; A => B, B => C |- A => B
  ; A formula; |- A => A
  [deductive-system deductive-system?]
  
  ; (1) (A * B) symmetric-monoidal
  [times mll-times
    [mediary-deductive-system mediary-deductive-system?]
    symmetric-monoidal-connective?]
  
  ; (~A) contra-unary
  [not mll-not
    [mediary-deductive-system mediary-deductive-system?]
    contra-unary-connective?]
  
  ; (1) (A * B) (~1) (~(~A * ~B)) intermediary-mll
  [intermediation mll-intermediation
    [mediary-deductive-system mediary-deductive-system?]
    [times symmetric-monoidal-connective?]
    [par symmetric-monoidal-connective?]
    intermediary-mll?]
  
  ; TODO: See if this should be factored out into its own logic called
  ; `involutive-unary-connective?`.
  ;
  ; A formula; |- ~~A <=> A
  [double-negation-elimination mll-double-negation-elimination
    [a any/c]
    (list/c any/c any/c)]
  
  ; NOTE: We choose to put the negation on the side of the `*` that
  ; makes this like a left-to-right implication. If linear implication
  ; is `A -o B`, then the formula `~(A * ~B)` is equivalent to
  ; `A -o B`, and `A * ~B` is equivalent to `~(A -o B)`).
  ;
  ; A formula; |- 1 => ~(A * ~A)
  ; A formula; |- (A * ~A) => ~1
  [intro mll-intro [a any/c] (list/c any/c any/c)])


; This is an expression of full classical logic in the SKS style.
; (That's the symmetric version (S) of the presentation of classical
; logic (K) in the calculus of structures.) This version offers
; introduction, cut, (co-)contraction, and (co-)weakening rules on all
; atoms, and it offers a negation connective.
;
; NOTE:
;
; In a way, this "enforces" some proof-theoretic properties that the
; `mediary-classical-logic?` interface allows to be upheld in a
; good-faith way. In particular, it enforces that identity derivations
; and intro, cut, (co-)contraction, and (co-)weakening rules can be
; computed for any given formula.
;
; A `mediary-classical-logic?` value may have already offered those
; features external to the `mediary-classical-logic?` interface, and
; we expect `mediary-classical-logic?` to be a sufficient amount of
; functionality for systems we build here in Lathe Morphisms (just as
; `mediary-deductive-system?` has been enough for most of these
; logics). We're building these interfaces for logics just so we can
; use them to express the laws of our interfaces for categories, and
; when we do that, we can simply have our categories provide their own
; bespoke intro, cut, (co-)contraction, and (co-)weakening rules for
; their equality and apartness relations.
;
; We've built this `classical-logic?` interface basically just to show
; we can. We could potentially go even further and make other other
; proof-theoretic properties available in a constructive way, like
; providing the ability to compute from any derivation to a cut-free
; derivation. We don't do this; the sweet spot we've chosen is to
; offer a full set of inference rules on atoms while mostly ignoring
; the possibility that one derivation value might be preferred over
; another.
;
; If we ever model derivation systems where we care about operations
; on derivation values, we will probably find success in treating
; those derivations as the morphisms of a category and taking
; advantage category-theoretic tools. Since we already intend to
; develop category theory interfaces out of this, we'll be able to
; build the new derivation systems on that foundation.
;
(struct-of-procedures
  classical-logic-rep
  classical-logic?
  make-classical-logic
  
  ; (true) (A and B) (false) (A or B) mll
  ; i.e.
  ; A, B, C formula; |- A and (B or C) => (A and B) or C
  ; A formula; |- A => A
  ; A formula; |- 1 => ~(A * ~A)
  ; A formula; |- (A * ~A) => ~1
  [mll classical-logic-mll mll?]
  
  ; (true) (A and B) (false) (A or B) mediary-classical-logic
  ; i.e.
  ; A, B, C, D formula;
  ; |- (A and B) or (C and D) => (A or C) and (B or D)
  [mediary classical-logic-mediary [mediary-mll mediary-mll?]
    mediary-classical-logic?]
  
  ; A formula; |- false => A
  ; A formula; |- A => true
  [weakening classical-logic-weakening [a any/c]
    (list/c any/c any/c)]
  
  ; A formula; |- (A and A) => A
  ; A formula; |- A => (A or A)
  [contraction classical-logic-contraction [a any/c]
    (list/c any/c any/c)])



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
