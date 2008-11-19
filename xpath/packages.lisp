;; packages.lisp

(defpackage :libxml2.xpath
  (:use :cl :cffi :iter :libxml2.private :libxml2.tree #+sbcl :sb-ext :metabang.bind)
  (:export
   :compiled-expression
   :compile-expression
   :with-compiled-expression
   :node-set
   :node-set-length
   :node-set-at
   :xpath-result
   :xpath-result-type
   :xpath-result-value
   :eval-expression

   :find-string
   :find-number
   :find-boolean
   :find-single-node
   :with-xpath-result
   :*default-ns-map*
   :getpath

   :xpath-parser-context
   :with-xpath-functions
   :defxpathfun
   ))