(set-frame-position (selected-frame) 10 30)

; Let's remove all those nastyt hings
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))

;; Set the fill-column for things like latex to a nice width
(setq-default fill-column 140)

;; Turn iswitch-buffer on
(iswitchb-mode 1)

;; Bind meta-g to goto-line. WHY ISN'T THIS A DEFAULT?!
(global-set-key "\M-g" 'goto-line)

(global-font-lock-mode 1)

;; This sets option as meta key
;; I <3 u david
(setq mac-option-modifier 'meta)

;; Remove C-up and C-down since I never use them and am always hitting
;; then when I don't want to
(global-unset-key (kbd "C-<up>"))
(global-unset-key (kbd "C-<down>"))

;; show regions with different color
(setq transient-mark-mode t)

(setq-default show-trailing-whitespace t)

(require 'tramp)

(require 'epa-file)
(epa-file-enable)

;(autoload 'smalltalk-mode "/opt/local/stow/gnu-smalltalk/share/emacs/site-lisp/smalltalk-mode.elc" "" t)

(autoload 'php-mode "php-mode" "Mode for editing PHP source files")
(add-to-list 'auto-mode-alist '("\\.\\(inc\\|php[s34]?\\)" . php-mode))

(add-to-list 'load-path "~/.emacs-progmode")
;(add-to-list 'load-path "/Applications/Mozart.app/Contents/Resources/share/elisp")
;(require 'oz)

;(setq auto-mode-alist (cons '("\\.py$" . python-mode) auto-mode-alist))
;(setq interpreter-mode-alist (cons '("python" . python-mode)
;                                       interpreter-mode-alist))
;(autoload 'python-mode "python-mode" "Python editing mode." t)
(add-hook 'python-mode-hook
 '(lambda ()
    (local-set-key [(control m)] 'newline-and-indent)
    (setq indent-tabs-mode nil)))

(add-hook 'c-mode-hook
  '(lambda ()
     (local-set-key [(control m)] 'newline-and-indent)
     (setq indent-tabs-mode nil)))

(add-hook 'c++-mode-hook
  '(lambda ()
     (local-set-key [(control m)] 'newline-and-indent)
     (setq indent-tabs-mode nil)))

(add-hook 'java-mode-hook
  '(lambda ()
     (local-set-key [(control m)] 'newline-and-indent)
     (setq indent-tabs-mode nil)))

(add-hook 'ruby-mode-hook
  '(lambda ()
     (local-set-key [(control m)] 'newline-and-indent)
     (setq indent-tabs-mode nil)))

;(autoload 'flex-mode "flex-mode" "Flex Editing" t)

; Erlang stuff
(add-to-list 'load-path "/opt/local/lib/erlang/lib/tools-2.6.7/emacs/")
(setq erlang-root-dir "/opt/local")
(add-to-list 'exec-path "/opt/local")
(require 'erlang-start)
;(require 'kaz-erlang)
(require 'two-mode-mode)
;; Start it as a node
(setq inferior-erlang-machine "/opt/local/bin/erl")
(setq inferior-erlang-machine-options '("-sname" "emacs"))

(add-hook 'erlang-mode-hook
  '(lambda ()
     (local-set-key [(control m)] 'newline-and-indent)
     (setq indent-tabs-mode nil)
     (setq erlang-compile-function 'kaz-erlang-compile)
     (define-key erlang-mode-map "\C-c!" 'erlang-shell-display)
))

; Haskell mode
(load "~/.emacs-progmode/haskell-mode-2.1/haskell-site-file")
(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indent)


; Lets you do outline mode in literate haskell
;; (set (make-local-variable 'outline-regexp)
;;      "^\\([0-9]+\\.[0-9\\.]*\\)")
;; (set (make-local-variable 'outline-level)
;;      (lambda ()
;;        (save-excursion
;; 	 (re-search-forward
;; 	  "^\\([0-9]+\\.[0-9\\.]*\\)" nil t)
;; 	 (length (replace-regexp-in-string "\\([0-9]+\\)" "$1" (match-string 1)))))
     
     

;(add-to-list 'load-path "/usr/local/oz/share/elisp")
;(require 'oz)


; SES stuff
;(add-to-list 'load-path "~/.emacs-progmode/ses21-031130")
;(autoload 'ses-mode "ses.el" "Spreadsheet mode" t)
;(add-to-list 'auto-mode-alist '("\\.ses$" . ses-mode))

; Caml Mode
;; (add-to-list 'load-path "~/.emacs-progmode/caml-mode")
;; (setq auto-mode-alist
;;       (cons '("\\.ml[iylp]?$" . caml-mode) auto-mode-alist))
;; (autoload 'caml-mode "caml" "Major mode for editing Caml code." t)
;; (autoload 'run-caml "inf-caml" "Run an inferior Caml process." t)
;; (require 'caml-font)

; Tuareg Mode
(add-to-list 'load-path "~/.emacs-progmode/tuareg-2.0.2")
(setq auto-mode-alist (cons '("\\.ml\\w?" . tuareg-mode) auto-mode-alist))
(autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
(autoload 'camldebug "camldebug" "Run the Caml debugger" t)


(add-hook 'tuareg-mode-hook
          '(lambda ()
             ;; font locking
             (setq tuareg-font-lock-keywords
                   (cons (list "\\<perform\\>"
                               0 'tuareg-font-lock-governing-face nil nil)
                         tuareg-font-lock-keywords))
             ;; indentation
             (setq tuareg-keyword-regexp
                   (concat tuareg-keyword-regexp "\\|\\<perform\\>"))
             (setq tuareg-matching-keyword-regexp
                   (concat tuareg-matching-keyword-regexp "\\|\\<perform\\>"))
             (setq tuareg-keyword-alist
                   (cons '("perform" . tuareg-default-indent)
                         tuareg-keyword-alist))))

; Add spell checking to LaTeX
(add-hook 'LaTeX-mode-hook 'flyspell-mode)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(safe-local-variable-values (quote ((allout-layout . t))))
 '(tuareg-in-indent 0))

; Scala
;(add-to-list 'load-path "/Users/orbitz/bin/scala/misc/scala-tool-support/emacs")
;(require 'scala-mode-auto)


;; (add-to-list 'load-path "~/.emacs-progmode/ess-5.4")
;; (require 'ess-site)

(add-to-list 'load-path "~/.emacs-progmode/clojure-mode")
(require 'clojure-mode)

; Matlab
(autoload 'matlab-mode "~/.emacs-progmode/matlab.el" "Enter Matlab mode." t) 
(setq auto-mode-alist (cons '("\\.m\\'" . matlab-mode) auto-mode-alist)) 

(require 'rst)
(setq auto-mode-alist
      (append '(("\\.txt$" . rst-mode)
                ("\\.rst$" . rst-mode)
                ("\\.rest$" . rst-mode)) auto-mode-alist))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Changes in appearance ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq default-frame-alist
      `((cursor-color . "green")
  (background-color . "black")
  (foreground-color . "white")))

(setq initial-frame-alist 
  '((background-mode . dark)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
