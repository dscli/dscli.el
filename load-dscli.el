;;; load-dscli.el --- Quick load script for dscli development -*- lexical-binding: t; -*-

;; Quick load script for dscli.el development
;; Usage: M-x load-file RET ~/src/gitcode.com/dscli/dscli.el/load-dscli.el

;; Set up load path
(let ((dscli-dir "/home/nanjj/src/gitcode.com/dscli/dscli.el"))
  (add-to-list 'load-path dscli-dir)
  (add-to-list 'load-path (expand-file-name "dscli-modules" dscli-dir)))
;; Load all dscli modules
(require 'dscli-all)

;; Also load the main entry point
(require 'dscli)
(setq dscli-save-on-process-end t)
(setq dscli-save-on-buffer-kill t)

;; Enable debug mode if needed
;; (setq dscli-debug-mode t)

;; Set up keybindings
(global-set-key (kbd "C-c d") 'dscli)
(global-set-key (kbd "C-c C-d") 'dscli-quick)

;; Message
(message "dscli loaded successfully! Use C-c d to start.")

(provide 'load-dscli)