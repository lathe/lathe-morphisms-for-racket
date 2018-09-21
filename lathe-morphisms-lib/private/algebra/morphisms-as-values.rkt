#lang parendown racket/base

; lathe-morphisms/private/algebra/morphisms-as-values
;
; Implementations of category-theoretic concepts where a category's
; morphisms correspond to values at run time, but its objects and
; equivalences are erased. For higher categories, the cells that
; correspond to run time values are the ones that have notions of
; equivalence.

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
  -> ->* any any/c cons/c listof)
(require #/only-in racket/contract/region define/contract)

(require #/only-in lathe-comforts
  dissect dissectfn expect expectfn fn)
(require #/only-in lathe-comforts/list list-foldl list-foldr list-map)

(require #/only-in lathe-morphisms/private/algebra/conceptual
  category category?
  functor functor?
  natural-transformation natural-transformation?
  
  terminal-object terminal-object?
  particular-binary-product particular-binary-product?
  binary-products binary-products?
  particular-pullback particular-pullback?
  pullbacks pullbacks?
  particular-exponential-object particular-exponential-object?
  exponential-objects exponential-objects?
  morphism-inverses morphism-inverses?
  category-monoidal-structure category-monoidal-structure?
  tensorial-strength tensorial-strength?
  bicategory bicategory?
  monad monad?
)

(provide #/all-defined-out)



; ===== Miscellaneous definitions that haven't been sorted yet =======


; These definitions are based on the docummented signatures in
; lathe-morphisms/private/algebra/conceptual.rkt. We're using an
; encoding where all those signatures are thought of as a dependent
; sum at the top level, and:
;
;  - A dependent sum or binary product is represented as a cons cell
;    if both of its elements have run time content, with no run time
;    content at all if neither does, and as only the value that has
;    run time content if there's only one.
;
;  - A dependent product is represented as a function if both its
;    domain and codomain have run time content, with no run time
;    content at all if the codomain doesn't have run time content, and
;    as only a codomain value if that one has run time content and the
;    domain doesn't.
;
;  - A type has no run time content.
;
;  - An equivalence has no run time content.
;
;  - An inhabitant of a type in a theory that has no concept of
;    equivalence has no run time content, unless that inhabitant is
;    the interpretation of an inhabitant in another theory that does
;    have run time content.
;
;  - An inhabitant of a type in a theory that does have a concept of
;    equivalence does have run time content, and this run time content
;    is a value that is completely unverified. As we reason about
;    equivalences on these run time values, these values are
;    considered equivalent when they lead to pretty much the same
;    observations, perhaps with a few informal exceptions so that
;    `eq?` observations, performance measurements, unsafe pointer
;    manipulations, and other hard-to-code-defensively-against
;    observations don't really count as observations we care about.
;
;  - At the outermost level, if the entire type has no run time
;    content but we must represent its values anyway, we represent
;    them as an empty list.
;
; For most of these utilities, we're dealing with categories, and they
; require a notion of equivalence for morphisms but not for objects,
; so the morphisms are our unrestricted first-class values there.
;
; For a few of these utilities, we're dealing with bicategories, and
; they require a notion of equivalence for 2-cells, but not for
; 1-cells or 0-cells, so the 2-cells are our unrestricted first-class
; values there.
;
; TODO: The module name "morphisms-as-values" didn't really pan out as
; a complete description of what we're doing once bicategories entered
; the picture. See if we should call this module
; "strict-cells-as-values" or something.


; Category:

(define/contract (make-category id compose)
  (-> any/c (-> (cons/c any/c any/c) any) category?)
  (category #/cons id #/dissectfn (cons g f) #/compose g f))

; NOTE: The procedures `category-{compose,seq}{,-list}` are the same
; aside from their calling conventions.

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


; Functor:

(define/contract (make-functor map)
  (-> (-> any/c any) functor?)
  (functor #/fn morphism #/map morphism))

(define/contract (functor-map ftr morphism)
  (-> functor? any/c any)
  (dissect ftr (functor map)
  #/map morphism))


; Natural transformation:

(define/contract (make-natural-transformation component)
  (-> any/c natural-transformation?)
  (natural-transformation component))

(define/contract (natural-transformation-component nt)
  (-> natural-transformation? any/c)
  (dissect nt (natural-transformation component)
    component))

; TODO: See if the rest of these natural transformation utilities
; should be set apart as "[Metatheoretical construction]" concepts.

; NOTE: The procedures `natural-transformation-{compose,seq}{,-list}`
; are the same aside from their calling conventions.

(define/contract (natural-transformation-compose-list category-t nts)
  (-> category? (listof natural-transformation?)
    natural-transformation?)
  (make-natural-transformation #/category-compose-list category-t
  #/list-map nts #/fn nt #/natural-transformation-component nt))

(define/contract (natural-transformation-compose category-t . nts)
  (->* (category?) #:rest (listof natural-transformation?)
    natural-transformation?)
  (natural-transformation-compose-list category-t nts))

(define/contract (natural-transformation-seq-list category-t nts)
  (-> category? (listof natural-transformation?)
    natural-transformation?)
  (make-natural-transformation #/category-seq-list category-t
  #/list-map nts #/fn nt
    (dissect nt (natural-transformation component)
      component)))

(define/contract (natural-transformation-seq category-t . nts)
  (->* (category?) #:rest (listof natural-transformation?)
    natural-transformation?)
  (natural-transformation-seq-list category-t nts))

; NOTE: The procedure `natural-transformation-whisker-source` is the
; identity function, but with a more specific type.
(define/contract (natural-transformation-whisker-source nt)
  (-> natural-transformation? natural-transformation?)
  nt)

; NOTE: The procedures
; `natural-transformation-compose-whiskering-target` and
; `natural-transformation-seq-whiskering-target` are the same but with
; their arguments reversed.

(define/contract
  (natural-transformation-compose-whiskering-target functor nt)
  (-> functor? natural-transformation? natural-transformation?)
  (make-natural-transformation
  #/functor-map functor #/natural-transformation-component nt))

(define/contract
  (natural-transformation-seq-whiskering-target nt functor)
  (-> natural-transformation? functor? natural-transformation?)
  (make-natural-transformation
  #/functor-map functor #/natural-transformation-component nt))

; NOTE: The nullary horizontal composition
; `natural-transformation-horizontally-compose-zero` is a special case
; of the nullary vertical composition performed by calling
; `natural-transformation-compose`, with a more specific type.
(define/contract
  (natural-transformation-horizontally-compose-zero category-t)
  (-> category? natural-transformation?)
  (natural-transformation-compose category-t))

(define/contract
  (natural-transformation-horizontally-compose-two-with-source-functor
    category-t functor-gs g f)
  (->
    category? functor? natural-transformation? natural-transformation?
    natural-transformation?)
  (natural-transformation-compose category-t
    (natural-transformation-whisker-source g)
    (natural-transformation-compose-whiskering-target functor-gs f)))

(define/contract
  (natural-transformation-horizontally-compose-two-with-target-functor
    category-t functor-gt g f)
  (->
    category? functor? natural-transformation? natural-transformation?
    natural-transformation?)
  (natural-transformation-compose category-t
    (natural-transformation-compose-whiskering-target functor-gt f)
    (natural-transformation-whisker-source g)))


; Terminal object:

(define/contract (make-terminal-object terminal-map)
  (-> any/c terminal-object?)
  (terminal-object terminal-map))

(define/contract (terminal-object-terminal-map t)
  (-> terminal-object? any/c)
  (dissect t (terminal-object terminal-map)
    terminal-map))


; Binary product of two objects in particular:

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


; The quality of having all binary products:

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


; TODO: See if this should be set apart as a
; "[Metatheoretical construction]".
(define/contract (general-to-particular-binary-product bp)
  (-> binary-products? particular-binary-product?)
  (dissect bp (binary-products rep)
  #/particular-binary-product rep))


; Pullback of a particular cospan:

(define/contract (make-particular-pullback fst snd pair)
  (-> any/c any/c (-> any/c any/c any/c) particular-pullback?)
  (particular-pullback #/list* fst snd #/dissectfn (cons sa sb)
    (pair sa sb)))

(define/contract (particular-pullback-fst p)
  (-> particular-pullback? any/c)
  (dissect p (particular-pullback #/list* fst snd pair)
    fst))

(define/contract (particular-pullback-snd p)
  (-> particular-pullback? any/c)
  (dissect p (particular-pullback #/list* fst snd pair)
    snd))

(define/contract (particular-pullback-pair p sa sb)
  (-> particular-pullback? any/c any/c any/c)
  (dissect p (particular-pullback #/list* fst snd pair)
  #/pair #/cons sa sb))


; The quality of having all pullbacks:

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


; TODO: See if this should be set apart as a
; "[Metatheoretical construction]".
(define/contract (general-to-particular-pullback p at bt)
  (-> pullbacks? any/c any/c particular-pullback?)
  (make-particular-pullback
    (pullbacks-fst p at bt)
    (pullbacks-snd p at bt)
    (fn sa sb #/pullbacks-pair p at bt sa sb)))


; A particular exponential object:

(define/contract
  (make-particular-exponential-object call-domain call curry)
  (->
    particular-binary-product?
    any/c
    (-> particular-binary-product? any/c any/c)
    particular-exponential-object?)
  (expect call-domain
    (particular-binary-product #/list*
      call-domain-fst call-domain-snd call-domain-pair)
    (error "Expected a particular-binary-product based on the morphisms-as-values theories")
  #/particular-exponential-object #/list*
    call-domain-fst call-domain-snd call-domain-pair call
  #/dissectfn
    (list*
      imitation-call-domain-fst
      imitation-call-domain-snd
      imitation-call-domain-pair
      imitation-call)
    (curry
      (particular-binary-product #/list*
        imitation-call-domain-fst
        imitation-call-domain-snd
        imitation-call-domain-pair)
      imitation-call)))

(define/contract (particular-exponential-object-call-domain eo)
  (-> particular-exponential-object? particular-binary-product?)
  (dissect eo
    (particular-exponential-object #/list*
      call-domain-fst call-domain-snd call-domain-pair call curry)
  #/particular-binary-product #/list*
    call-domain-fst call-domain-snd call-domain-pair))

(define/contract (particular-exponential-object-call eo)
  (-> particular-exponential-object? any/c)
  (dissect eo
    (particular-exponential-object #/list*
      call-domain-fst call-domain-snd call-domain-pair call curry)
    call))

(define/contract
  (particular-exponential-object-curry
    eo imitation-call-domain imitation-call)
  (-> particular-exponential-object? particular-binary-product? any/c
    any/c)
  (dissect eo
    (particular-exponential-object #/list*
      call-domain-fst call-domain-snd call-domain-pair call curry)
  #/dissect imitation-call-domain
    (particular-binary-product #/list*
      imitation-call-domain-fst
      imitation-call-domain-snd
      imitation-call-domain-pair)
  #/curry
    imitation-call-domain-fst
    imitation-call-domain-snd
    imitation-call-domain-pair
    imitation-call))


; The quality of having all exponential objects
; (closed category structure):

(define/contract (make-exponential-objects call-domain call curry)
  (->
    particular-binary-product?
    any/c
    (-> particular-binary-product? any/c any/c)
    exponential-objects?)
  (expect call-domain
    (particular-binary-product #/list*
      call-domain-fst call-domain-snd call-domain-pair)
    (error "Expected a particular-binary-product based on the morphisms-as-values theories")
  #/exponential-objects #/list*
    call-domain-fst call-domain-snd call-domain-pair call
  #/dissectfn
    (list*
      imitation-call-domain-fst
      imitation-call-domain-snd
      imitation-call-domain-pair
      imitation-call)
    (curry
      (particular-binary-product #/list*
        imitation-call-domain-fst
        imitation-call-domain-snd
        imitation-call-domain-pair)
      imitation-call)))

(define/contract (exponential-objects-call-domain eo)
  (-> exponential-objects? particular-binary-product?)
  (dissect eo
    (exponential-objects #/list*
      call-domain-fst call-domain-snd call-domain-pair call curry)
  #/particular-binary-product #/list*
    call-domain-fst call-domain-snd call-domain-pair))

(define/contract (exponential-objects-call eo)
  (-> exponential-objects? any/c)
  (dissect eo
    (exponential-objects #/list*
      call-domain-fst call-domain-snd call-domain-pair call curry)
    call))

(define/contract
  (exponential-objects-curry eo imitation-call-domain imitation-call)
  (-> particular-exponential-object? particular-binary-product? any/c
    any/c)
  (dissect eo
    (exponential-objects #/list*
      call-domain-fst call-domain-snd call-domain-pair call curry)
  #/dissect imitation-call-domain
    (particular-binary-product #/list*
      imitation-call-domain-fst
      imitation-call-domain-snd
      imitation-call-domain-pair)
  #/curry
    imitation-call-domain-fst
    imitation-call-domain-snd
    imitation-call-domain-pair
    imitation-call))


; TODO: See if this should be set apart as a
; "[Metatheoretical construction]".
(define/contract (general-to-particular-exponential-object eo)
  (-> exponential-objects? particular-exponential-object?)
  (dissect eo (exponential-objects rep)
  #/particular-exponential-object rep))


; A particular one-sided inverse on morphisms:
;
; (Nothing. There is no run time content to represent.)


; A particular isomorphism:
;
; (Nothing. There is no run time content to represent.)


; The quality of having all inverse morphisms (groupoid structure):

(define/contract (make-morphism-inverses invert)
  (-> (-> any/c any/c) morphism-inverses?)
  (morphism-inverses invert))

(define/contract (morphism-inverses-invert i morphism)
  (-> morphism-inverses? any/c any/c)
  (dissect i (morphism-inverses invert)
  #/invert morphism))


; Natural isomorphism:
;
; (Nothing. There is no run time content to represent.)


; [Metatheoretical construction] Product category:

(define/contract (product-category a b)
  (-> category? category? category?)
  (make-category (cons (category-compose a) (category-compose b))
  #/fn g f
    (expect g (cons ga gb)
      (error "Expected each morphism of a product category to be a pair")
    #/expect f (cons fa fb)
      (error "Expected each morphism of a product category to be a pair")
    #/cons (category-compose a ga fa) (category-compose b gb fb))))


; [Metatheoretical construction] Terminal category:

(define/contract (terminal-category)
  (-> category?)
  (make-category (list) #/fn g f
    (expect g (list)
      (error "Expected each morphism of the terminal category to be an empty list")
    #/expect f (list)
      (error "Expected each morphism of the terminal category to be an empty list")
    #/list)))

; [Metatheoretical construction] Bimap functor:

(define/contract (bimap-functor a b)
  (-> functor? functor? functor?)
  (make-functor #/fn f
    (expect f (cons fa fb)
      (error "Expected each morphism of a product category to be a pair")
    #/cons (functor-map a fa) (functor-map b fb))))


; [Metatheoretical construction] Global element functor:

(define/contract (global-element-functor c)
  (-> category? functor?)
  (make-functor #/expectfn (list)
    (error "Expected each morphism of the terminal category to be an empty list")
    (category-compose c)))


; [Metatheoretical construction] Left unit introduction functor:

(define/contract (left-unit-intro-functor)
  (-> functor?)
  (make-functor #/fn f
    (cons (list) f)))


; [Metatheoretical construction] Right unit introduction functor:

(define/contract (right-unit-intro-functor)
  (-> functor?)
  (make-functor #/fn f
    (cons f (list))))


; [Metatheoretical construction] Left associator functor:

(define/contract (left-associator-functor)
  (-> functor?)
  (make-functor #/expectfn (cons a (cons b c))
    (error "Expected each morphism of a product category to be a pair")
    (cons (cons a b) c)))


; [Metatheoretical construction] Identity functor:
; [Metatheoretical construction] Composition of functors:

; NOTE: The procedures `functor-{compose,seq}{,-list}` are the same
; aside from their calling conventions.

(define/contract (functor-compose-list functors)
  (-> (listof functor?) functor)
  (make-functor #/fn morphism
    (list-foldr functors morphism #/fn functor morphism
      (functor-map functor morphism))))

(define/contract (functor-compose . functors)
  (->* () #:rest (listof functor?) functor)
  (functor-compose-list functors))

(define/contract (functor-seq-list functors)
  (-> (listof functor?) functor)
  (make-functor #/fn morphism
    (list-foldl morphism functors #/fn morphism functor
      (functor-map functor morphism))))

(define/contract (functor-seq . functors)
  (->* () #:rest (listof functor?) functor)
  (functor-seq-list functors))


; Monoidal structure on a category's objects
; (monoidal category structure):

; Since it might be unclear what's going on here: The only run time
; component of one of these is a function, `append-functor-map`, that
; takes a pair (cons cell) of two morphism values and returns a
; morphism value. If the two input morphisms go from `a` to `b` and
; from `c` to `d` respectively, then the output morphism goes from
; `(append a c)` to `(append b d)`, where `append` satisfies various
; laws showing it's a monoidal way to combine two objects.
;
; For instance, we might have a category of finite-length tuple types
; and transformations between them, where each transformation is
; tagged with the length of its domain tuple type. This category has a
; monoidal structure where `append` concatenates two tuple types. In
; this case, `append-functor-map` takes two transformations and
; creates another transformation that works by applying the first one
; to the first part of its tuple value and the second one to the rest,
; concatenating the resulting tuple values.

(define/contract (make-category-monoidal-structure append-functor)
  (-> functor? category-monoidal-structure?)
  (dissect append-functor (functor append-functor-map)
  #/category-monoidal-structure append-functor-map))

(define/contract (category-monoidal-structure-append-functor cms)
  (-> category-monoidal-structure? functor?)
  (dissect cms (category-monoidal-structure append-functor-map)
  #/functor append-functor-map))

; One of the most common examples of monoidal structure is when the
; category has all finite products (i.e. has a terminal object and all
; binary products). Then the binary product operation is the `append`
; of this monoidal structure, and `append-functor-map` works by taking
; the product apart with `binary-products-fst` and
; `binary-products-snd`, composing those respectively with the two
; morphisms in the product category morphism we're mapping over, and
; then zipping the results back together with `binary-products-pair`.
;
; TODO: See if this should be set apart as a
; "[Metatheoretical construction]".
;
(define/contract (finite-products-to-monoidal-structure c p)
  (-> category? binary-products? category-monoidal-structure?)
  (make-category-monoidal-structure
  #/make-functor #/expectfn (cons a b)
    (error "Expected each morphism of a product category to be a pair")
    (binary-products-pair p
      (category-compose c a #/binary-products-fst p)
      (category-compose c b #/binary-products-snd p))))


; Tensorial strength (the strong functor condition):

(define/contract (make-tensorial-strength nt)
  (-> natural-transformation? tensorial-strength?)
  (dissect nt (natural-transformation nt-component)
  #/tensorial-strength nt-component))

(define/contract (tensorial-strength-nt ts)
  (-> tensorial-strength? natural-transformation?)
  (dissect ts (tensorial-strength nt-component)
  #/natural-transformation nt-component))


; Bicategory:

; Since it might be unclear what's going on here: The only run time
; component of one of these is a function, `compose-functor-map`, that
; takes a pair (cons cell) of two 2-cell values and returns the 2-cell
; value that horizontally composes them. Suppose the two input 2-cells
; go from `bcs` to `bct` and from `abs` to `abt` respectively, where
; `bcs` and `bct` are 1-cells from `b` to `c`; `abs` and `abt` are
; 1-cells from `a` to `b`; and `c`, `b`, and `a` are 0-cells. Then the
; output 2-cell goes from `(compose bcs abs)` to `(compose bct abt)`.

(define/contract (make-bicategory compose-functor)
  (-> functor? bicategory?)
  (dissect compose-functor (functor compose-functor-map)
  #/bicategory compose-functor-map))

(define/contract (bicategory-compose-functor b)
  (-> bicategory? functor?)
  (dissect b (bicategory compose-functor-map)
  #/functor compose-functor-map))

; A monoidal category is a bicategory with a single 0-cell.
;
; TODO: See if this should be set apart as a
; "[Metatheoretical construction]".
;
(define/contract (category-monoidal-structure-to-bicategory cms)
  (-> category-monoidal-structure? bicategory?)
  (dissect cms (category-monoidal-structure append-functor-map)
  #/bicategory append-functor-map))


; Monad:

(define/contract (make-monad empty append)
  (-> any/c any/c monad?)
  (monad #/cons empty append))

(define/contract (monad-empty m)
  (-> monad? any/c)
  (dissect m (monad #/cons empty append)
    empty))

(define/contract (monad-append m)
  (-> monad? any/c)
  (dissect m (monad #/cons empty append)
    append))

; Given any Cartesian monoidal category, any monad over it (in the
; bicategory `Cat` of categories, functors, and natural
; transformations) with functor `f.<etc>`, any tensorial strength on
; that functor `s`, any objects `a` and `b` in the category, and a
; particular exponential object with domain `a` and codomain `b`, this
; constructs a morphism with domain
; `(product (exponential-object a b) (f.transform-obj a))` and
; codomain `(f.transform-obj b)`.
;
; In most functional programming languages, the syntactic category
; (the category where the objects correspond to the language's types
; and the morphisms correspond the language's terms) always has the
; same implementation of `c`, `s`, and `eo` for every monad, so this
; operation is available for every monad as long as the witnesses `m`
; and `f` for that monad and its underlying functor are available at
; run time.
;
; TODO: Hmm, we should be able to generalize this to any monoidal
; category, not just a Cartesian monoidal one. Instead of using a
; particular exponential object, we would use a particular
; internal hom. (An exponential object is an internal hom in a
; Cartesian monoidal category.) Is there a way to define a
; "particular" internal hom, or will we have to make it out of an
; adjunction? If there is a way to specify particular ones, we can
; just update this definition to use an internal hom; otherwise, each
; approach could come in handy in different situations, so we might
; want to define both.
;
; TODO: See if this should be set apart as a
; "[Metatheoretical construction]".
;
(define/contract (strong-monad-in-cat-bind c f s m eo)
  (->
    category?
    functor?
    tensorial-strength?
    monad?
    particular-exponential-object?
    any/c)
  (category-seq c
    (natural-transformation-component #/tensorial-strength-nt s)
    (functor-map f #/particular-exponential-object-call eo)
    (natural-transformation-component #/monad-append m)))

; TODO: See if we can somehow extrapolate that monadic bind utility to
; monads in bicategories other than `Cat`. We're almost there with
; this code, but there are various problems with it that I don't
; understand how to approach yet:
;
;   - The `s` parameter is a `tensorial-strength`, and gives us a
;     natural transformation with `tensorial-strength-nt`, but what we
;     really want is a 2-cell this time. Is it standard to generalize
;     tensorial strengths to bicategories?
;
;   - We're missing something we can use in the place where we used an
;     exponential object's evaluation map above. What we needed there
;     was a morphism, and what we need here is a 2-cell that goes from
;     a functor shaped like
;     `(cms.append (eo.exponential-object x -) x)` into the identity
;     functor. Unfortunately, `eo.exponential-object` isn't even a
;     functor here; we'll probably need to demand a witness of the
;     closed Cartesian category structure (and hence we'll need to
;     write a signature for that). That oughta give us some kind of
;     adjunction-like mechanism we can work with to make the right
;     2-cell out of an identity 2-cell on
;     `(eo.exponential-object x -)`. But will the variable `x` here
;     cause any trouble? The overall 2-cell we're building will be
;     "extranatural" in `x`, if extranaturality is even a concept that
;     makes sense when the 2-cells aren't necessarily natural
;     transformations.
;
#;
(define/contract
  (strong-monad-in-a-bicategory-bind b hom-category s m eo)
  (->
    bicategory?
    category?
    tensorial-strength?
    monad?
    particular-exponential-object?
    any/c)
  (category-seq hom-category
    (tensorial-strength-nt s)
    (functor-map (bicategory-compose-functor b) #/cons
      (category-compose hom-category)
      'TODO)
    (monad-append m)))
