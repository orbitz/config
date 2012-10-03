;;; To use set the value of erlang-compile-function to
;;; kaz-erlang-compile.  Then C-c C-k will compile the 
;;; source file using options specified in the alist, or
;;; at the very least, kaz-erlang-compile-options.  If
;;; invoked with a prefix arg, you will be prompted for 
;;; the compile options to use.  These options will be 
;;; used as the default for all files in the current 
;;; source directory.

(require 'cl)

(defvar kaz-erlang-compile-options "report"
  "*Default options to pass to erlang compile if there are no project
specific overrides.")

(defvar kaz-erlang-compile-options-alist '()
  "*Alist of compile options that should be used on a per project
basis.  A project is determined by the base directory of the current
file being compiled.  The CAR is the source directory for which the
options apply, and the CDR is a string of options to pass to the
erlang compiler.  For example:

  (add-to-list 'kaz-erlang-compile-options-alist
               '(\"/some/src/dir/\" . \"report, hipe\"))
")

(defvar kaz-erlang-history '()
  "History for erlang compile minibuffer commands.")

(defun kaz-update-alist (key value alist)
  "Update element of alist with new (key . value)"
  (cons (cons key value)
        (remove* key alist :test 'equal :key 'car)))

(defun kaz-erlang-read-options (default)
  "Read a list of options prompting the user with DEFAULT."
  (read-string (format "Compile options [%s]: " default)
               nil
               'kaz-erlang-history
               default))

(defun kaz-erlang-compile (&optional arg)
  "*Compile current buffer using default options specified in
`kaz-erlang-compile-options-alist'.  If no entry exists in the alist,
the value of `kaz-erlang-compile-options' is used instead.  When ARG
is specified, prompt the user for a list of options to use for the
current project."
  (interactive "P")
  (let* ((dir (file-name-directory (buffer-file-name)))
         (noext (file-name-sans-extension (buffer-file-name)))
         (out (expand-file-name (concat dir "../ebin/")))
         (inc (expand-file-name (concat dir "../inc/")))
         (options (or (assoc-default dir kaz-erlang-compile-options-alist)
                      kaz-erlang-compile-options)))
    (when arg
      (setq options (kaz-erlang-read-options options))
      (setq kaz-erlang-compile-options-alist
            (kaz-update-alist dir
                              options
                              kaz-erlang-compile-options-alist)))
    (kaz-erlang-compile-with-command
     (format (concat "code:add_path(\"%s\"), c(\"%s\", ["
                     (when options (concat options " ,"))
                     "{outdir, \"%s\"}, {i, \"%s\"}]).")
             out
             noext
             out
             inc))))

(defun kaz-erlang-compile-with-command (command)
  "Compile the file in the current buffer using COMMAND."
  (save-some-buffers)
  (or (inferior-erlang-running-p)
      (save-excursion
        (inferior-erlang)))
  (or (inferior-erlang-running-p)
      (error "Error starting inferior Erlang shell"))
  (inferior-erlang-display-buffer)
  (inferior-erlang-wait-prompt)
  (let ((end (inferior-erlang-send-command command nil)))
    (inferior-erlang-wait-prompt)
    (save-excursion
      (set-buffer inferior-erlang-buffer)
      (setq compilation-error-list nil)
      (set-marker compilation-parsing-end end))
    (setq compilation-last-buffer inferior-erlang-buffer)))

(provide 'kaz-erlang)
