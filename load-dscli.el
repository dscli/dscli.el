;;; load-dscli.el --- Simple loader for dscli development -*- lexical-binding: t; -*-

;; Simple script to load dscli from development directory
;; Author: Nan Jun Jie <nanjunjie@139.com>

;; Add paths
(add-to-list 'load-path (file-name-directory load-file-name))
(add-to-list 'load-path (expand-file-name "dscli-modules" (file-name-directory load-file-name)))

;; Load modules
(require 'dscli-all)
(require 'dscli)

;; Configure basic settings (only if variables exist)
(when (boundp 'dscli-auto-save-output)
  (setq dscli-auto-save-output t))

(when (boundp 'dscli-save-on-process-end)
  (setq dscli-save-on-process-end t))

(when (boundp 'dscli-save-on-buffer-kill)
  (setq dscli-save-on-buffer-kill t))

;; Set keybindings
(global-set-key (kbd "C-c d") 'dscli)
(global-set-key (kbd "C-c C-d") 'dscli-quick)
(global-set-key (kbd "C-c C-s") 'dscli-manual-save-output)

(message "dscli loaded successfully! Use C-c d to start, C-c C-s to save output.")