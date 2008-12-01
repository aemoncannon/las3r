;;; las3r-mode.el -- Major mode for las3r-code

;; Copyright (C) 2008 Aemon Cannon
;;   
;;   Originally by: Jeffrey Chu <jochu0@gmail.com>
;;                  Copyright (C) 2008 Jeffrey Chu
;; 
;;   Originally by: Lennart Staflin <lenst@lysator.liu.se>
;;                  Copyright (C) 2007, 2008 Lennart Staflin
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

(require 'cl)
(require 'http-post)

(defgroup las3r-mode nil
  "A mode for Las3r"
  :prefix "las3r-mode-"
  :group 'applications)

(defcustom las3r-mode-font-lock-multiline-def t
  "Set to non-nil in order to enable font-lock of
multi-line (def...) forms. Changing this will require a
restart (ie. M-x las3r-mode) of existing las3r mode buffers."
  :type 'boolean
  :group 'las3r-mode)

(defcustom las3r-mode-font-lock-comment-sexp nil
  "Set to non-nil in order to enable font-lock of (comment...)
forms. This option is experimental. Changing this will require a
restart (ie. M-x las3r-mode) of existing las3r mode buffers."
  :type 'boolean
  :group 'las3r-mode)



(defcustom las3r-mode-use-backtracking-indent nil
  "Set to non-nil to enable backtracking/context sensitive
indentation."
  :type 'boolean
  :group 'las3r-mode)

(defcustom las3r-max-backtracking 3
  "Maximum amount to backtrack up a list to check for context."
  :type 'integer
  :group 'las3r-mode)


(defvar las3r-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-x\C-e" 'las3r-eval-last-sexp)
    (define-key map "\C-c\C-r" 'las3r-eval-buffer)
    map)
  "Keymap for ordinary Las3r mode.
All commands in `lisp-mode-shared-map' are inherited by this map.")


(defvar las3r-mode-syntax-table
  (let ((table (copy-syntax-table emacs-lisp-mode-syntax-table)))
    (modify-syntax-entry ?~ "'   " table)
    (modify-syntax-entry ?, "    " table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?^ "'" table)
    table))



(defun las3r-mode ()
  "Major mode for editing Las3r code - similar to Lisp mode..
Commands:
Delete converts tabs to spaces as it moves back.
Blank lines separate paragraphs.  Semicolons start comments.
\\{las3r-mode-map}
Note that `run-lisp' may be used either to start an inferior Lisp job
or to switch back to an existing one.

Entry to this mode calls the value of `las3r-mode-hook'
if that value is non-nil."
  (interactive)
  (kill-all-local-variables)
  (use-local-map las3r-mode-map)
  (setq major-mode 'las3r-mode)
  (setq mode-name "las3r")
  (lisp-mode-variables nil)
  (set-syntax-table las3r-mode-syntax-table)
  
  (set (make-local-variable 'comment-start-skip)
       "\\(\\(^\\|[^\\\\\n]\\)\\(\\\\\\\\\\)*\\)\\(;+\\|#|\\) *")
  (set (make-local-variable 'lisp-indent-function)
       'las3r-indent-function)
  (set (make-local-variable 'font-lock-multiline) t)

  (if (and (not (boundp 'font-lock-extend-region-functions))
           (or las3r-mode-font-lock-multiline-def
               las3r-mode-font-lock-comment-sexp))
      (message "Las3r mode font lock extras are unavailable, please upgrade to atleast version 22 ")
    
    (when las3r-mode-font-lock-multiline-def
      (add-to-list 'font-lock-extend-region-functions 'las3r-font-lock-extend-region-def t))
   
    (when las3r-mode-font-lock-comment-sexp
      (add-to-list 'font-lock-extend-region-functions 'las3r-font-lock-extend-region-comment t)
      (make-local-variable 'las3r-font-lock-keywords)
      (add-to-list 'las3r-font-lock-keywords  'las3r-font-lock-mark-comment t)
      (set (make-local-variable 'open-paren-in-column-0-is-defun-start) nil)))

  (setq font-lock-defaults
	'(las3r-font-lock-keywords	; keywords
	  nil nil
          (("+-*/.<>=!?$%_&~^:@" . "w")) ; syntax alist
          nil
	  (font-lock-mark-block-function . mark-defun)
	  (font-lock-syntactic-face-function . lisp-font-lock-syntactic-face-function)))
  
  (run-mode-hooks 'las3r-mode-hook))


(defun las3r-eval-last-sexp (p)
  "Evaluate the sexp before point."
  (interactive (list (point)))
  (save-excursion
    (backward-sexp)
    (let ((src (buffer-substring-no-properties (point) p)))
      (let* ((proc (http-post "http://localhost:9876/push" `(("src" . ,(format "%s" src))) 'iso-8859-1))
	     (buf (process-buffer proc)))
	(kill-buffer buf)))))
  
(defun las3r-eval-buffer nil
  "Evaluate the code in the current buffer."
  (interactive)
  (let ((src (buffer-string)))
    (let* ((proc (http-post "http://localhost:9876/push" `(("src" . ,(format "%s" src))) 'iso-8859-1))
	   (buf (process-buffer proc)))
      (kill-buffer buf))))

(defun las3r-font-lock-def-at-point (point)
  "Find the position range between the top-most def* and the
fourth element afterwards. Note that this means there's no
gaurantee of proper font locking in def* forms that are not at
top-level."
  (goto-char point)
  (condition-case nil
      (beginning-of-defun)
    (error nil))
  
  (let ((beg-def (point)))
    (when (and (not (= point beg-def))
               (looking-at "(def"))
      (condition-case nil
	  (progn
	    ;; move forward as much as possible until failure (or success)
	    (forward-char)
	    (dotimes (i 4)
	      (forward-sexp)))
	(error nil))
      (cons beg-def (point)))))

(defun las3r-font-lock-extend-region-def ()
  "Move fontification boundaries to always include the first four
elements of a def* forms."
  (let ((changed nil))
    (let ((def (las3r-font-lock-def-at-point font-lock-beg)))
      (when def
	(destructuring-bind (def-beg . def-end) def
	  (when (and (< def-beg font-lock-beg)
		     (< font-lock-beg def-end))
	    (setq font-lock-beg def-beg
		  changed t)))))

    (let ((def (las3r-font-lock-def-at-point font-lock-end)))
      (when def
	(destructuring-bind (def-beg . def-end) def
	  (when (and (< def-beg font-lock-end)
		     (< font-lock-end def-end))
	    (setq font-lock-end def-end
		  changed t)))))
    changed))

(defun las3r-font-lock-extend-region-comment ()
  "Move fontification boundaries to always contain
  entire (comment ..) sexp. Does not work if you have a
  white-space between ( and comment, but that is omitted to make
  this run faster."
  (let ((changed nil))
    (goto-char font-lock-beg)
    (condition-case nil (beginning-of-defun) (error nil))
    (let ((pos (re-search-forward "(comment\\>" font-lock-end t)))
      (when pos
        (forward-char -8)
        (when (< (point) font-lock-beg)
          (setq font-lock-beg (point)
                changed t))
        (condition-case nil (forward-sexp) (error nil))
        (when (> (point) font-lock-end)
          (setq font-lock-end (point)
                changed t))))
    changed))
        

(defun las3r-font-lock-mark-comment (limit)
  "Marks all (comment ..) forms with font-lock-comment-face."
  (let (pos)
    (while (and (< (point) limit)
                (setq pos (re-search-forward "(comment\\>" limit t)))
      (when pos
        (forward-char -8)
        (condition-case nil
            (add-text-properties (1+ (point)) (progn (forward-sexp) (1- (point)))
                                 '(face font-lock-comment-face multiline t))
          (error (forward-char 8))))))
  nil)

(defconst las3r-font-lock-keywords
  (eval-when-compile
    `( ;; Definitions.
      (,(concat "(\\(?:las3r/\\)?\\(def"
		;; Function declarations.
		"\\(n-?\\|multi\\|macro\\|method\\|"
		;; Variable declarations.
                "struct\\|"
		"\\)\\)\\>"
		;; Any whitespace
		"[ \r\n\t]*"
                ;; Possibly type or metadata
                "\\(?:#^\\(?:{[^}]*}\\|\\sw+\\)[ \r\n\t]*\\)?"
                
                "\\(\\sw+\\)?")
       (1 font-lock-keyword-face)
       (3 font-lock-function-name-face nil t))
      ;; Control structures
      (,(concat
         "(\\(?:las3r/\\)?" 
         (regexp-opt
          '("cond" "for" "loop" "let" "recur" "do" "binding" "with-meta"
            "when" "when-not" "when-let" "when-first" "if" "if-let"
            "delay" "lazy-cons" "." ".." "->" "and" "or" "locking"
            "dosync"
            "sync" "doseq" "dotimes" "import" "unimport" "in-ns" "refer"
            "implement" "proxy" "time" "try" "catch" "finally" "throw"
            "doto" "with-open" "with-local-vars" "struct-map" ) t)
         "\\>")
       .  1)
      ;; (fn name? args ...)
      (,(concat "(\\(?:las3r/\\)?\\(fn\\)[ \t]+"
                ;; Possibly type
                "\\(?:#^\\sw+[ \t]*\\)?"
                ;; Possibly name
                "\\(\\sw+\\)?" )
       (1 font-lock-keyword-face)
       (2 font-lock-function-name-face nil t))
      ;; Constant values.
      ("\\<:\\sw+\\>" 0 font-lock-builtin-face)
      ;; Meta type annotation #^Type
      ("#^\\sw+" 0 font-lock-type-face)
      ))
  "Default expressions to highlight in las3r mode.")




(defun las3r-indent-function (indent-point state)
  "This function is the normal value of the variable `lisp-indent-function'.
It is used when indenting a line within a function call, to see if the
called function says anything special about how to indent the line.

INDENT-POINT is the position where the user typed TAB, or equivalent.
Point is located at the point to indent under (for default indentation);
STATE is the `parse-partial-sexp' state for that position.

If the current line is in a call to a Lisp function
which has a non-nil property `lisp-indent-function',
that specifies how to do the indentation.  The property value can be
* `defun', meaning indent `defun'-style;
* an integer N, meaning indent the first N arguments specially
  like ordinary function arguments and then indent any further
  arguments like a body;
* a function to call just as this function was called.
  If that function returns nil, that means it doesn't specify
  the indentation.

This function also returns nil meaning don't specify the indentation."
  (let ((normal-indent (current-column)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (if (and (elt state 2)
             (not (looking-at "\\sw\\|\\s_")))
        ;; car of form doesn't seem to be a symbol
        (progn
          (if (not (> (save-excursion (forward-line 1) (point))
                      calculate-lisp-indent-last-sexp))
	      (progn (goto-char calculate-lisp-indent-last-sexp)
		     (beginning-of-line)
		     (parse-partial-sexp (point)
					 calculate-lisp-indent-last-sexp 0 t)))
	  ;; Indent under the list or under the first sexp on the same
	  ;; line as calculate-lisp-indent-last-sexp.  Note that first
	  ;; thing on that line has to be complete sexp since we are
          ;; inside the innermost containing sexp.
          (backward-prefix-chars)
          (if (and (eq (char-after (point)) ?\[)
                   (eq (char-after (elt state 1)) ?\())
              (+ (current-column) 2) ;; this is probably inside a defn
            (current-column)))
      (let ((function (buffer-substring (point)
					(progn (forward-sexp 1) (point))))
            (open-paren (elt state 1))
	    method)
	(setq method (get (intern-soft function) 'las3r-indent-function))
        
	(cond ((member (char-after open-paren) '(?\[ ?\{))
	       (goto-char open-paren)
               (1+ (current-column)))
	      ((or (eq method 'defun)
		   (and (null method)
			(> (length function) 3)
			(string-match "\\`\\(?:las3r/\\)?def" function)))
	       (lisp-indent-defform state indent-point))
              
	      ((integerp method)
	       (lisp-indent-specform method state
				     indent-point normal-indent))
	      (method
	       (funcall method indent-point state))
              (las3r-mode-use-backtracking-indent
               (las3r-backtracking-indent indent-point state normal-indent)))))))

(defun las3r-backtracking-indent (indent-point state normal-indent)
  "Experimental backtracking support. Will upwards in an sexp to
check for contextual indenting."
  (let (indent (path) (depth 0))
    (goto-char (elt state 1))
    (while (and (not indent)
                (< depth las3r-max-backtracking))
      (let ((containing-sexp (point)))
        (parse-partial-sexp (1+ containing-sexp) indent-point 1 t)
        (when (looking-at "\\sw\\|\\s_")
          (let* ((start (point))
                 (fn (buffer-substring start (progn (forward-sexp 1) (point))))
                 (meth (get (intern-soft fn) 'las3r-backtracking-indent)))
            (let ((n 0))
              (when (< (point) indent-point)
                (condition-case ()
                    (progn
		      (forward-sexp 1)
		      (while (< (point) indent-point)
			(parse-partial-sexp (point) indent-point 1 t)
			(incf n)
			(forward-sexp 1)))
                  (error nil)))
              (push n path))
            (when meth
              (let ((def meth))
                (dolist (p path)
                  (if (and (listp def)
                           (< p (length def)))
                      (setq def (nth p def))
                    (if (listp def)
                        (setq def (car (last def)))
                      (setq def nil))))
                (goto-char (elt state 1))
                (when def
                  (setq indent (+ (current-column) def)))))))
        (goto-char containing-sexp)
        (condition-case ()
            (progn
              (backward-up-list 1)
              (incf depth))
          (error (setq depth las3r-max-backtracking)))))
    indent))

;; (defun las3r-indent-defn (indent-point state)
;;   "Indent by 2 if after a [] clause that's at the beginning of a
;; line"
;;   (if (not (eq (char-after (elt state 2)) ?\[))
;;       (lisp-indent-defform state indent-point)
;;     (goto-char (elt state 2))
;;     (beginning-of-line)
;;     (skip-syntax-forward " ")
;;     (if (= (point) (elt state 2))
;;         (+ (current-column) 2)
;;       (lisp-indent-defform state indent-point))))

;; (put 'defn 'las3r-indent-function 'las3r-indent-defn)
;; (put 'defmacro 'las3r-indent-function 'las3r-indent-defn)

;; las3r backtracking indent is experimental and the format for these

;; entries are subject to change
(put 'implement 'las3r-backtracking-indent '(4 (2)))
(put 'proxy 'las3r-backtracking-indent '(4 4 (2)))


(defun put-las3r-indent (sym indent)
  (put sym 'las3r-indent-function indent)
  (put (intern (format "las3r/%s" (symbol-name sym))) 'las3r-indent-function indent))

(defmacro define-las3r-indent (&rest kvs)
  `(progn
     ,@(mapcar (lambda (x) `(put-las3r-indent (quote ,(first x)) ,(second x))) kvs)))

(define-las3r-indent
  (catch 2)
  (defmuti 1)
  (do 0)
  (for 1)	    ; FIXME (for seqs expr) and (for seqs filter expr)
  (if 1)
  (let 1)
  (loop 1)
  (struct-map 1)
  (assoc 1)

  (fn 'defun))

;; built-ins
(define-las3r-indent
  (binding 1)
  (comment 0)
  (defstruct 1)
  (doseq 2)
  (dotimes 2)
  (doto 1)
  (implement 1)
  (let 1)
  (when-let 2)
  (if-let 2)
  (locking 1)
  (proxy 2)
  (sync 1)
  (when 1)
  (when-first 2)
  (when-let 2)
  (when-not 1)
  (with-local-vars 1)
  (with-open 2))

;; macro indent (auto generated)

;; Things that just aren't right (manually removed)
					; (put '-> 'las3r-indent-function 2)
					; (put '.. 'las3r-indent-function 2)
					; (put 'and 'las3r-indent-function 1)
					; (put 'defmethod 'las3r-indent-function 2)
					; (put 'defn- 'las3r-indent-function 1)
					; (put 'memfn 'las3r-indent-function 1)
					; (put 'or 'las3r-indent-function 1)
					; (put 'lazy-cat 'las3r-indent-function 1)
					; (put 'lazy-cons 'las3r-indent-function 1)

(provide 'las3r-mode)

;;; las3r-mode.el ends here
