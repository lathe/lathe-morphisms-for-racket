#lang parendown racket/base

; lathe-morphisms/private
;
; Implementation details.

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


(provide #/all-defined-out)



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
;   postulate a type at layer 1:
;     obj
;
;   given these at layer 1:
;     b : obj
;     a : obj
;   postulate a type at layer 2:
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
;       : (compose (compose h g) f) = (compose h (compose g f))
;       : (hom a d)
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


; Binary product of two objects in particular:
;
;   expect <etc> according to Category, including its theories
;
;   postulate a value at layer 1:
;     a : obj
;
;   postulate a value at layer 1:
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


; The quality of having all binary products:
;
;   expect <etc> according to Category, including its theories
;
;   given these at layer 1:
;     a : obj
;     b : obj
;   postulate a value at layer 1:
;     (product a b) : obj
;
;   given these at layer 1:
;     a : obj
;     b : obj
;   expect <etc> according to "Binary product of two objects in
;     particular", with each level of givens here prepended to the
;     corresponding level of those constructions' givens, so that the
;     `a`, `b`, and `(product a b)` postulated there are instead
;     expectations of the ones given or postulated here


; Pullback of a particular cospan:
;
;   expect <etc> according to Category, including its theories
;
;   postulate a value at layer 1:
;     t : obj
;
;   postulate a value at layer 1:
;     a : obj
;
;   postulate a value at layer 1:
;     b : obj
;
;   postulate a value at layer 2:
;     at : (hom a t)
;
;   postulate a value at layer 2:
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
;   given these layer 2 values interpreted at layer 1:
;     at : (hom a t)
;     bt : (hom b t)
;   postulate a value at layer 1:
;     (pullback t a b at bt) : obj
;
;   given these at layer 1:
;     t : obj
;     a : obj
;     b : obj
;   given these at layer 2:
;     at : (hom a t)
;     bt : (hom b t)
;   expect <etc> according to "Pullback of a particular cospan", with
;     each level of givens here prepended to the corresponding level
;     of those constructions' givens, so that the `t`, `a`, `b`, `at`,
;     `bt`, and `(pullback t a b at bt)` postulated there are instead
;     expectations of the ones given or postulated here
