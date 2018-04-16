#lang info

(define collection "lathe-morphisms")

(define deps (list "base"))
(define build-deps
  (list
    "lathe-morphisms-lib"
    "parendown-lib"
    "racket-doc"
    "scribble-lib"))

(define scribblings
  (list (list "scribblings/lathe-morphisms.scrbl" (list))))
