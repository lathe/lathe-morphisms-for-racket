#lang parendown racket/base

; lathe-morphisms/lawless/mediary/set
;
; Interfaces for "mediary" sets where not all of the elements have to
; be well-behaved, and where none of the laws (of equality between
; elements) have to hold, but where we still go to some lengths to
; ensure we can write informative contracts.

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
  
  atomic-set-element-sys?
  atomic-set-element-sys-impl?
  atomic-set-element-sys-accepts/c
  atomic-set-element-sys-replace-set-sys
  prop:atomic-set-element-sys
  make-atomic-set-element-sys-impl-from-accepts-and-replace
  
  mediary-set-sys?
  mediary-set-sys-impl?
  mediary-set-sys-element/c
  prop:mediary-set-sys
  make-mediary-set-sys-impl-from-contract
  
  accepts/c)

(provide #/recontract-out
  
  atomic-set-element-sys?
  atomic-set-element-sys-impl?
  atomic-set-element-sys-accepts/c
  atomic-set-element-sys-replace-set-sys
  prop:atomic-set-element-sys
  make-atomic-set-element-sys-impl-from-accepts-and-replace
  
  mediary-set-sys?
  mediary-set-sys-impl?
  mediary-set-sys-element/c
  prop:mediary-set-sys
  make-mediary-set-sys-impl-from-contract
  
  accepts/c)
