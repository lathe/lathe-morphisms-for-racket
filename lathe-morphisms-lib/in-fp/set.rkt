#lang parendown racket/base

; lathe-morphisms/in-fp/set
;
; Interfaces for sets where none of the laws (of equality between
; elements) are represented computationally, but where we still go to
; some lengths to ensure we can write informative contracts.

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
  set-sys?
  set-sys-impl?
  prop:set-sys
  set-sys-element/c
  set-sys-element-accepts/c
  make-set-sys-impl-from-contract
  makeshift-set-sys-from-contract)


(provide #/shim-recontract-out
  set-sys?
  set-sys-impl?
  prop:set-sys
  set-sys-element/c
  set-sys-element-accepts/c
  make-set-sys-impl-from-contract
  makeshift-set-sys-from-contract)
