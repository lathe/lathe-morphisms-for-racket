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


(require #/only-in racket/contract/base
  -> ->* ->d any/c list/c listof)
(require #/only-in racket/contract/region define/contract)
(require #/only-in racket/generic define/generic define-generics)

(require #/only-in lathe-comforts dissect expect fn mat w-)
(require #/only-in lathe-comforts/maybe just maybe/c nothing)
(require #/only-in lathe-comforts/list list-foldr)
(require #/only-in lathe-comforts/struct struct-easy)

(require #/only-in
  lathe-morphisms/private/ordinals/below-epsilon-zero/onum
  onum? onum<? onum<=? onum-compare onum-drop onum-drop1 onum-one
  onum-plus onum-plus1 onum-zero)

; TODO: Document all of these exports.
(provide
  (rename-out [-olist? olist?])
  ; TODO: Consider providing `list->olist` and `olist->maybe-list`
  ; operations.
  olist-zero olist-build olist-length olist-plus1
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
  
  ; TODO: See if we'll ever use `olist-map-kv`.
  olist-map olist-map-kv olist-zip-map
  olist-tails
  
  olist-ref-thunk olist-ref-and-call olist-set-thunk
  olist-update-thunk
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
  (-> olist? #/maybe/c #/list/c (-> any/c) olist?)
  (dissect lst (olist rep)
  #/olist-rep-drop1 rep))

(define/contract (olist-drop amount lst)
  (-> onum? olist? #/maybe/c #/list/c olist? olist?)
  (dissect lst (olist rep)
  #/olist-rep-drop amount rep))


; TODO: See if we should export this.
(define/contract (olist-zero? x)
  (-> any/c boolean?)
  (and (olist? x) (equal? onum-zero #/olist-length x)))


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
        (error "Expected this to be an olist-rep-dynamic")
      #/onum-drop start stop))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-dynamic start stop index->element)
        (error "Expected this to be an olist-rep-dynamic")
      #/w- new-start (onum-plus start onum-one)
      #/just #/list (fn #/index->element start)
      #/if (equal? new-start stop) (olist-zero)
      #/olist #/olist-rep-dynamic new-start stop index->element))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-dynamic start stop index->element)
        (error "Expected this to be an olist-rep-dynamic")
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
        (error "Expected this to be an olist-rep-plus")
      #/onum-plus (-length a) (-length b)))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-plus a b)
        (error "Expected this to be an olist-rep-plus")
      #/expect (-drop1 a) (just get-first-and-a-rest) (-drop1 b)
      #/dissect get-first-and-a-rest (list get-first #/olist a-rest)
      #/just #/list get-first #/olist #/olist-rep-plus a-rest b))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-plus a b)
        (error "Expected this to be an olist-rep-plus")
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
  (if (olist-zero? a) b
  #/if (olist-zero? b) a
  #/dissect a (olist a)
  #/dissect b (olist b)
  #/olist #/olist-rep-plus a b))

(define/contract (olist-plus-list lsts)
  (-> (listof olist?) olist?)
  (list-foldr lsts (olist-zero) #/fn a b #/olist-plus-binary a b))

(define/contract (olist-plus . lsts)
  (->* () #:rest (listof olist?) olist?)
  (olist-plus-list lsts))

(define/contract (olist-plus1 get-first rest)
  (-> (-> any/c) olist? olist?)
  (olist-plus (olist-build onum-one #/fn _ #/get-first) rest))


(struct-easy (olist-rep-map orig func)
  (#:guard-easy
    (unless (olist-rep? orig)
      (error "Expected orig to be an olist-rep"))
    (unless (procedure? func)
      (error "Expected func to be a procedure")))
  #:other
  #:methods gen:olist-rep
  [
    (define/generic -length olist-rep-length)
    (define/generic -drop1 olist-rep-drop1)
    (define/generic -drop olist-rep-drop)
    
    (define (olist-rep-length this)
      (expect this (olist-rep-map orig func)
        (error "Expected this to be an olist-rep-map")
      #/-length orig))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-map orig func)
        (error "Expected this to be an olist-rep-map")
      #/expect (-drop1 orig) (just get-first-and-rest) (nothing)
      #/dissect get-first-and-rest (list get-first #/olist rest)
      #/just #/list (fn #/func #/get-first)
      #/olist #/olist-rep-map rest func))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-map orig func)
        (error "Expected this to be an olist-rep-map")
      #/expect (-drop amount orig) (just dropped-and-rest) (nothing)
      #/dissect dropped-and-rest (list (olist dropped) (olist rest))
      #/just #/list
        (olist #/olist-rep-map dropped func)
        (olist #/olist-rep-map rest func)))
  ])

(define/contract (olist-map lst func)
  (-> olist? (-> any/c any/c) olist?)
  (dissect lst (olist lst)
  #/olist #/olist-rep-map lst func))


(struct-easy (olist-rep-map-kv start orig func)
  (#:guard-easy
    (unless (onum? start)
      (error "Expected start to be an onum"))
    (unless (olist-rep? orig)
      (error "Expected orig to be an olist-rep"))
    (unless (procedure? func)
      (error "Expected func to be a procedure")))
  #:other
  #:methods gen:olist-rep
  [
    (define/generic -length olist-rep-length)
    (define/generic -drop1 olist-rep-drop1)
    (define/generic -drop olist-rep-drop)
    
    (define (olist-rep-length this)
      (expect this (olist-rep-map-kv start orig func)
        (error "Expected this to be an olist-rep-map-kv")
      #/-length orig))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-map-kv start orig func)
        (error "Expected this to be an olist-rep-map-kv")
      #/expect (-drop1 orig) (just get-first-and-rest) (nothing)
      #/dissect get-first-and-rest (list get-first #/olist rest)
      #/just #/list (fn #/func start #/get-first)
      #/olist #/olist-rep-map-kv (onum-plus1 start) rest func))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-map-kv start orig func)
        (error "Expected this to be an olist-rep-map-kv")
      #/expect (-drop amount orig) (just dropped-and-rest) (nothing)
      #/dissect dropped-and-rest (list (olist dropped) (olist rest))
      #/just #/list
        (olist #/olist-rep-map-kv start dropped func)
        (olist
        #/olist-rep-map-kv (onum-plus start amount) rest func)))
  ])

(define/contract (olist-map-kv lst func)
  (-> olist? (-> onum? any/c any/c) olist?)
  (dissect lst (olist lst)
  #/olist #/olist-rep-map-kv onum-zero lst func))


(struct-easy (olist-rep-zip-map a b func)
  (#:guard-easy
    (unless (olist-rep? a)
      (error "Expected a to be an olist-rep"))
    (unless (olist-rep? b)
      (error "Expected b to be an olist-rep"))
    (unless (equal? (olist-length a) (olist-length b))
      (error "Expected the length of a and b to be the same"))
    (unless (procedure? func)
      (error "Expected func to be a procedure")))
  #:other
  #:methods gen:olist-rep
  [
    (define/generic -length olist-rep-length)
    (define/generic -drop1 olist-rep-drop1)
    (define/generic -drop olist-rep-drop)
    
    (define (olist-rep-length this)
      (expect this (olist-rep-zip-map a b func)
        (error "Expected this to be an olist-rep-zip-map")
      #/-length a))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-zip-map a b func)
        (error "Expected this to be an olist-rep-zip-map")
      #/expect (-drop1 a) (just a-get-first-and-rest) (nothing)
      #/dissect a-get-first-and-rest (list a-get-first #/olist a-rest)
      #/dissect (-drop1 b) (just #/list b-get-first #/olist b-rest)
      #/just #/list (fn #/func (a-get-first) (b-get-first))
      #/olist #/olist-rep-zip-map a-rest b-rest func))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-zip-map a b func)
        (error "Expected this to be an olist-rep-zip-map")
      #/expect (-drop amount a) (just a-dropped-and-rest) (nothing)
      #/dissect a-dropped-and-rest
        (list (olist a-dropped) (olist a-rest))
      #/dissect (-drop amount b)
        (just #/list (olist b-dropped) (olist b-rest))
      #/just #/list
        (olist #/olist-rep-map-kv a-dropped b-dropped func)
        (olist #/olist-rep-map-kv a-rest b-rest func)))
  ])

(define/contract (olist-zip-map a b func)
  (->d ([a olist?] [b olist?] [func (-> any/c any/c any/c)])
    #:pre (equal? (olist-length a) (olist-length b))
    [_ olist?])
  (dissect a (olist a)
  #/dissect b (olist b)
  #/olist #/olist-rep-zip-map a b func))


; NOTE: While we could implement `olist-tails` in terms of
; `olist-map-kv` and `olist-drop`, that would be inefficient.
(struct-easy (olist-rep-tails stop orig)
  (#:guard-easy
    (unless (onum? stop)
      (error "Expected stop to be an onum"))
    (unless (olist-rep? orig)
      (error "Expected orig to be an olist-rep"))
    (when (equal? onum-zero stop)
      (error "Expected stop to be nonzero"))
    (unless (onum<=? stop #/onum-plus1 #/olist-length orig)
      (error "Expected stop to be no greater than one plus the length of orig")))
  #:other
  #:methods gen:olist-rep
  [
    (define/generic -length olist-rep-length)
    (define/generic -drop1 olist-rep-drop1)
    (define/generic -drop olist-rep-drop)
    
    (define (olist-rep-length this)
      (expect this (olist-rep-tails stop orig)
        (error "Expected this to be an olist-rep-tails")
        stop))
    
    (define (olist-rep-drop1 this)
      (expect this (olist-rep-tails stop orig)
        (error "Expected this to be an olist-rep-tails")
      #/dissect (onum-drop1 stop) (just new-stop)
      #/just #/list (fn orig)
        (if (equal? onum-zero new-stop)
          (olist #/olist-rep-zero)
          (dissect (-drop1 orig) (just #/list get-first #/olist rest)
          #/olist #/olist-rep-tails new-stop rest))))
    
    (define (olist-rep-drop amount this)
      (expect this (olist-rep-tails stop orig)
        (error "Expected this to be an olist-rep-tails")
      #/expect (onum-drop amount stop) (just new-stop) (nothing)
      #/just #/list
        (if (equal? onum-zero amount)
          (olist #/olist-rep-zero)
          (olist #/olist-rep-tails amount orig))
        (if (equal? onum-zero new-stop)
          (olist #/olist-rep-zero)
          (dissect (-drop amount orig)
            (just #/list (olist dropped) (olist rest))
          #/olist #/olist-rep-tails new-stop rest))))
  ])

(define/contract (olist-tails lst)
  
  ; TODO: If we ever have an `olistof` contract, use it here.
  ;
  ;   (-> olist? #/olistof olist?)
  ;
  (-> olist? olist?)
  
  (w- stop (onum-plus1 #/olist-length lst)
  #/dissect lst (olist lst)
  #/olist #/olist-rep-tails stop lst))


(define/contract (olist-ref-thunk lst i)
  (->d ([lst olist?] [i onum?])
    #:pre (onum<? i #/olist-length lst)
    [_ (-> any/c)])
  (dissect (olist-drop i lst) (just #/list dropped rest)
  #/dissect (olist-drop1 rest) (just #/list get-first rest)
    get-first))

(define/contract (olist-ref-and-call lst i)
  (->d ([lst olist?] [i onum?])
    #:pre (onum<? i #/olist-length lst)
    [_ any/c])
  (#/olist-ref-thunk lst i))

(define/contract (olist-set-thunk lst i get-elem)
  (->d ([lst olist?] [i onum?] [get-elem (-> any/c)])
    #:pre (onum<? i #/olist-length lst)
    [_ olist?])
  (dissect (olist-drop i lst) (just #/list past lst)
  #/dissect (olist-drop1 lst) (just #/list get-old-elem rest)
  #/olist-plus past #/olist-plus1 get-elem rest))

(define/contract (olist-update-thunk lst i func)
  (->d ([lst olist?] [i onum?] [func (-> (-> any/c) (-> any/c))])
    #:pre (onum<? i #/olist-length lst)
    [_ olist?])
  (dissect (olist-drop i lst) (just #/list past lst)
  #/dissect (olist-drop1 lst) (just #/list get-elem rest)
  #/olist-plus past #/olist-plus1 (func get-elem) rest))
