#lang parendown racket/base

; lathe-morphisms/lawless/category
;
; Interfaces for categories where none of the laws have to hold, but
; where we still go to some lengths to ensure we can write informative
; contracts.

;   Copyright 2019 The Lathe Authors
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


(require #/only-in racket/contract/base recontract-out)

(require #/only-in lathe-morphisms/private/lawless/lawless
  
  category-sys?
  category-sys-impl?
  category-sys-object-set-sys
  category-sys-object/c
  category-sys-object-identity-morphism
  category-sys-morphism-set-sys
  category-sys-morphism/c
  category-sys-morphism-replace-source
  category-sys-morphism-replace-target
  category-sys-morphism-chain-two
  prop:category-sys
  make-category-sys-impl-from-chain-two
  
  functor-sys?
  functor-sys-impl?
  functor-sys-source
  functor-sys-replace-source
  functor-sys-target
  functor-sys-replace-target
  functor-sys-apply-to-object
  functor-sys-apply-to-morphism
  prop:functor-sys
  make-functor-sys-impl-from-apply
  functor-sys/c
  makeshift-functor-sys
  functor-sys-identity
  functor-sys-chain-two
  
  natural-transformation-sys?
  natural-transformation-sys-impl?
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
  prop:natural-transformation-sys
  make-natural-transformation-sys-impl-from-apply
  natural-transformation-sys/c
  makeshift-natural-transformation-sys
  natural-transformation-sys-identity
  natural-transformation-sys-chain-two
  natural-transformation-sys-chain-two-along-end)

(provide #/recontract-out
  
  category-sys?
  category-sys-impl?
  category-sys-object-set-sys
  category-sys-object/c
  category-sys-object-identity-morphism
  category-sys-morphism-set-sys
  category-sys-morphism/c
  category-sys-morphism-replace-source
  category-sys-morphism-replace-target
  category-sys-morphism-chain-two
  prop:category-sys
  make-category-sys-impl-from-chain-two
  
  functor-sys?
  functor-sys-impl?
  functor-sys-source
  functor-sys-replace-source
  functor-sys-target
  functor-sys-replace-target
  functor-sys-apply-to-object
  functor-sys-apply-to-morphism
  prop:functor-sys
  make-functor-sys-impl-from-apply
  functor-sys/c
  makeshift-functor-sys
  functor-sys-identity
  functor-sys-chain-two
  
  natural-transformation-sys?
  natural-transformation-sys-impl?
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
  prop:natural-transformation-sys
  make-natural-transformation-sys-impl-from-apply
  natural-transformation-sys/c
  makeshift-natural-transformation-sys
  natural-transformation-sys-identity
  natural-transformation-sys-chain-two
  natural-transformation-sys-chain-two-along-end)
