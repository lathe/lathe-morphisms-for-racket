#lang parendown racket/base

; lathe-morphisms/in-fp/category
;
; Interfaces for categories where none of the laws are represented
; computationally, but where we still go to some lengths to ensure we
; can write informative contracts.

;   Copyright 2019-2021 The Lathe Authors
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


(require lathe-morphisms/private/shim)

(require #/only-in lathe-morphisms/private/in-fp/in-fp
  
  category-sys?
  category-sys-impl?
  prop:category-sys
  category-sys-object-set-sys
  category-sys-object/c
  category-sys-morphism-set-sys
  category-sys-morphism/c
  category-sys-object-identity-morphism
  category-sys-morphism-chain-two
  make-category-sys-impl-from-chain-two
  
  functor-sys?
  functor-sys-impl?
  prop:functor-sys
  functor-sys-source
  functor-sys-replace-source
  functor-sys-target
  functor-sys-replace-target
  functor-sys-apply-to-object
  functor-sys-apply-to-morphism
  make-functor-sys-impl-from-apply
  functor-sys/c
  makeshift-functor-sys
  functor-sys-identity
  functor-sys-chain-two
  
  natural-transformation-sys?
  natural-transformation-sys-impl?
  prop:natural-transformation-sys
  natural-transformation-sys-endpoint-source
  natural-transformation-sys-replace-endpoint-source
  natural-transformation-sys-endpoint-target
  natural-transformation-sys-replace-endpoint-target
  natural-transformation-sys-endpoint/c
  natural-transformation-sys-source
  natural-transformation-sys-replace-source
  natural-transformation-sys-target
  natural-transformation-sys-replace-target
  natural-transformation-sys-apply-to-morphism
  make-natural-transformation-sys-impl-from-apply
  natural-transformation-sys/c
  makeshift-natural-transformation-sys
  natural-transformation-sys-identity
  natural-transformation-sys-chain-two
  natural-transformation-sys-chain-two-along-end)


(provide #/shim-recontract-out
  
  category-sys?
  category-sys-impl?
  prop:category-sys
  category-sys-object-set-sys
  category-sys-object/c
  category-sys-morphism-set-sys
  category-sys-morphism/c
  category-sys-object-identity-morphism
  category-sys-morphism-chain-two
  make-category-sys-impl-from-chain-two
  
  functor-sys?
  functor-sys-impl?
  prop:functor-sys
  functor-sys-source
  functor-sys-replace-source
  functor-sys-target
  functor-sys-replace-target
  functor-sys-apply-to-object
  functor-sys-apply-to-morphism
  make-functor-sys-impl-from-apply
  functor-sys/c
  makeshift-functor-sys
  functor-sys-identity
  functor-sys-chain-two
  
  natural-transformation-sys?
  natural-transformation-sys-impl?
  prop:natural-transformation-sys
  natural-transformation-sys-endpoint-source
  natural-transformation-sys-replace-endpoint-source
  natural-transformation-sys-endpoint-target
  natural-transformation-sys-replace-endpoint-target
  natural-transformation-sys-endpoint/c
  natural-transformation-sys-source
  natural-transformation-sys-replace-source
  natural-transformation-sys-target
  natural-transformation-sys-replace-target
  natural-transformation-sys-apply-to-morphism
  make-natural-transformation-sys-impl-from-apply
  natural-transformation-sys/c
  makeshift-natural-transformation-sys
  natural-transformation-sys-identity
  natural-transformation-sys-chain-two
  natural-transformation-sys-chain-two-along-end)
