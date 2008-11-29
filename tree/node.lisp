;;; node.lisp

(in-package #:libxml2.tree)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; node
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcstruct %xmlNode
  ;; void *	_private	: application data
  (%private :pointer)
  ;; xmlElementType	type	: type number, must be second !
  (%type %xmlElementType)
  ;; const xmlChar *	name	: the name of the node, or the entity
  (%name %xmlCharPtr)
  ;; struct _xmlNode *	children	: parent->childs link
  (%children %xmlNodePtr)
  ;; struct _xmlNode *	last	: last child link
  (%last %xmlNodePtr)
  ;; struct _xmlNode *	parent	: child->parent link
  (%parent %xmlNodePtr)
  ;; struct _xmlNode *	next	: next sibling link
  (%next %xmlNodePtr)
  ;; struct _xmlNode *	prev	: previous sibling link
  (%prev %xmlNodePtr)
  ;; struct _xmlDoc *	doc	: the containing document End of common p
  (%doc %xmlDocPtr)
  ;; xmlNs *	ns	: pointer to the associated namespace
  (%ns %xmlNsPtr)
  ;; xmlChar *	content	: the content
  (%content %xmlCharPtr)
  ;; struct _xmlAttr *	properties	: properties list
  (%properties %xmlAttrPtr)
  ;; xmlNs *	nsDef	: namespace definitions on this node
  (%nsDef %xmlNsPtr)
  ;; void *	psvi	: for type/PSVI informations
  (%psvi :pointer)
  ;; unsigned short	line	: line number
  (%line :unsigned-short)
  ;; unsigned short	extra	: extra data for XPath/XSLT
  (%extra :unsigned-short))

(defwrapper node %xmlNode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; release/impl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlFreeNode" %xmlFreeNode) :void
  (node %xmlNodePtr))

