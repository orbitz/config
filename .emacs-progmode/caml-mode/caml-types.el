;(***********************************************************************)
;(*                                                                     *)
;(*                           Objective Caml                            *)
;(*                                                                     *)
;(*          Damien Doligez, projet Moscova, INRIA Rocquencourt         *)
;(*                                                                     *)
;(*  Copyright 2003 Institut National de Recherche en Informatique et   *)
;(*  en Automatique.  All rights reserved.  This file is distributed    *)
;(*  under the terms of the GNU General Public License.                 *)
;(*                                                                     *)
;(***********************************************************************)

;(* $Id: caml-types.el,v 1.33 2007/02/09 13:31:15 doligez Exp $ *)

; An emacs-lisp complement to the "-dtypes" option of ocamlc and ocamlopt.

;; XEmacs compatibility

(eval-and-compile
  (if (and (boundp 'running-xemacs) running-xemacs) 
      (require 'caml-xemacs)
    (require 'caml-emacs)))



(defvar caml-types-location-re nil "Regexp to parse *.annot files.

Annotation files *.annot may be generated with the \"-dtypes\" option 
of ocamlc and ocamlopt. 

Their format is:

  file ::= block *
  block ::= position <SP> position <LF> annotation *
  position ::= filename <SP> num <SP> num <SP> num
  annotation ::= keyword open-paren <LF> <SP> <SP> data <LF> close-paren

  <SP> is a space character (ASCII 0x20)
  <LF> is a line-feed character (ASCII 0x0A)
  num is a sequence of decimal digits
  filename is a string with the lexical conventions of O'Caml
  open-paren is an open parenthesis (ASCII 0x28)
  close-paren is a closed parenthesis (ASCII 0x29)
  data is any sequence of characters where <LF> is always followed by
       at least two space characters.

- in each block, the two positions are respectively the start and the
  end of the range described by the block.
- in a position, the filename is the name of the file, the first num
  is the line number, the second num is the offset of the beginning
  of the line, the third num is the offset of the position itself.
- the char number within the line is the difference between the third
  and second nums.

For the moment, the only possible keyword is \"type\"."
)

(let* ((caml-types-filename-re "\"\\(\\([^\\\"]\\|\\\\.\\)*\\)\"")
       (caml-types-number-re "\\([0-9]*\\)")
       (caml-types-position-re
        (concat caml-types-filename-re " "
                caml-types-number-re " "
                caml-types-number-re " "
                caml-types-number-re)))
  (setq caml-types-location-re
        (concat "^" caml-types-position-re " " caml-types-position-re)))

(defvar caml-types-expr-ovl (make-overlay 1 1))

(make-face 'caml-types-face)
(set-face-doc-string 'caml-types-face
                     "face for hilighting expressions and types")
(if (not (face-differs-from-default-p 'caml-types-face))
    (set-face-background 'caml-types-face "#88FF44"))

(defvar caml-types-typed-ovl (make-overlay 1 1))

(make-face 'caml-types-typed-face)
(set-face-doc-string 'caml-types-typed-face
                     "face for hilighting typed expressions")
(if (not (face-differs-from-default-p 'caml-types-typed-face))
    (set-face-background 'caml-types-typed-face "#FF8844"))

(overlay-put caml-types-expr-ovl 'face 'caml-types-face)
(overlay-put caml-types-typed-ovl 'face 'caml-types-typed-face)


(defvar caml-types-annotation-tree nil)
(defvar caml-types-annotation-date nil)
(make-variable-buffer-local 'caml-types-annotation-tree)
(make-variable-buffer-local 'caml-types-annotation-date)

(defvar caml-types-buffer-name "*caml-types*"
  "Name of buffer for diplaying caml types")
(defvar caml-types-buffer nil
  "buffer for diplaying caml types")

(defun caml-types-show-type (arg)
  "Show the type of expression or pattern at point.
   The smallest expression or pattern that contains point is
   temporarily highlighted.  Its type is highlighted in the .annot
   file and the mark is set to the beginning of the type.
   The type is also displayed in the mini-buffer.

   Hints on using the type display:
   . If you want the type of an identifier, put point within any
     occurrence of this identifier.
   . If you want the result type of a function application, put point
     at the first space after the function name.
   . If you want the type of a list, put point on a bracket, on a
     semicolon, or on the :: constructor.
   . Even if type checking fails, you can still look at the types
     in the file, up to where the type checker failed.

Types are also displayed in the buffer *caml-types*, which is
displayed when the command is called with Prefix argument 4. 

See also `caml-types-explore' for exploration by mouse dragging.
See `caml-types-location-re' for annotation file format.
"
  (interactive "p")
  (let* ((target-buf (current-buffer))
         (target-file (file-name-nondirectory (buffer-file-name)))
         (target-line (1+ (count-lines (point-min)
                                       (caml-line-beginning-position))))
         (target-bol (caml-line-beginning-position))
         (target-cnum (point))
         (type-file (concat (file-name-sans-extension (buffer-file-name))
                            ".annot")))
    (caml-types-preprocess type-file)
    (setq caml-types-buffer (get-buffer-create caml-types-buffer-name))
    (let* ((targ-loc (vector target-file target-line target-bol target-cnum))
           (node (caml-types-find-location targ-loc ()
                                           caml-types-annotation-tree)))
      (cond
       ((null node)
         (delete-overlay caml-types-expr-ovl)
         (message "Point is not within a typechecked expression or pattern."))
       (t
        (let ((left (caml-types-get-pos target-buf (elt node 0)))
              (right (caml-types-get-pos target-buf (elt node 1)))
              (type (elt node 2)))
          (move-overlay caml-types-expr-ovl left right target-buf)
          (with-current-buffer caml-types-buffer
            (erase-buffer)
            (insert type)
            (message (format "type: %s" type)))
          ))))
    (if (and (= arg 4)
             (not (window-live-p (get-buffer-window caml-types-buffer))))
        (display-buffer caml-types-buffer))
    (unwind-protect
        (caml-sit-for 60)
      (delete-overlay caml-types-expr-ovl)
      )))

(defun caml-types-preprocess (type-file)
  (let* ((type-date (nth 5 (file-attributes type-file)))
         (target-file (file-name-nondirectory (buffer-file-name)))
         (target-date (nth 5 (file-attributes target-file))))
    (unless (and caml-types-annotation-tree
                 type-date
                 caml-types-annotation-date
                 (not (caml-types-date< caml-types-annotation-date type-date)))
      (if (and type-date target-date (caml-types-date< type-date target-date))
          (error (format "%s is more recent than %s" target-file type-file)))
      (message "Reading annotation file...")
      (let* ((type-buf (caml-types-find-file type-file))
             (tree (with-current-buffer type-buf
                    (widen)
                    (goto-char (point-min))
                    (caml-types-build-tree target-file))))
        (setq caml-types-annotation-tree tree
              caml-types-annotation-date type-date)
        (kill-buffer type-buf)
        (message ""))
      )))

(defun caml-types-date< (date1 date2)
  (or (< (car date1) (car date2))
      (and (= (car date1) (car date2))
           (< (nth 1 date1) (nth 1 date2)))))


; we use an obarray for hash-consing the strings within each tree

(defun caml-types-make-hash-table ()
  (make-vector 255 0))

(defun caml-types-hcons (elem table)
  (symbol-name (intern elem table)))


; tree of intervals
; each node is a vector
; [ pos-left pos-right type-info child child child... ]
; type-info =
;  () if this node does not correspond to an annotated interval
;  (type-start . type-end)  address of the annotation in the .annot file

(defun caml-types-build-tree (target-file)
  (let ((stack ())
        (accu ())
        (table (caml-types-make-hash-table))
        (type-info ()))
    (while (re-search-forward caml-types-location-re () t)
      (let ((l-file (file-name-nondirectory (match-string 1)))
            (l-line (string-to-int (match-string 3)))
            (l-bol (string-to-int (match-string 4)))
            (l-cnum (string-to-int (match-string 5)))
            (r-file (file-name-nondirectory (match-string 6)))
            (r-line (string-to-int (match-string 8)))
            (r-bol (string-to-int (match-string 9)))
            (r-cnum (string-to-int (match-string 10))))
        (unless (caml-types-not-in-file l-file r-file target-file)
          (while (and (re-search-forward "^" () t)
                      (not (looking-at "type"))
                      (not (looking-at "\\\"")))
            (forward-char 1))
          (setq type-info
                (if (looking-at
                     "^type(\n\\(  \\([^\n)]\\|.)\\|\n[^)]\\)*\\)\n)")
                    (caml-types-hcons (match-string 1) table)))
          (setq accu ())
          (while (and stack
                      (caml-types-pos-contains l-cnum r-cnum (car stack)))
            (setq accu (cons (car stack) accu))
            (setq stack (cdr stack)))
          (let* ((left-pos (vector l-file l-line l-bol l-cnum))
                 (right-pos (vector r-file r-line r-bol r-cnum))
                 (node (caml-types-make-node left-pos right-pos type-info
                                             accu)))
            (setq stack (cons node stack))))))
    (if (null stack)
        (error "no annotations found for this source file")
      (let* ((left-pos (elt (car (last stack)) 0))
             (right-pos (elt (car stack) 1)))
        (if (null (cdr stack))
            (car stack)
          (caml-types-make-node left-pos right-pos () (nreverse stack)))))))

(defun caml-types-not-in-file (l-file r-file target-file)
  (or (and (not (string= l-file target-file))
           (not (string= l-file "")))
      (and (not (string= r-file target-file))
           (not (string= r-file "")))))

(defun caml-types-make-node (left-pos right-pos type-info children)
  (let ((result (make-vector (+ 3 (length children)) ()))
        (i 3))
    (aset result 0 left-pos)
    (aset result 1 right-pos)
    (aset result 2 type-info)
    (while children
      (aset result i (car children))
      (setq children (cdr children))
      (setq i (1+ i)))
    result))

(defun caml-types-pos-contains (l-cnum r-cnum node)
  (and (<= l-cnum (elt (elt node 0) 3))
       (>= r-cnum (elt (elt node 1) 3))))

(defun caml-types-find-location (targ-pos curr node)
  (if (not (caml-types-pos-inside targ-pos node))
      curr
    (if (elt node 2)
        (setq curr node))
    (let ((i (caml-types-search node targ-pos)))
      (if (and (> i 3)
               (caml-types-pos-inside targ-pos (elt node (1- i))))
          (caml-types-find-location targ-pos curr (elt node (1- i)))
        curr))))

; trouve le premier fils qui commence apres la position
; ou (length node) si tous commencent avant
(defun caml-types-search (node pos)
  (let ((min 3)
        (max (length node))
        med)
    (while (< min max)
      (setq med (/ (+ min max) 2))
      (if (caml-types-pos<= (elt (elt node med) 0) pos)
          (setq min (1+ med))
        (setq max med)))
    min))

(defun caml-types-pos-inside (pos node)
  (let ((left-pos (elt node 0))
        (right-pos (elt node 1)))
    (and (caml-types-pos<= left-pos pos)
         (caml-types-pos> right-pos pos))))

(defun caml-types-find-interval (buf targ-pos node)
  (let ((nleft (elt node 0))
        (nright (elt node 1))
        (left ())
        (right ())
        i)
    (cond
     ((not (caml-types-pos-inside targ-pos node))
      (if (not (caml-types-pos<= nleft targ-pos))
          (setq right nleft))
      (if (not (caml-types-pos> nright targ-pos))
          (setq left nright)))
     (t
      (setq left nleft
            right nright)
      (setq i (caml-types-search node targ-pos))
      (if (< i (length node))
          (setq right (elt (elt node i) 0)))
      (if (> i 3)
          (setq left (elt (elt node (1- i)) 1)))))
     (cons (if left
               (caml-types-get-pos buf left)
             (with-current-buffer buf (point-min)))
           (if right
               (caml-types-get-pos buf right)
             (with-current-buffer buf (point-max))))))


;; Warning: these comparison functions are not symmetric.
;; The first argument determines the format:
;; when its file component is empty, only the cnum is compared.

(defun caml-types-pos<= (pos1 pos2)
  (let ((file1 (elt pos1 0))
        (line1 (elt pos1 1))
        (bol1 (elt pos1 2))
        (cnum1 (elt pos1 3))
        (file2 (elt pos2 0))
        (line2 (elt pos2 1))
        (bol2 (elt pos2 2))
        (cnum2 (elt pos2 3)))
    (if (string= file1 "")
        (<= cnum1 cnum2)
      (and (string= file1 file2)
           (or (< line1 line2)
               (and (= line1 line2)
                    (<= (- cnum1 bol1) (- cnum2 bol2))))))))

(defun caml-types-pos> (pos1 pos2)
  (let ((file1 (elt pos1 0))
        (line1 (elt pos1 1))
        (bol1 (elt pos1 2))
        (cnum1 (elt pos1 3))
        (file2 (elt pos2 0))
        (line2 (elt pos2 1))
        (bol2 (elt pos2 2))
        (cnum2 (elt pos2 3)))
    (if (string= file1 "")
        (> cnum1 cnum2)
      (and (string= file1 file2)
           (or (> line1 line2)
               (and (= line1 line2)
                    (> (- cnum1 bol1) (- cnum2 bol2))))))))

(defun caml-types-get-pos (buf pos)
  (save-excursion
    (set-buffer buf)
    (goto-line (elt pos 1))
    (forward-char (- (elt pos 3) (elt pos 2)))
    (point)))

; find-file-read-only-noselect seems to be missing from emacs...
(defun caml-types-find-file (name)
  (let (buf)
  (cond
   ((setq buf (get-file-buffer name))
    (unless (verify-visited-file-modtime buf)
      (if (buffer-modified-p buf)
          (find-file-noselect name)
        (with-current-buffer buf (revert-buffer t t)))
      ))
   ((and (file-readable-p name)
         (setq buf (find-file-noselect name)))
     (with-current-buffer buf (toggle-read-only 1))
     )
   (t
    (error "No annotation file. You should compile with option \"-dtypes\"."))
    )
  buf))

(defun caml-types-mouse-ignore (event)
  (interactive "e")
  nil)

(defun caml-types-time ()
  (let ((time (current-time)))
     (+ (* (mod (cadr time) 1000) 1000)
                  (/ (cadr (cdr time)) 1000))))

(defun caml-types-explore (event)
  "Explore type annotations by mouse dragging.

The expression under the mouse is highlighted and its type is displayed 
in the minibuffer, until the move is released, much as `caml-types-show-type'.
The function uses two overlays. 

 . One overlay delimits the largest region whose all subnodes 
   are well-typed. 
 . Another overlay delimits the current node under the mouse (whose type
   annotation is beeing displayed).
"
  (interactive "e")
  (set-buffer (window-buffer (caml-event-window event)))
  (let* ((target-buf (current-buffer))
         (target-file (file-name-nondirectory (buffer-file-name)))
         (type-file (concat (file-name-sans-extension (buffer-file-name))
                            ".annot"))
         (target-line) (target-bol)
         target-pos
         Left Right limits cnum node mes type
         region
         (window (caml-event-window event))
         target-tree
         (speed 100)
         (last-time (caml-types-time))
         (original-event event)
         )
    (select-window window)
    (unwind-protect
        (progn
          (caml-types-preprocess type-file)
          (setq target-tree caml-types-annotation-tree)
          (setq caml-types-buffer (get-buffer-create caml-types-buffer-name))
          ;; (message "Drag the mouse to explore types")
          (unwind-protect
              (caml-track-mouse
               (while event
                 (cond
                  ;; we ignore non mouse events 
                  ((caml-ignore-event-p event))
                  ;; we stop when the original button is released
                  ((caml-release-event-p original-event event)
                   (setq event nil))
                  ;; we scroll when the motion is outside the window
                  ((and (caml-mouse-movement-p event)
                        (not (and (equal window (caml-event-window event))
                                  (integer-or-marker-p
                                   (caml-event-point-end event)))))
                   (let* ((win (caml-window-edges window))
                          (top (nth 1 win))
                          (bottom (- (nth 3 win) 1))
                          mouse
                          time
                          )
                     (while (and
                             (caml-sit-for 0 (/ 500 speed))
                             (setq time (caml-types-time)) 
                             (> (- time last-time) (/ 500 speed))
                             (setq mouse (caml-mouse-vertical-position))
                             (or (< mouse top) (>= mouse bottom))
                             )
                       (setq last-time time)
                       (cond
                        ((< mouse top)
                         (setq speed (- top mouse))
                         (condition-case nil
                             (scroll-down 1)
                           (error (message "Beginning of buffer!"))))
                        ((>= mouse bottom)
                         (setq speed (+ 1 (- mouse bottom)))
                         (condition-case nil
                             (scroll-up 1)
                           (error (message "End of buffer!"))))
                        )                         
                       (setq speed (* speed speed))
                       )))
                  ;; main action, when the motion is inside the window
                  ;; or on orginal button down event
                  ((or (caml-mouse-movement-p event)
                       (equal original-event event))
                   (setq cnum (caml-event-point-end event))
                   (if (and region
                            (<= (car region) cnum) (< cnum (cdr region)))
                       ;; mouse remains in outer region
                       nil
                     ;; otherwise, reset the outer region 
                     (setq region
                           (caml-types-typed-make-overlay
                            target-buf (caml-event-point-start event))))
                   (if
                       (and limits
                            (>= cnum (car limits)) (< cnum (cdr limits)))
                       ;; inner region is unchanged
                       nil
                     ;; recompute the inner region and type annotation
                     (setq target-bol
                           (save-excursion
                             (goto-char cnum) (caml-line-beginning-position))
                           target-line (1+ (count-lines (point-min)
                                                        target-bol))
                           target-pos
                           (vector target-file target-line target-bol cnum))
                     (save-excursion
                       (setq node (caml-types-find-location
                                   target-pos () target-tree))
                       (set-buffer caml-types-buffer)
                       (erase-buffer)
                       (cond
                        (node
                         (setq Left
                               (caml-types-get-pos target-buf (elt node 0))
                               Right
                               (caml-types-get-pos target-buf (elt node 1)))
                         (move-overlay
                          caml-types-expr-ovl Left Right target-buf)
                         (setq limits
                               (caml-types-find-interval target-buf
                                                         target-pos node)
                               type (elt node 2))
                         )
                        (t
                         (delete-overlay caml-types-expr-ovl)
                         (setq type "*no type information*")
                         (setq limits
                               (caml-types-find-interval
                                target-buf target-pos target-tree))
                         ))
                       (setq mes (format "type: %s" type))
                       (insert type)
                       ))
                   (message mes)
                   )
                  )
                 ;; we read next event, unless it is nil, and loop back.
                 (if event (setq event (caml-read-event)))
                 )
               )
            ;; delete overlays at end of exploration
            (delete-overlay caml-types-expr-ovl)
            (delete-overlay caml-types-typed-ovl)
            ))
      ;; When an error occurs, the mouse release event has not been read.
      ;; We could wait for mouse release to prevent execution of
      ;; a binding of mouse release, such as cut or paste.
      ;; In most common cases, next event will be the mouse release.
      ;; However, it could also be a key stroke before mouse release.
      ;; Emacs does not allow to test whether mouse is up or down.
      ;; Not sure it is robust to loop for mouse release after an error
      ;; occured, as is done for exploration. 
      ;; So far, we just ignore next event. (Next line also be uncommenting.)
      (if event (caml-read-event))
      )))

(defun caml-types-typed-make-overlay (target-buf pos)
  (interactive "p")
  (let ((start pos) (end pos) len node left right)
      (setq len (length caml-types-annotation-tree))
      (while (> len 3)
        (setq len (- len 1))
        (setq node (aref caml-types-annotation-tree len))
        (if (and (equal target-buf (current-buffer))
                 (setq left (caml-types-get-pos target-buf (elt node 0))
                       right (caml-types-get-pos target-buf (elt node 1)))
                 (<= left pos) (> right pos)
                 )
            (setq start (min start left)
                  end (max end right))
             ))
      (move-overlay caml-types-typed-ovl
                    (max (point-min) (- start 1))
                    (min (point-max) (+ end 1)) target-buf)
    (cons start end)))

(defun caml-types-version ()
  "internal version number of caml-types.el"
  (interactive)
  (message "2")
)

(provide 'caml-types)
