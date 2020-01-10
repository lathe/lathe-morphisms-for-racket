#lang parendown racket/base

; lathe-morphisms/in-fp/mediary/set
;
; Interfaces for "mediary" sets where not all of the elements have to
; be well-behaved, and where none of the laws (of equality between
; elements) are represented computationally, but where we still go to
; some lengths to ensure we can write informative contracts.

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

(require #/only-in lathe-morphisms/private/in-fp/in-fp
  
  set-element-good-behavior
  set-element-good-behavior?
  set-element-good-behavior-getter-of-value
  set-element-good-behavior-value
  set-element-good-behavior-getter-of-accepts/c
  set-element-good-behavior-with-value/c
  set-element-good-behavior-for-mediary-set-sys/c
  
  atomic-set-element-sys?
  atomic-set-element-sys-impl?
  prop:atomic-set-element-sys
  atomic-set-element-sys-good-behavior
  atomic-set-element-sys-accepts/c
  make-atomic-set-element-sys-impl-from-good-behavior
  make-atomic-set-element-sys-impl-from-contract
  
  mediary-set-sys?
  mediary-set-sys-impl?
  prop:mediary-set-sys
  mediary-set-sys-element/c
  make-mediary-set-sys-impl-from-contract
  
  ok/c)


(provide
  set-element-good-behavior)
(provide #/recontract-out
  set-element-good-behavior?
  set-element-good-behavior-getter-of-value
  set-element-good-behavior-value
  set-element-good-behavior-getter-of-accepts/c
  set-element-good-behavior-with-value/c
  set-element-good-behavior-for-mediary-set-sys/c)

(provide #/recontract-out
  atomic-set-element-sys?
  atomic-set-element-sys-impl?
  prop:atomic-set-element-sys
  atomic-set-element-sys-good-behavior
  atomic-set-element-sys-accepts/c
  make-atomic-set-element-sys-impl-from-good-behavior
  make-atomic-set-element-sys-impl-from-contract)

(provide #/recontract-out
  mediary-set-sys?
  mediary-set-sys-impl?
  prop:mediary-set-sys
  mediary-set-sys-element/c
  make-mediary-set-sys-impl-from-contract)

(provide #/recontract-out
  ok/c)
