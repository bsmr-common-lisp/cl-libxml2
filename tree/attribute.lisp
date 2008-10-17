;; attribute.lisp

(in-package #:libxml2.tree)

;;; attribute-value

(defun attribute-value (element name &optional uri)
  (foreign-string-to-lisp 
   (with-foreign-string (%name name)
     (if uri
         (with-foreign-string (%uri uri)
           (%xmlGetNsProp (pointer element) %name %uri))
         (%xmlGetProp (pointer element) %name)))))


(defun set-attribute-value (element name &optional uri value)
  (with-foreign-strings ((%name name) (%value (or value uri)))
    (if value
        (let ((ns (or (search-ns-by-href element uri)
                      (make-ns element uri))))
          (%xmlSetNsProp (pointer element) (pointer ns) %name %value))
        (%xmlSetProp (pointer element) %name %value)))
  (or value uri))

(defsetf attribute-value set-attribute-value)

;;; remove-attribute

(defun remove-attribute (element name &optional uri)
  (let ((%attr (with-foreign-string (%name name)
                  (if uri
                      (with-foreign-string (%uri uri)
                        (%xmlHasNsProp (pointer element) %name %uri))
                      (%xmlHasProp (pointer element) %name)))))
    (unless (null-pointer-p %attr)
      (= 0 (%xmlRemoveProp %attr)))))

;;; iter (FOR (value name href)  IN-NODE-ATTRIBUTES node )

(defmacro-driver (for attr in-attributes node)
  (let ((kwd (if generate 'generate 'for)))
    `(progn
       (,kwd %attr first (foreign-slot-value (pointer ,node) '%xmlNode '%properties) then (foreign-slot-value %attr '%xmlAttr '%next))
       (while (not (null-pointer-p %attr)))
       (for ,attr = (list (foreign-string-to-lisp 
                           (foreign-slot-value (foreign-slot-value %attr 
                                                                   '%xmlAttr 
                                                                   '%children) 
                                               '%xmlNode 
                                               '%content))
                          (foreign-string-to-lisp (foreign-slot-value %attr '%xmlAttr '%name))
                          (let ((%ns (foreign-slot-value %attr '%xmlAttr '%ns)))
                            (unless (null-pointer-p %ns)
                              (foreign-string-to-lisp (foreign-slot-value %ns
                                                                          '%xmlNs
                                                                          '%href)))))))))

;;; add-extra-namespace (element prefix uri)

(defun add-extra-namespace (element href prefix)
  (with-foreign-strings ((%href href) (%prefix prefix))
                         (%xmlNewNs (pointer element)
                                    %href
                                    %prefix)))

  