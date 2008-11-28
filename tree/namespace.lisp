;;; namespace.lisp

(in-package #:libxml2.tree)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ns
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcstruct %xmlNs
  ;; struct _xmlNs *	next	: next Ns link for this node
  (%next %xmlNsPtr)
  ;; xmlNsType	type	: global or local
  (%type %xmlNsType)
  ;; const xmlChar *	href	: URL for the namespace
  (%href %xmlCharPtr)
  ;; const xmlChar *	prefix	: prefix for the namespace  
  (%prefix %xmlCharPtr)
  ;; void *	_private	: application data
  (%_private :pointer)
  ;; struct _xmlDoc *	context	: normally an xmlDoc  
  (%context %xmlDocPtr))

(defwrapper ns %xmlNs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; make-ns
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlSearchNs" %xmlSearchNs) %xmlNsPtr
  (doc %xmlDocPtr)
  (node %xmlNodePtr)
  (prefix %xmlCharPtr))

(defun generate-ns-prefix (element)
  (iter (for i from 1)
        (for prefix = (format nil "ns_~A" i))
        (finding prefix such-that (null-pointer-p (with-foreign-string (%prefix prefix)
                                                    (%xmlSearchNs (pointer (document element))
                                                                  (pointer element)
                                                                  %prefix))))))

(defcfun ("xmlNewNs" %xmlNewNs) %xmlNsPtr
  (node %xmlNodePtr)
  (href %xmlCharPtr)
  (prefix %xmlCharPtr))

(defun make-ns (element href &optional prefix)
  (make-instance 'ns
                 :pointer (with-foreign-strings ((%href href) (%prefix (or prefix (generate-ns-prefix element))))
                            (%xmlNewNs (pointer element)
                                       %href
                                       %prefix))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; search-ns-by-href
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlSearchNsByHref" %xmlSearchNsByHref) %xmlNsPtr
  (doc %xmlDocPtr)
  (node %xmlNodePtr)
  (href %xmlCharPtr))

(defun search-ns-by-href (element href)
  (let ((%ns (with-foreign-string (%href href)
               (%xmlSearchNsByHref (pointer (document element))
                                   (pointer element)
                                   %href))))
    (unless (null-pointer-p %ns)
      (make-instance 'ns :pointer %ns))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; namespace-uri
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun namespace-uri (node)
   (let ((%ns (wrapper-slot-value node '%ns)))
     (unless (null-pointer-p %ns)
       (cffi:foreign-string-to-lisp (cffi:foreign-slot-value %ns '%xmlNs '%href)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; namespace-prefix
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun namespace-prefix (node)
   (let ((ns (wrapper-slot-wrapper node '%ns 'ns)))
     (if ns (cffi:foreign-string-to-lisp
              (wrapper-slot-value ns '%prefix)))))
