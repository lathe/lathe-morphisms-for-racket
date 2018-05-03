#lang parendown racket/base

; lathe-morphisms/private/ordinals/below-epsilon-zero/olist
;
; A list-like data structure where the length and indexes can be any
; ordinal number less than epsilon zero.

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


(require #/only-in racket/contract/base -> ->* any/c list/c listof)
(require #/only-in racket/contract/region define/contract)
(require #/only-in racket/generic define/generic define-generics)

(require #/only-in lathe-comforts dissect expect fn mat w-)
(require #/only-in lathe-comforts/maybe just maybe/c nothing)
(require #/only-in lathe-comforts/list list-foldr)
(require #/only-in lathe-comforts/struct struct-easy)

(require #/only-in
  lathe-morphisms/private/ordinals/below-epsilon-zero/onum
  onum? onum<? onum-compare onum-drop onum-one onum-plus onum-zero)

; TODO: Document all of these exports.
(provide
  (rename-out [-olist? olist?])
  ; TODO: Consider providing `list->olist` and `olist->maybe-list`
  ; operations.
  olist-zero olist-build olist-length
  olist-plus-list olist-plus
  olist-drop1
  olist-drop
  
  ; TODO: See if we can define operations analogous to these. For
  ; instance, `(olist-untimes amount-onum olst)` could return
  ; `(list factor-olist term-olist)`, where `factor-olist` is an
  ; ordinal-indexed list where each `olist-drop1` operation actually
  ; drops a list of `amount-onum` elements from `olst`, and where
  ; `term-olist` is the remainder of the elements of `olst` that are
  ; never reached by `factor-olist`.
;  onum-times-list onum-times
;  onum-untimes
;  onum-pow-list onum-pow
  
  ; TODO: If we ever implement an `onum-log`, consider its analogous
  ; `olist-log` as well.
)


(define-generics olist-rep
  (olist-rep-length olist-rep)
  (olist-rep-drop1 olist-rep)
  (olist-rep-drop amount olist-rep))

(struct-easy (olist rep)
  (#:guard-easy
    (unless (olist-rep? rep)
      (error "Expected rep to be an olist-rep"))))

; NOTE: This is just like `olist?` except for its interaction with
; `struct-predicate-procedure?`.
(define/contract (-olist? x)
  (-> any/c boolean?)
  (olist? x))

(define/contract (olist-length lst)
  (-> olist? onum?)
  (dissect lst (olist rep)
  #/olist-rep-length rep))

(define/contract (olist-drop1 lst)
  (-> olist? #/maybe/c #/list/c any/c olist?)
  (dissect lst (olist rep)
  #/olist-rep-drop1 rep))

(define/contract (olist-drop amount lst)
  (-> onum? olist? #/maybe/c #/list/c olist? olist?)
  (dissect lst (olist rep)
  #/olist-rep-drop amount rep))


(struct-easy (olist-rep-zero)
  #:other
  #:methods gen:olist-rep
  [
    (define (olist-rep-length this)
      (expect this (olist-rep-zero)
        (error "Expected this to be an olist-rep-zero")
        onum-zero))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-zero)
        (error "Expected this to be an olist-rep-zero")
      #/nothing))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-zero)
        (error "Expected this to be an olist-rep-zero")
      #/if (equal? onum-zero amount)
        (just #/list (olist this) (olist this))
        (nothing)))
  ])

; NOTE: We make this a procedure so that clients don't start to depend
; on `(equal? olist-zero x)`. No two values returned by this procedure
; are `equal?`. (TODO: Test this to make sure.)
;
; TODO: See if we should change `onum-zero` to work this way for
; consistency, so that people don't accidentally pass around
; `olist-zero` as a procedure where what they want is to pass around
; the empty ordinal-indexed list.
;
(define/contract (olist-zero)
  (-> olist?)
  (olist #/olist-rep-zero))


(struct-easy (olist-rep-dynamic start stop index->element)
  (#:guard-easy
    (unless (onum? start)
      (error "Expected start to be an onum"))
    (unless (onum? stop)
      (error "Expected stop to be an onum"))
    (unless (onum<? start stop)
      (error "Expected start to be less than stop")))
  #:other
  #:methods gen:olist-rep
  [
    (define (olist-rep-length this)
      (expect this (olist-rep-dynamic start stop index->element)
        (error "Expected this to be an olist-rep")
      #/onum-drop start stop))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-dynamic start stop index->element)
        (error "Expected this to be an olist-rep")
      #/w- new-start (onum-plus start onum-one)
      #/just #/list (index->element start)
      #/if (equal? new-start stop) (olist-zero)
      #/olist #/olist-rep-dynamic new-start stop index->element))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-dynamic start stop index->element)
        (error "Expected this to be an olist-rep")
      #/if (equal? onum-zero amount)
        (just #/list (olist-zero) #/olist this)
      #/w- new-start (onum-plus start amount)
      #/w- comparison (onum-compare new-start stop)
      #/mat comparison '> (nothing)
      #/just #/list
        (olist #/olist-rep-dynamic start new-start index->element)
        (mat comparison '= (olist-zero)
        #/olist #/olist-rep-dynamic new-start stop index->element)))
  ])

(define/contract (olist-build len index->element)
  (-> onum? (-> onum? any/c) olist?)
  (if (equal? onum-zero len) (olist-zero)
  #/olist #/olist-rep-dynamic onum-zero len index->element))


(struct-easy (olist-rep-plus a b)
  (#:guard-easy
    (unless (olist-rep? a)
      (error "Expected a to be an olist-rep"))
    (unless (olist-rep? b)
      (error "Expected b to be an olist-rep")))
  #:other
  #:methods gen:olist-rep
  [
    (define/generic -length olist-rep-length)
    (define/generic -drop1 olist-rep-drop1)
    (define/generic -drop olist-rep-drop)
    
    (define (olist-rep-length this)
      (expect this (olist-rep-plus a b)
        (error "Expected this to be an olist-rep")
      #/onum-plus (-length a) (-length b)))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-plus a b)
        (error "Expected this to be an olist-rep")
      #/expect (-drop1 a) (just first-and-a-rest) (-drop1 b)
      #/dissect first-and-a-rest (list first #/olist a-rest)
      #/just #/list first #/olist #/olist-rep-plus a-rest b))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-plus a b)
        (error "Expected this to be an olist-rep")
      #/if (equal? onum-zero amount)
        (just #/list (olist-zero) #/olist this)
      #/mat (-drop amount a) (just dropped-and-a-rest)
        (dissect dropped-and-a-rest (list dropped #/olist a-rest)
        #/just #/list dropped #/olist #/olist-rep-plus a-rest b)
      #/mat (-drop (onum-drop (-length a) amount) b)
        (just dropped-and-b-rest)
        (dissect dropped-and-b-rest (list (olist dropped) b-rest)
        #/just #/list (olist #/olist-rep-plus a dropped) b-rest)
      #/nothing))
  ])

(define/contract (olist-plus-binary a b)
  (-> olist? olist? olist?)
  (dissect a (olist a)
  #/dissect b (olist b)
  #/olist #/olist-rep-plus a b))

(define/contract (olist-plus-list lsts)
  (-> (listof olist?) olist?)
  (list-foldr lsts (olist-zero) #/fn a b #/olist-plus-binary a b))

(define/contract (olist-plus . lsts)
  (->* () #:rest (listof olist?) olist?)
  (olist-plus-list lsts))