(defmethod release/impl ((node node))
  (%xmlFreeNode (pointer node)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; copy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlCopyNode" %xmlCopyNode) %xmlNodePtr
  (node %xmlNodePtr)
  (extended :int))

(defmethod copy ((node node))
  (make-instance 'node
                 :pointer (%xmlCopyNode (pointer node) 1)))



(defun wrapper-slot-node (node slot)
  (wrapper-slot-wrapper node slot 'node))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; make-element
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlNewNode" %xmlNewNode) %xmlNodePtr
  (ns %xmlNsPtr)
  (name %xmlCharPtr))

(defun make-element (name &optional href prefix)
  (let ((%node (with-foreign-string (%name name)
                 (%xmlNewNode (null-pointer) 
                              %name))))
    (if href
        (setf (foreign-slot-value %node
                                  '%xmlNode
                                  '%ns)
              (gp:with-garbage-pool ()
                (%xmlNewNs %node
                           (gp:cleanup-register (foreign-string-alloc href) #'foreign-string-free)
                           (if prefix
                               (gp:cleanup-register (foreign-string-alloc prefix)  #'foreign-string-free)
                               (null-pointer))))))
    (make-instance 'node
                   :pointer %node)))
                
               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; make-text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlNewText" %xmlNewText) %xmlNodePtr
  (content %xmlCharPtr))

(defun make-text (data)
  (make-instance 'node
                 :pointer (with-foreign-string (%data data)
                            (%xmlNewText %data))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; make-comment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlNewComment" %xmlNewComment) %xmlNodePtr
  (content %xmlCharPtr))

(defun make-comment (data)
  (make-instance 'node
                 :pointer (with-foreign-string (%data data)
                            (%xmlNewComment %data))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; make-process-instruction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlNewPI" %xmlNewPI) %xmlNodePtr
  (name %xmlCharPtr)
  (content %xmlCharPtr))

(defun make-process-instruction (name content)
  (make-instance 'node
                 :pointer (with-foreign-strings ((%name name) (%content content))
                            (%xmlNewPI %name %content))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; predicates
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro def-node-p (name node-type)
  `(defun ,name (node &key throw-error)
     (if (eql (node-type node) ,node-type)
         t
         (if throw-error
             (error (format nil "node is not ~A" ,node-type))))))

(def-node-p element-p :xml-element-node)
(def-node-p attribute-p :xml-attribute-node)
(def-node-p text-p :xml-element-text)
(def-node-p comment-p :xml-comment-node)
(def-node-p process-instruction-p :xml-pi-node)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; local-name
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun local-name (node)
  (cffi:foreign-string-to-lisp
   (wrapper-slot-value node '%name)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; node-type
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun node-type (node)
  (wrapper-slot-value node '%type))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; next-sibling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun next-sibling (node)
  (wrapper-slot-node node '%next))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; prev-sibling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun prev-sibling (node)
  (wrapper-slot-node node '%prev))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; first-child
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun first-child (node)
  (wrapper-slot-node node '%children))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; last-child
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun last-child (node)
  (wrapper-slot-node node '%last))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; parent
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun parent (node)
  (wrapper-slot-node node '%parent))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; text-content
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlNodeGetContent" %xmlNodeGetContent) %xmlCharPtr
  (cur %xmlNodePtr))

(defun text-content (node)
  (let ((%content (%xmlNodeGetContent (pointer node))))
    (unless (null-pointer-p %content)
      (unwind-protect
           (foreign-string-to-lisp %content)
        (%xmlFree %content)))))

(defcfun ("xmlNodeSetContent" %xmlNodeSetContent) :void
  (cur %xmlNodePtr)
  (content %xmlCharPtr))

(defun (setf text-content) (content node)
  (with-foreign-string (%content content)
    (%xmlNodeSetContent (pointer node)
                        %content)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; base-url
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlNodeGetBase" %xmlNodeGetBase) %xmlCharPtr
  (doc %xmlDocPtr)
  (cur %xmlNodePtr))

(defmethod base-url ((node node))
  (let ((%str (%xmlNodeGetBase (pointer (document node))
                               (pointer node))))
    (unwind-protect
         (puri:parse-uri (foreign-string-to-lisp %str))
      (%xmlFree %str))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; process-xinclude
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlXIncludeProcessTree" %xmlXIncludeProcessTree) :int
  (node %xmlNodePtr))

(defmethod process-xinclude ((node node))
  (%xmlXincludeProcessTree (pointer node)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; FOR var IN-... WITH ()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun node-filter (&key type local-name ns filter)
  (if (or type local-name)
      (lambda (node)
        (and (or (not type)
                 (eql (node-type node) type))
             (or (not local-name)
                 (string= (local-name node) local-name))
             (or (not ns)
                 (string= (namespace-uri node) ns))
             (or (not filter)
                 (funcall filter node))))))

(defun find-node (first filter)
  (if first
    (if filter
        (if (funcall filter first)
            first
            (find-node (next-sibling first) filter))
        first)))


;;; FOR var IN-CHILD-NODES node WITH ()

(defmacro-driver (for var in-child-nodes node &optional with filter)
  (let ((kwd (if generate 'generate 'for)))
  `(progn
     (with filter-fun = (node-filter ,@filter))
     (,kwd ,var first (find-node (first-child ,node) filter-fun) then (find-node (next-sibling ,var) filter-fun))
     (while ,var))))


;;; FOR var IN-NEXT-SIBLINGS node WITH ()

(defmacro-driver (for var in-next-siblings node &optional with filter)
  (let ((kwd (if generate 'generate 'for)))
  `(progn
     (with filter-fun = (node-filter ,@filter))
     (,kwd ,var first (find-node (next-sibling ,node) filter-fun) then (find-node (next-sibling ,var) filter-fun))
     (while ,var))))

;;; FOR var IN-NEXT-SIBLINGS-FROM node WITH ()

(defmacro-driver (for var in-next-siblings-from node &optional with filter)
  (let ((kwd (if generate 'generate 'for)))
  `(progn
     (with filter-fun = (node-filter ,@filter))
     (,kwd ,var first (find-node ,node filter-fun) then (find-node (next-sibling ,var) filter-fun))
     (while ,var))))

;;; FOR var IN-PREV-SIBLING node WITH ()

(defmacro-driver (for var in-prev-siblings node &optional with filter)
  (let ((kwd (if generate 'generate 'for)))
  `(progn
     (with filter-fun = (node-filter ,@filter))
     (,kwd ,var first (find-node (prev-sibling ,node) filter-fun) then (find-node (prev-sibling ,var) filter-fun))
     (while ,var))))

;;; FOR var IN-PREV-SIBLING-FROM node WITH ()

(defmacro-driver (for var in-prev-siblings-from node &optional with filter)
  (let ((kwd (if generate 'generate 'for)))
  `(progn
     (with filter-fun = (node-filter ,@filter))
     (,kwd ,var first (find-node ,node filter-fun) then (find-node (prev-sibling ,var) filter-fun))
     (while ,var))))




(defun pointer-to-node (ptr)
  (unless (null-pointer-p ptr)
    (make-instance 'node
                   :pointer ptr)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; insert-child-before
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlAddPrevSibling" %xmlAddPrevSibling) %xmlNodePtr
  (cur %xmlNodePtr)
  (elem %xmlNodePtr))

(defun insert-child-before (new-child ref-child)
  (pointer-to-node (%xmlAddPrevSibling (pointer ref-child)
                                       (pointer new-child))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; insert-child-after
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlAddNextSibling" %xmlAddNextSibling) %xmlNodePtr
  (cur %xmlNodePtr)
  (elem %xmlNodePtr))

(defun insert-child-after (new-child ref-child)
  (pointer-to-node (%xmlAddNextSibling (pointer ref-child)
                                       (pointer new-child))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; append-child
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlAddChild" %xmlAddChild) %xmlNodePtr
  (parent %xmlNodePtr)
  (child %xmlNodePtr))

(defun append-child (parent node)
  (pointer-to-node (%xmlAddChild (pointer parent)
                                 (pointer node))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; prepend-child
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun prepend-child (parent node)
  (let ((first (first-child parent)))
    (if first
        (insert-child-before node first)
        (append-child parent node))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; detach
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlUnlinkNode" %xmlUnlinkNode) :void
  (node %xmlNodePtr))

(defun detach (node)
  (%xmlUnlinkNode (pointer node)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; remove-child
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun remove-child (child)
  (detach child)
  (release child))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; replace-child
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defcfun ("xmlReplaceNode" %xmlReplaceNode) %xmlNodePtr
  (old %xmlNodePtr)
  (cur %xmlNodePtr))

(defun replace-child (old-child new-child &key (delete t))
  (let ((%old (%xmlReplaceNode (pointer old-child)
                               (pointer new-child))))
    (if delete
        (%xmlFreeNode %old)
        (pointer-to-node %old))))