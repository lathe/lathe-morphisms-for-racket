#lang parendown racket/base

; lathe-morphisms/private/algebra/conceptual
;
; Algebraic concepts without a particular implementation here, but
; with versatile documentation for each implementation to refer to.

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


(require #/only-in lathe-comforts/struct struct-easy)

(provide
  (struct-out category)
  (struct-out functor)
  (struct-out natural-transformation)
  
  (struct-out terminal-object)
  (struct-out particular-binary-product)
  (struct-out binary-products)
  (struct-out particular-pullback)
  (struct-out pullbacks)
  (struct-out particular-exponential-object)
  (struct-out exponential-objects)
  (struct-out particular-morphism-one-sided-inverse)
  (struct-out particular-isomorphism)
  (struct-out morphism-inverses)
  (struct-out natural-isomorphism)
  (struct-out category-monoidal-structure)
  (struct-out tensorial-strength)
  (struct-out bicategory)
  (struct-out monad)
)



; ===== Miscellaneous definitions that haven't been sorted yet =======

; TODO: Write some definitions.


; For every instance of a run time representation of an algebraic
; concept, there must be some suitable "theories" such that the
; components of that run time value are instances of certain
; (conceptual) types, as documented for that algebraic concept.
;
; (The "theories" are essentially dependent type theories which might
; not be "closed," e.g. having some dependent products but not others.
; We parameterize our algebraic signatures in terms of these theories
; so that programmers can potentially instantiate some of them with
; programmer-defined categories that have enough structure. If this
; doesn't make it easy to work with enriched category theory, we're
; doing something wrong and should reevaluate our "theory"-based
; notation. (TODO:) However, we do not currently define enough
; structure to begin approaching enriched categories in this way, so
; our signatures may be subject to change as we discover mistakes in
; our approach.)
;
; We start with categories:


; Category:
;
;   expect theories "layer 1" and "layer 2" such that:
;     layer 1 can interpret layer 2
;     layer 2 has a notion of equivalence
;
;   expect a type at layer 1:
;     obj
;
;   given these at layer 1:
;     b : obj
;     a : obj
;   expect a type at layer 2:
;     (hom a b)
;
;   given these at layer 1:
;     a : obj
;   postulate a value at layer 2:
;     id : (hom a a)
;   (The value `id-witness` is a layer 2 morphism realizing the
;   layer 2 portion of this construction.)
;
;   given these at layer 1:
;     c : obj
;     b : obj
;     a : obj
;   given these at layer 2:
;     g : (hom b c)
;     f : (hom a b)
;   postulate a value at layer 2:
;     (compose g f) : (hom a c)
;   (The value `compose-witness` is a layer 2 morphism realizing the
;   layer 2 portion of this construction.)
;
;   given these at layer 1:
;     b : obj
;     a : obj
;   given these at layer 2:
;     f : (hom a b)
;   postulate an equivalence over layer 2:
;     left-unitor : (compose id f) = f : (hom a b)
;
;   given these at layer 1:
;     b : obj
;     a : obj
;   given these at layer 2:
;     f : (hom a b)
;   postulate an equivalence over layer 2:
;     right-unitor : (compose f id) = f : (hom a b)
;
;   given these at layer 1:
;     d : obj
;     c : obj
;     b : obj
;     a : obj
;   given these at layer 2:
;     h : (hom c d)
;     g : (hom b c)
;     f : (hom a b)
;   postulate an equivalence over layer 2:
;     associator
;     : (compose (compose h g) f) = (compose h (compose g f))
;     : (hom a d)

(struct-easy (category rep))


; Usually, we interpret each section of "givens" as a dependent
; product from an iterated binary product of the givens (associated to
; the right) into an interpretation of the rest of the signature in
; that layer, where the "interpretation" of an equivalence is an
; identity type. The theories we're dealing with don't necessarily
; need to have all dependent products, all binary products, or all
; identity types, but in order for any construction to satisfy this
; signature, the theories just enough of these things so that the
; signature is well-defined.
;
; For example, consider the notation we're using for the `compose`
; construction:
;
;   given these at layer 1:
;     c : obj
;     b : obj
;     a : obj
;   given these at layer 2:
;     g : (hom b c)
;     f : (hom a b)
;   postulate a value at layer 2:
;     (compose g f) : (hom a c)
;
; This becomes a type something like this if layer 1 and layer 2 each
; have enough dependent products and binary products:
;
;   (layer-1-dependent-products.dependent-product layer-1-givens
;     (layer-1-products.product
;       ; c
;       obj
;     #/layer-1-products.product
;       ; b
;       obj
;       ; a
;       obj)
;   #/layer-1-interpret-layer-2
;   #/layer-2-dependent-products.dependent-product layer-2-givens
;     (layer-2-products.product
;       (hom
;         ; b
;         (layer-1-products.fst #/layer-1-products.snd layer-1-givens)
;         ; c
;         (layer-1-products.fst layer-1-givens))
;       (hom
;         ; a
;         (layer-1-products.snd #/layer-1-products.snd layer-1-givens)
;         ; b
;         (layer-1-products.fst
;         #/layer-1-products.snd layer-1-givens)))
;     (hom
;       ; a
;       (layer-1-products.snd #/layer-1-products.snd layer-1-givens)
;       ; c
;       (layer-1-products.fst layer-1-givens)))
;
; For some category theory concepts, it's useful to stipulate that the
; theory involved has certain *pullbacks*. If we were modeling
; *internal categories* here, we might scrap layer 1 altogether and
; give `compose` a signature like this:
;
;   (layer-2-dependent-products.dependent-product layer-2-givens
;     (layer-2-pullbacks.pullback obj hom hom
;       <a layer-2 morphism witnessing `hom-source`>
;       <a layer-2 morphism witnessing `hom-target`>)
;     hom)
;
; This loses a bit of information from the approach we're using,
; namely the information that the `compose` operation preserves the
; value of `hom-source` on its second argument and `hom-target` on its
; first argument. Internal categories don't actually lose this
; information; they merely enforce it using some additional postulated
; equivalences.
;
; Although it's tempting to find some kind of automatic translation
; between signatures that use pullbacks and signatures that use
; multiple levels of variable bindings, we aren't writing our
; signatures to facilitate this. As such, for internal categories and
; other concepts where pullbacks might be thought of as a
; rarely-brought-up detail of the metatheory, we'll have to manipulate
; them more explicitly than we may like.
;
; In particular, if we model internal categories, we will not expect a
; "theory" that has pullbacks; we will postulate a category (in terms
; of other theories) and use that category's pullbacks explicitly
; rather than calling that category a "theory."


; Functor:
;
;   expect layers-a.<etc> according to Category, such that the
;     theories "layer 1" and "layer 2" expected there are expected
;     here as theories "layer a1" and "layer a2" respectively
;
;   expect layers-b.<etc> according to Category, such that the
;     theories "layer 1" and "layer 2" expected there are expected
;     here as theories "layer b1" and "layer b2" respectively
;
;   expect the theories to behave such that:
;     layer a1 can interpret layer b1
;     layer a2 can interpret layer b2
;     both indirect ways of interpreting layer b2 in a1 are the same
;
;   given these at layer a1:
;     a : layers-a.obj
;   postulate a value at layer b1:
;     (transport-obj a) : layers-b.obj
;
;   given these at layer a1:
;     b : layers-a.obj
;     a : layers-a.obj
;   given these at layer a2:
;     f : (layers-a.hom a b)
;   postulate a value at layer b2:
;     (transport-hom f)
;     : (layers-b.hom (transport-obj a) (transport-obj b))
;
;   given these at layer a1:
;     a : layers-a.obj
;   postulate an equivalence at layer b2:
;     naturality-id
;     : layers-b.id = (transport-hom layers-a.id)
;     : (layers-b.hom (transport-obj a) (transport-obj a))
;
;   given these at layer a1:
;     c : layers-a.obj
;     b : layers-a.obj
;     a : layers-a.obj
;   given these at layer a2:
;     g : (layers-a.hom b c)
;     f : (layers-a.hom a b)
;   postulate an equivalence at layer b2:
;     naturality-compose
;     : (layers-b.compose (transport-hom g) (transport-hom f))
;     = (transport-hom (layers-a.compose g f))
;     : (layers-b.hom (transport-obj a) (transport-obj c))

(struct-easy (functor rep))


; Natural transformation:
;
;   expect layers-a.<etc> according to Category, such that the
;     theories "layer 1" and "layer 2" expected there are expected
;     here as theories "layer a1" and "layer a2" respectively
;
;   expect layers-b.<etc> according to Category, such that the
;     theories "layer 1" and "layer 2" expected there are expected
;     here as theories "layer b1" and "layer b2" respectively
;
;   expect the theories to behave such that:
;     layer a1 can interpret layer b1
;     layer a2 can interpret layer b2
;     both indirect ways of interpreting layer b2 in a1 are the same
;
;   expect functor-a.<etc> according to Functor using layers-a.<etc>
;     and layers-b.<etc>
;
;   expect functor-b.<etc> according to Functor using layers-a.<etc>
;     and layers-b.<etc>
;
;   given these at layer 1a:
;     a : layers-a.obj
;   postulate a value at layer 2b:
;     component
;     : (layers-b.hom
;         (functor-a.transport-obj a)
;         (functor-b.transport-obj a))
;
;   given these at layer 1a:
;     b : layers-a.obj
;     a : layers-a.obj
;   given these at layer 2a:
;     f : (layers-a.hom a b)
;   postulate an equivalence at layer 2b:
;     naturality
;     : (layers-b.compose component (functor-a.transport-hom f))
;     = (layers-b.compose (functor-b.transport-hom f) component)
;     : (hom (functor-a.transport-obj a) (functor-b.transport-obj b))

(struct-easy (natural-transformation rep))


; Terminal object:
;
;   expect <etc> according to Category, including its theories
;
;   postulate a value at layer 1:
;     one : obj
;
;   given these at layer 1:
;     s : obj
;   postulate a value at layer 2:
;     terminal-map : (hom s one)
;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     imitation-terminal-map : (hom s one)
;   postulate an equivalence at layer 2:
;     terminal-map-unique :
;     imitation-terminal-map = terminal-map : (hom s one)

(struct-easy (terminal-object rep))


; Binary product of two objects in particular:
;
;   expect <etc> according to Category, including its theories
;
;   expect a value at layer 1:
;     a : obj
;
;   expect a value at layer 1:
;     b : obj
;
;   postulate a value at layer 1:
;     (product a b) : obj
;
;   postulate a value at layer 2:
;     fst : (hom (product a b) a)
;
;   postulate a value at layer 2:
;     snd : (hom (product a b) b)
;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     sa : (hom s a)
;     sb : (hom s b)
;   postulate a value at layer 2:
;     (pair sa sb) : (hom s (product a b))
;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     sa : (hom s a)
;     sb : (hom s b)
;   postulate an equivalence at layer 2:
;     fst-inverts : sa = (compose fst (pair sa sb)) : (hom s a)
;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     sa : (hom s a)
;     sb : (hom s b)
;   postulate an equivalence at layer 2:
;     snd-inverts : sb = (compose snd (pair sa sb)) : (hom s b)
;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     sa : (hom s a)
;     sb : (hom s b)
;     (imitation-pair sa sb) : (hom s (product a b))
;   given these equivalences at layer 2:
;     imitation-fst-inverts
;     : sa = (compose fst (imitation-pair sa sb)) : (hom s a)
;     imitation-snd-inverts
;     : sb = (compose snd (imitation-pair sa sb)) : (hom s b)
;   postulate an equivalence at layer 2:
;     pair-unique
;     : (imitation-pair sa sb) = (pair sa sb) : (hom s (product a b))

(struct-easy (particular-binary-product rep))


; The quality of having all binary products:
;
;   expect <etc> according to Category, including its theories
;
;   given these at layer 1:
;     a : obj
;     b : obj
;   postulate and/or expect <etc> according to
;     "Binary product of two objects in particular", with each level
;     of givens here prepended to the corresponding level of those
;     constructions' givens, so that the `a` and `b` expected there
;     are the ones given here

(struct-easy (binary-products rep))


; Pullback of a particular cospan:
;
;   expect <etc> according to Category, including its theories
;
;   expect a value at layer 1:
;     t : obj
;
;   expect a value at layer 1:
;     a : obj
;
;   expect a value at layer 1:
;     b : obj
;
;   expect a value at layer 2:
;     at : (hom a t)
;
;   expect a value at layer 2:
;     bt : (hom b t)
;
;   postulate a value at layer 1:
;     (pullback t a b at bt) : obj
;
;   postulate a value at layer 2:
;     fst : (hom (pullback t a b at bt) a)
;
;   postulate a value at layer 2:
;     snd : (hom (pullback t a b at bt) b)
;
;   postulate an equivalence at layer 2:
;     pullback-commutes
;     : (compose at fst) = (compose bt snd)
;     : (hom (pullback t a b at bt) t)
;
;   ; NOTE: If layer 2 itself has enough products and pullbacks, then
;   ; the given layer 2 values and given layer 2 equivalence here can
;   ; be bundled into a single layer 2 pullback of products:
;   ;
;   ;   (layer-2-pullbacks.pullback
;   ;     (hom s t)
;   ;     (layer-2-products.product (hom a t) (hom s a))
;   ;     (layer-2-products.product (hom b t) (hom s b))
;   ;     <a layer-2 morphism witnessing `compose`>
;   ;     <a layer-2 morphism witnessing `compose`>)
;   ;
;   ; However, the way we're writing this signature is much different,
;   ; and an approach which uses layer 2 pullbacks like that is not
;   ; necessarily going to be easy to adapt into the signature we've
;   ; chosen. Our signature is more directly understandable as this
;   ; use of identity types:
;   ;
;   ;   (layer-1-dependent-products.dependent-product s obj
;   ;   #/layer-1-interpret-layer-2
;   ;   #/layer-2-dependent-products.dependent-product
;   ;     layer-2-givens
;   ;     (layer-2-products.product
;   ;       ; sa
;   ;       (hom s a)
;   ;       ; sb
;   ;       (hom s b))
;   ;   #/layer-2-dependent-products.dependent-product
;   ;     layer-2-equivalences-at-layer-2-givens
;   ;     (layer-2-identity-types.eq
;   ;       (compose at
;   ;         ; sa
;   ;         (layer-2-products.fst layer-2-givens))
;   ;       (compose bt
;   ;         ; sb
;   ;         (layer-2-products.snd layer-2-givens)))
;   ;   #/hom s (pullback t a b at bt))
;   ;
;   ; More information on this approach is described below, beginning
;   ; at "Note that the constructions ... ."
;   ;
;   ; The purpose of the whole "given ... postulate" notation we're
;   ; using is so that the questions of how types, functions,
;   ; products, and equalities at each "theory" are represented at run
;   ; time can be documented in one place that defines how that theory
;   ; works. Unfortunately, it seems like if we want to represent a
;   ; category's family of pullbacks in terms of this signature and
;   ; this signature must be interpreted in terms of the category's
;   ; layer 2 theory's pullbacks, the signature must be contorted in a
;   ; way that's hard to predict from our "given ... postulate"
;   ; notation.
;   ;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     sa : (hom s a)
;     sb : (hom s b)
;   given these layer 2 equivalences interpreted at layer 2:
;     commutes : (compose at sa) = (compose bt sb) : (hom s t)
;   postulate a value at layer 2:
;     (pair at bt sa sb) : (hom s (pullback t a b at bt))
;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     sa : (hom s a)
;     sb : (hom s b)
;   postulate an equivalence at layer 2:
;     fst-inverts : sa = (compose fst (pair at bt sa sb)) : (hom s a)
;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     sa : (hom s a)
;     sb : (hom s b)
;   postulate an equivalence at layer 2:
;     snd-inverts : sb = (compose snd (pair at bt sa sb)) : (hom s b)
;
;   given these at layer 1:
;     s : obj
;   given these at layer 2:
;     sa : (hom s a)
;     sb : (hom s b)
;     (imitation-pair at bt sa sb) : (hom s (pullback t a b at bt))
;   given these equivalences at layer 2:
;     commutes : (compose at sa) = (compose bt sb) : (hom s t)
;     imitation-fst-inverts
;     : sa = (compose fst (imitation-pair at bt sa sb)) : (hom s a)
;     imitation-snd-inverts
;     : sb = (compose snd (imitation-pair at bt sa sb)) : (hom s b)
;   postulate an equivalence at layer 2:
;     pair-unique
;     : (imitation-pair at bt sa sb) = (pair at bt sa sb)
;     : (hom s (pullback t a b at bt))

(struct-easy (particular-pullback rep))


; Note that the construction `pair` here and the construction of
; `pullback` in "The quality of having all pullbacks" go against the
; typical grain of our "layer" system of notation: The construction of
; `pullback` makes a layer-1 value that depends on a layer-2 value,
; and the construction of `pair` makes a layer-2 value that depends on
; a layer-2 equivalence. (The layer-2 equivalences can be thought of
; as values of their own layer, like a layer 3.)
;
; Most of our constructions proceed forwards through the layers, where
; we express dependencies on layer 1 values, then on layer 2 values,
; and so on, until we reach a postulation in a layer that's at the
; same layer or an even deeper one. In these cases, we think of the
; layer-1 givens as being the inputs of a layer-1 dependent product
; whose codomain is the layer-1 interpretation of a layer-2 dependent
; product type, whose codomain could be a layer-2 interpretation of a
; layer-3 dependent product type, and so on. (Equivalence layers are a
; case that deserves special attention, since our notation doesn't
; express equivalences the same way as values: The layer-2
; interpretation of a layer-2 equivalence is a layer-2 identity type.)
;
; When we go backwards through layers like this, we signal this
; explicitly in our notation by saying that a certain layer of givens
; is interpreted in another layer. In that case, each of the givens is
; interpreted, and the interpreting layer is used to take the product
; of those givens and the dependent product out of that product type
; into the rest of the signature.
;
; Notice that we have still not introduced a need for dependent sums,
; since none of the givens in one layer depend on another. (In the
; notation of `pair-unique` for products and for pullbacks, it appears
; `(imitation-pair f g)` and `(imitation-pair cb db ac ad)` depend on
; other givens at the same layer, but this is just a verbose name
; we're using for similarity with `(pair f g)` and
; `(pair cb db ac ad)`, not an actual dependency.) All our
; dependencies are expressed with a series of dependent products, and
; so far this is sufficient.


; The quality of having all pullbacks:
;
;   expect <etc> according to Category, including its theories
;
;   given these at layer 1:
;     t : obj
;     a : obj
;     b : obj
;   given these at layer 2:
;     at : (hom a t)
;     bt : (hom b t)
;   postulate and/or expect <etc> according to
;     "Pullback of a particular cospan", with each level of givens
;     here prepended to the corresponding level of those
;     constructions' givens, so that the `t`, `a`, `b`, `at`, and `bt`
;     expected there are the ones given here

(struct-easy (pullbacks rep))


; A particular exponential object:
;
;   expect <etc> according to Category, including its theories
;
;   expect a value at layer 1:
;     x : obj
;
;   expect a value at layer 1:
;     y : obj
;
;   postulate a value at layer 1:
;     (exponential-object x y) : obj
;
;   postulate and/or expect call-domain.<etc> according to
;     "Binary product of two objects in particular", so that the `a`
;     expected there is the `(exponential-object x y)` postulated
;     here, the `b` expected there is the `x` expected here, and the
;     `(product a b)` postulated there is known here as
;     `(call-domain.product (exponential-object x y) x)`
;
;   postulate a value at layer 2:
;     call : (hom (call-domain.product (exponential-object x y) x) y)
;
;   ; NOTE: Unlike the rest of the places we write
;   ; "given imitation-call-domain.<etc> ...," this one has the
;   ; layer 2 equivalences interpreted at layer 2.
;   given these at layer 1:
;     s : obj
;   given imitation-call-domain.<etc> according to the postulations of
;     "Binary product of two objects in particular" at appropriate
;     layers, with the layer 2 equivalences interpreted at layer 2,
;     the `a` expected there being the `s` given here, the `b`
;     expected there being the `x` expected here, and the
;     `(product a b)` postulated there being known here as
;     `(imitation-call-domain.product s x)`:
;   given these at layer 2:
;     imitation-call : (hom (imitation-call-domain.product s x) y)
;   postulate a value at layer 2:
;     (curry imitation-call) : (hom s (exponential-object x y))
;
;   given these at layer 1:
;     s : obj
;   given imitation-call-domain.<etc> according to the postulations of
;     "Binary product of two objects in particular" at appropriate
;     layers, with the `a` expected there being the `s` given here,
;     the `b` expected there being the `x` expected here, and the
;     `(product a b)` postulated there being known here as
;     `(imitation-call-domain.product s x)`:
;   given these at layer 2:
;     imitation-call : (hom (imitation-call-domain.product s x) y)
;   postulate an equivalence at layer 2:
;     call-inverts
;     : imitation-call = (compose call (curry imitation-call))
;     : (hom (imitation-call-domain.product s x) y)
;
;   given these at layer 1:
;     s : obj
;   given imitation-call-domain.<etc> according to the postulations of
;     "Binary product of two objects in particular" at appropriate
;     layers, with the `a` expected there being the `s` given here,
;     the `b` expected there being the `x` expected here, and the
;     `(product a b)` postulated there being known here as
;     `(imitation-call-domain.product s x)`:
;   given these at layer 2:
;     imitation-call : (hom (imitation-call-domain.product s x) y)
;     (imitation-curry imitation-call)
;     : (hom s (exponential-object x y))
;   given these equivalences at layer 2:
;     imitation-call-inverts
;     : imitation-call = (compose call (curry imitation-call))
;     : (hom (imitation-call-domain.product s x) y)
;   postulate an equivalence at layer 2:
;     curry-unique
;     : (imitation-curry imitation-call) = (curry imitation-call)
;     : (hom s (exponential-object x y))

(struct-easy (particular-exponential-object rep))


; The quality of having all exponential objects
; (closed category structure):
;
;   expect <etc> according to Category, including its theories
;
;   given these at layer 1:
;     x : obj
;     y : obj
;   postulate and/or expect <etc> according to
;     "A particular exponential object", with each level of givens
;     here prepended to the corresponding level of those
;     constructions' givens, so that the `x` and `y` expected there
;     are the ones given here

(struct-easy (exponential-objects rep))


; A particular one-sided inverse on morphisms:
;
;   expect <etc> according to Category, including its theories
;
;   expect this at layer 1:
;     here : obj
;
;   expect this at layer 1:
;     layover : obj
;
;   expect this at layer 2:
;     embark : (hom here layover)
;
;   expect this at layer 2:
;     return : (hom layover here)
;
;   postulate an equivalence at layer 2:
;     inverts : id = (compose return embark) : (hom here here)

(struct-easy (particular-morphism-one-sided-inverse rep))


; A particular isomorphism:
;
;   expect <etc> according to Category, including its theories
;
;   expect this at layer 1:
;     a : obj
;
;   expect this at layer 1:
;     b : obj
;
;   expect this at layer 2:
;     ab : (hom a b)
;
;   expect this at layer 2:
;     ba : (hom b a)
;
;   postulate and/or expect aba.<etc> according to
;     "A particular one-sided inverse on morphisms", where the
;     `here`, `layover`, `embark`, and `return`, expected there are
;     the `a`, `b`, `ab`, and `ba` expected here, respectively
;
;   postulate and/or expect bab.<etc> according to
;     "A particular one-sided inverse on morphisms", where the
;     `here`, `layover`, `embark`, and `return`, expected there are
;     the `b`, `a`, `ba`, and `ab` expected here, respectively

(struct-easy (particular-isomorphism rep))


; The quality of having all inverse morphisms (groupoid structure):
;
;   expect <etc> according to Category, including its theories
;
;   given these at layer 1:
;     a : obj
;     b : obj
;   given these at layer 2:
;     ab : (hom a b)
;   postulate this at layer 2:
;     (invert ab) : (hom b a)
;
;   given these at layer 1:
;     a : obj
;     b : obj
;   given these at layer 2:
;     ab : (hom a b)
;   postulate and/or expect <etc> according to
;     "A particular isomorphism", with each level of givens here
;     prepended to the corresponding level of those constructions'
;     givens, so that the `a`, `b`, and `ab` expected there are the
;     ones given here, and so that the `ba` expected there is the
;     `(invert a b)` postulated here

; This will be particularly good for representing equivalence
; relations so that we can have some "theories" where the run time
; witnesses of equivalence are nontrivial. Operations that need to
; manipulate equivalences can use a groupoid, and the equivalences
; *of that groupoid* may or may not be erased at run time.
;
; TODO: Follow through on representing equivalence relations to
; manipulate run time equivalence witnesses that way.

(struct-easy (morphism-inverses rep))


; Natural isomorphism:
;
;   expect layers-a.<etc> according to Category, such that the
;     theories "layer 1" and "layer 2" expected there are expected
;     here as theories "layer a1" and "layer a2" respectively
;
;   expect layers-b.<etc> according to Category, such that the
;     theories "layer 1" and "layer 2" expected there are expected
;     here as theories "layer b1" and "layer b2" respectively
;
;   expect the theories to behave such that:
;     layer a1 can interpret layer b1 and vice versa
;     layer a2 can interpret layer b2 and vice versa
;     all indirect ways of interpreting one layer in another are the
;       same
;
;   expect functor-a.<etc> according to Functor using layers-a.<etc>
;     and layers-b.<etc>
;
;   expect functor-b.<etc> according to Functor using layers-a.<etc>
;     and layers-b.<etc>
;
;   expect ab.<etc> according to "Natural transformation" using
;     layers-a.<etc>, layers-b.<etc>, functor-a.<etc>, and
;     functor-b.<etc>
;
;   expect ba.<etc> according to "Natural transformation" using
;     layers-a.<etc> and layers-b.<etc>, and using functor-a.<etc> as
;     functor-b.<etc> and vice versa
;
;   given these at layer 1a:
;     a : layers-a.obj
;   postulate and/or expect <etc> according to
;     "A particular isomorphism", with each level of givens here
;     prepended to the corresponding level of those constructions'
;     givens, such that the theories "layer 1" and "layer 2" expected
;     there are the ones expected here as "layer b1" and "layer b2"
;     respectively and the `a`, `b`, `ab`, and `ba` expected there are
;     the `(functor-a.transport-obj a)`,
;     `(functor-b.transport-obj a)`, `ab.component`, and
;     `ba.component` given/postulated here

(struct-easy (natural-isomorphism rep))


; [Metatheoretical construction] Product category:
;
; Given two categories `a.<etc>` and `b.<etc>` with the same layer 1
; and layer 2 theories, their product, designated
; `(product-category a.<etc> b.<etc>)`, is a category where the set
; `obj` is the set of ordered pairs designated
; `(product-category-obj-pair a b)` with `a` in `a.obj` and `b`
; in `b.obj`, and each set
;
;    (hom
;      (product-category-obj-pair xa xb)
;      (product-category-obj-pair ya yb))
;
; has elements designated `(product-category-hom-pair fa fb)` with
; `fa` in `(a.hom xa ya)` and `fb` in `(b.hom xb yb)`.


; [Metatheoretical construction] Terminal category:
;
; The terminal category, designated `(terminal-category)`, is a
; category where the set `obj` is the set of a single element
; designated `(terminal-category-obj-terminal-map)`, and the set
;
;    (hom
;      (terminal-category-obj-terminal-map)
;      (terminal-category-obj-terminal-map))
;
; has a single element (already designated `id`).


; (TODO: See if there's a better name for this one.)
;
; [Metatheoretical construction] Bimap functor:
;
; Given two functors `a.<etc>` and `b.<etc>` with the same layer a1,
; layer a2, layer b1, and layer b2 theories,
; `(bimap-functor a.<etc> b.<etc>)` is a functor from
; `(product-category a.layers-a.<etc> b.layers-a.<etc>)` to
; `(product-category a.layers-b.<etc> b.layers-b.<etc>)` with a
; straightforward implementation.


; (TODO: See if there's a better name for this one.)
;
; [Metatheoretical construction] Generalized element functor:
;
; For any category `<etc>`, given some object `a`,
; `(generalized-element-functor a)` is a functor from
; `(terminal-category)` to `<etc>` that transforms
; `(terminal-category-obj-terminal-map)` into `a`.


; (TODO: See if there's a better name for this one.)
;
; [Metatheoretical construction] Left unit introduction functor:
;
; For any category `<etc>`, `(left-unit-intro-functor)` is a functor
; from `<etc>` to `(product-category (terminal-category) <etc>)` with
; a straightforward implementation.


; (TODO: See if there's a better name for this one.)
;
; [Metatheoretical construction] Right unit introduction functor:
;
; For any category `<etc>`, `(right-unit-intro-functor)` is a functor
; from `<etc>` to `(product-category <etc> (terminal-category))` with
; a straightforward implementation.


; (TODO: See if there's a better name for this one.)
;
; [Metatheoretical construction] Left associator functor:
;
; For any three categories `a.<etc>`, `b.<etc>`, and `c.<etc>`,
; `(left-associator-functor)` is a functor from
; `(product-category a.<etc> (product-category b.<etc> c.<etc>))` to
; `(product-category (product-category a.<etc> b.<etc>) c.<etc>)` with
; a straightforward implementation.


; [Metatheoretical construction] Identity functor:
;
; For any category `<etc>`, the identity functor `(identity-functor)`
; is a functor from `<etc>` to `<etc>` that has no effect.


; [Metatheoretical construction] Composition of functors:
;
; For any three categories `a.<etc>`, `b.<etc>`, and `c.<etc>` and any
; functors `ab.<etc>` from `a.<etc>` to `b.<etc>` and `bc.<etc>` from
; `b.<etc>` to `c.<etc>`, those functors' composition
; `(composed-functor bc.<etc> ab.<etc>)` is a functor from `a.<etc>`
; to `c.<etc>` with a straightforward implementation.


; Monoidal structure on a category's objects
; (monoidal category structure):
;
;   expect <etc> according to Category, including its theories
;
;   postulate a value at layer 1:
;     empty : obj
;
;   postulate and/or expect append-functor.<etc> according to Functor,
;     where the `layers-a.<etc>` and `laters-b.<etc>` expected there
;     are the `(product-category <etc> <etc>)` and `<etc>`
;     expected/computed here
;
;   let `(append a b)` be shorthand for
;     `(append-functor.transform-obj #/product-category-obj-pair a b)`
;
;   postulate and/or expect left-unitor.<etc> according to
;     "Natural isomorphism", where certain things expected there
;     correspond to things expected/computed here, like so:
;
;       layers-a.<etc> --> <etc>
;       layers-b.<etc> --> <etc>
;
;       functor-a.<etc>
;       -->
;       (composed-functor append-functor.<etc>
;       #/composed-functor
;         (bimap-functor
;           (global-element-functor empty)
;           (identity-functor))
;         (left-unit-intro-functor))
;
;       functor-b.<etc> --> (identity-functor)
;
;   postulate and/or expect right-unitor.<etc> according to
;     "Natural isomorphism", where certain things expected there
;     correspond to things expected/computed here, like so:
;
;       layers-a.<etc> --> <etc>
;       layers-b.<etc> --> <etc>
;       functor-a.<etc> --> (identity-functor)
;
;       functor-a.<etc>
;       -->
;       (composed-functor append-functor.<etc>
;       #/composed-functor
;         (bimap-functor
;           (identity-functor)
;           (global-element-functor empty))
;         (right-unit-intro-functor))
;
;       functor-b.<etc> --> (identity-functor)
;
;   postulate and/or expect associator.<etc> according to
;     "Natural isomorphism", where certain things expected there
;     correspond to things expected/computed here, like so:
;
;       layers-a.<etc>
;       -->
;       (product-category <etc> #/product-category <etc> <etc>)
;
;       layers-b.<etc> --> <etc>
;
;       functor-a.<etc>
;       -->
;       (composed-functor append-functor.<etc>
;       #/composed-functor
;         (bimap-functor append-functor.<etc> identity)
;         (left-associator-functor))
;
;       functor-b.<etc>
;       -->
;       (composed-functor append-functor.<etc>
;       #/bimap-functor identity append-functor.<etc>)
;
;   given these at layer 1:
;     x : obj
;     y : obj
;   postulate an equivalence over layer 2:
;     triangle
;     :
;     (compose
;       (append-functor.transform-hom
;       #/product-category-hom-pair id left-unitor.ab.component)
;       associator.ab.component)
;     =
;     (append-functor.transform-hom
;     #/product-category-hom-pair right-unitor.ab.component id)
;     : (hom (append (append x empty) y) (append x y))
;
;   given these at layer 1:
;     w : obj
;     x : obj
;     y : obj
;     z : obj
;   postulate an equivalence over layer 2:
;     pentagon
;     :
;     (compose associator.ab.component associator.ab.component)
;     =
;     (compose
;       (append-functor.transform-hom
;       #/product-category-hom-pair id associator.ab.component)
;     #/compose
;       associator.ab.component
;       (append-functor.transform-hom
;       #/product-category-hom-pair associator.ab.component id))
;     :
;     (hom
;       (append (append (append w x) y) z)
;       (append w (append x (append y z))))

(struct-easy (category-monoidal-structure rep))


; Tensorial strength (the strong functor condition):
;
;   expect <etc> according to "Monoidal structure on a category's
;     objects (monoidal category structure)", including its theories
;
;   expect f.<etc> according to Functor, where the `layers-a.<etc>`
;     and `laters-b.<etc>` expected there are the `<etc>` and `<etc>`
;     expected here
;
;   postulate and/or expect nt.<etc> according to
;     "Natural transformation", where certain things expected there
;     correspond to things expected/computed here, like so:
;
;       layers-a.<etc> --> (product-category <etc> <etc>)
;       layers-b.<etc> --> <etc>
;
;       functor-a.<etc>
;       -->
;       (composed-functor append-functor.<etc>
;       #/bimap-functor (identity-functor) f.<etc>)
;
;       functor-b.<etc>
;       -->
;       (composed-functor f.<etc> append-functor.<etc>)
;
;   given these at layer 1:
;     a : obj
;   postulate an equivalence over layer 2:
;     monoidal-strength-unitor
;     :
;     (compose
;       (f.transform-hom left-unitor.ab.component)
;       nt.component)
;     =
;     left-unitor.ab.component
;     : (hom (append empty #/f.transform-obj a) (f.transform-obj a))
;
;   given these at layer 1:
;     a : obj
;     b : obj
;     c : obj
;   postulate an equivalence over layer 2:
;     monoidal-strength-associator
;     :
;     (compose (f.transform-hom associator.ab.component) nt.component)
;     =
;     (compose
;       nt.component
;     #/compose
;       (bimap-functor (identity-functor) nt.component)
;       associator.ab.component)
;     :
;     (hom
;       (append (append a b) #/f.transform-obj c)
;       (f.transform-obj #/append a #/append b c))

(struct-easy (tensorial-strength rep))


; Bicategory:
;
;   ; NOTE: There's a lot of similarity between this and
;   ; "Monoidal structure on a category's objects
;   ; (monoidal category structure)". In fact, if we've formulated
;   ; these signatures correctly, that one should be a special case of
;   ; this one where `obj` has a single inhabitant.
;
;   expect theories "layer 1", "layer 2", and "layer 3" such that:
;     layer 1 can interpret layer 2
;     layer 2 can interpret layer 3
;     layer 3 has a notion of equivalence
;
;   expect a type at layer 1:
;     obj
;
;   given these at layer 1:
;     b : obj
;     a : obj
;   expect (hom-category.<etc> a b ...) according to Category, with
;     each level of givens here prepended to the corresponding level
;     of those constructions' givens, such that the theories "layer 1"
;     and "layer 2" expected there are expected here as theories
;     "layer 2" and "layer 3" respectively
;
;   given these at layer 1:
;     b : obj
;     a : obj
;   postulate a value at layer 1:
;     id : (hom-category.obj a b)
;
;   given these at layer 1:
;     c : obj
;     b : obj
;     a : obj
;   postulate and/or expect compose-functor.<etc> according to
;     Functor, with each level of givens here prepended to the
;     corresponding level of those constructions' givens, where
;     certain things expected there correspond to things
;     expected/computed here, like so:
;
;       "layer 1" --> "layer 2"
;       "layer 2" --> "layer 3"
;
;       layers-a.<etc>
;       -->
;       (product-category
;         (hom-category.<etc> b c ...)
;         (hom-category.<etc> a b ...))
;
;       layers-b.<etc> --> (hom-category.<etc> a c ...)
;
;   let `(compose a b)` be shorthand for
;     `(compose-functor.transform-obj #/product-category-obj-pair
;        a b)`
;
;   given these at layer 1:
;     b : obj
;     a : obj
;   postulate and/or expect left-unitor.<etc> according to
;     "Natural isomorphism", with each level of givens here prepended
;     to the corresponding level of those constructions' givens, where
;     certain things expected there correspond to things
;     expected/computed here, like so:
;
;       "layer 1" --> "layer 2"
;       "layer 2" --> "layer 3"
;
;       layers-a.<etc> --> (hom-category.<etc> a b ...)
;       layers-b.<etc> --> (hom-category.<etc> a b ...)
;
;       functor-a.<etc>
;       -->
;       (composed-functor compose-functor.<etc>
;       #/composed-functor
;         (bimap-functor
;           (global-element-functor id)
;           (identity-functor))
;         (left-unit-intro-functor))
;
;       functor-b.<etc> --> (identity-functor)
;
;   given these at layer 1:
;     b : obj
;     a : obj
;   postulate and/or expect right-unitor.<etc> according to
;     "Natural isomorphism", with each level of givens here prepended
;     to the corresponding level of those constructions' givens, where
;     certain things expected there correspond to things
;     expected/computed here, like so:
;
;       "layer 1" --> "layer 2"
;       "layer 2" --> "layer 3"
;
;       layers-a.<etc> --> (hom-category.<etc> b c ...)
;       layers-b.<etc> --> (hom-category.<etc> b c ...)
;       functor-a.<etc> --> (identity-functor)
;
;       functor-a.<etc>
;       -->
;       (composed-functor compose-functor.<etc>
;       #/composed-functor
;         (bimap-functor
;           (identity-functor)
;           (global-element-functor id))
;         (right-unit-intro-functor))
;
;       functor-b.<etc> --> (identity-functor)
;
;   given these at layer 1:
;     d : obj
;     c : obj
;     b : obj
;     a : obj
;   postulate and/or expect associator.<etc> according to
;     "Natural isomorphism", with each level of givens here prepended
;     to the corresponding level of those constructions' givens, where
;     certain things expected there correspond to things
;     expected/computed here, like so:
;
;       "layer 1" --> "layer 2"
;       "layer 2" --> "layer 3"
;
;       layers-a.<etc>
;       -->
;       (product-category (hom-category.<etc> c d ...)
;       #/product-category (hom-category.<etc> b c ...)
;         (hom-category.<etc> a b))
;
;       layers-b.<etc> --> (hom-category.<etc> a d ...)
;
;       functor-a.<etc>
;       -->
;       (composed-functor compose-functor.<etc>
;       #/composed-functor
;         (bimap-functor compose-functor.<etc> identity)
;         (left-associator-functor))
;
;       functor-b.<etc>
;       -->
;       (composed-functor compose-functor.<etc>
;       #/bimap-functor identity compose-functor.<etc>)
;
;   given these at layer 1:
;     c : obj
;     b : obj
;     a : obj
;   given these at layer 2:
;     bc : (hom-category.obj b c)
;     ab : (hom-category.obj a b)
;   postulate an equivalence over layer 3:
;     triangle
;     :
;     (hom-category.compose a c
;       (compose-functor.transform-hom #/product-category-hom-pair
;         (hom-category.id b c)
;         left-unitor.ab.component)
;       associator.ab.component)
;     =
;     (compose-functor.transform-hom #/product-category-hom-pair
;       right-unitor.ab.component
;       (hom-category.id a b))
;     :
;     (hom-category.hom a c
;       (compose (compose bc id) ab)
;       (compose bc ab))
;
;   given these at layer 1:
;     e : obj
;     d : obj
;     c : obj
;     b : obj
;     a : obj
;   given these at layer 2:
;     de : (hom-category.obj d e)
;     cd : (hom-category.obj c d)
;     bc : (hom-category.obj b c)
;     ab : (hom-category.obj a b)
;   postulate an equivalence over layer 3:
;     pentagon
;     :
;     (hom-category.compose a e
;       associator.ab.component
;       associator.ab.component)
;     =
;     (hom-category.compose a e
;       (compose-functor.transform-hom #/product-category-hom-pair
;         (hom-category.id d e)
;         associator.ab.component)
;     #/hom-category.compose a e
;       associator.ab.component
;       (compose-functor.transform-hom #/product-category-hom-pair
;         associator.ab.component
;         (hom-category.id a b)))
;     :
;     (hom-cagegory.hom a e
;       (compose (compose (compose de cd) bc) ab)
;       (compose de (compose cd (compose bc ab))))

(struct-easy (bicategory rep))


; Monad:
;
;   expect <etc> according to Bicategory, including its theories
;
;   postulate a value at layer 1:
;     a : obj
;
;   postulate a value at layer 2:
;     m : (hom-category.obj a a)
;
;   postulate a value at layer 3:
;     empty : (hom-category.hom a a id m)
;
;   postulate a value at layer 3:
;     append : (hom-category.hom a a (compose m m) m)
;
;   postulate an equivalence over layer 3:
;     monad-left-unitor
;     :
;     (hom-category.compose a a
;       append
;     #/hom-category.compose a a
;       (compose-functor.transform-hom #/product-category-hom-pair
;         empty
;         (hom-category.id a a))
;       left-unitor.ba.component)
;     =
;     (hom-category.id a a)
;     : (hom-category.hom a a m m)
;
;   postulate an equivalence over layer 3:
;     monad-right-unitor
;     :
;     (hom-category.compose a a
;       append
;     #/hom-category.compose a a
;       (compose-functor.transform-hom #/product-category-hom-pair
;         (hom-category.id a a)
;         empty)
;       right-unitor.ba.component)
;     =
;     (hom-category.id a a)
;     : (hom-category.hom a a m m)
;
;   postulate an equivalence over layer 3:
;     monad-associator
;     :
;     (hom-category.compose a a
;       append
;     #/hom-category.compose a a
;       (compose-functor.transform-hom #/product-category-hom-pair
;         append
;         (hom-category.id a a))
;       associator.ba.component)
;     =
;     (hom-category.compose a a
;       append
;       (compose-functor.transform-hom #/product-category-hom-pair
;         (hom-category.id a a)
;         append))
;     : (hom-category.hom a a (compose m #/compose m m) m)

(struct-easy (monad rep))


; TODO: Write signatures for these:
;
;   - Monoidal ("applicative") functors.
;     - Sometimes when people refer to these, they call them "lax,"
;       and sometimes they don't. I think that's because the monoidal
;       structure of a category is already enforced only up to some
;       natural isomorphisms, so functors that respect this kind of
;       structure are already rather lax. See if we should call them
;       "lax" oourselves. Either way, let's try to document the
;       reasons for our choice.
;   - A particular dependent product.
;   - All dependent products.
;     - These will probably come in handy for making custom
;       "theories."
;   - A particular finite limit.
;   - All finite limits.
;   - A particular W-type.
;   - All W-types.
;   - Duals of the others mentioned:
;     - An initial object.
;     - A particular binary sum.
;     - All binary sums.
;     - A particular pushout.
;     - All pushouts.
;     - A particular dependent sum.
;     - All dependent sums.
;       - These will probably come in handy for making custom
;         "theories."
;     - A particular finite colimit.
;     - All finite colimits.
;     - A particular M-type.
;     - All M-types.
;   - Star-autonomous category structure.
;
; Also figure out how strict 2-categories, various kinds of higher
; categories, monomorphisms, anafunctors, toposes, and
; Grothendieck toposes would fit into this approach. (Note that we
; already have bicategories, so strict 2-categories might be a short
; hop from those.)
