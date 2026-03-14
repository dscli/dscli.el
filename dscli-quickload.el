;;; dscli-quickload.el --- Quick load and development utilities for dscli -*- lexical-binding: t; -*-

;; Quick load utilities for dscli.el development
;; Author: Nan Jun Jie <nanjunjie@139.com>

;; ============================================================================
;; Configuration
;; ============================================================================

(defvar dscli-dev-path "/home/nanjj/src/gitcode.com/dscli/dscli.el"
  "Path to dscli development directory.")

(defvar dscli-loaded-p nil
  "Whether dscli is currently loaded.")
(defun dscli-dev-configure ()
  "Configure dscli for development."
  ;; Enable auto-save features (only if variables exist)
  (when (boundp 'dscli-auto-save-output)
    (setq dscli-auto-save-output t))
  
  (when (boundp 'dscli-save-on-process-end)
    (setq dscli-save-on-process-end t))
  
  (when (boundp 'dscli-save-on-buffer-kill)
    (setq dscli-save-on-buffer-kill t))
  
  ;; Development settings
  (when (boundp 'dscli-output-directory)
    (setq dscli-output-directory "~/.dscli/outputs/"))
  
  (when (boundp 'dscli-output-filename-template)
    (setq dscli-output-filename-template "{project}/{date}-{time}.org"))
  ;; Optional: enable debug mode
  ;; (setq dscli-debug-mode t)
  )

;; ============================================================================
;; Core Loading Functions
;; ============================================================================

(defun dscli-load ()
  "Load dscli from development directory."
  (interactive)
  (unless dscli-loaded-p
    (let ((dscli-dir dscli-dev-path))
      ;; Add paths
      (add-to-list 'load-path dscli-dir)
      (add-to-list 'load-path (expand-file-name "dscli-modules" dscli-dir))
      
      ;; Load modules
      (require 'dscli-all)
      (require 'dscli)
      
      ;; Configure for development
      (dscli-dev-configure)
      
      ;; Set flag
      (setq dscli-loaded-p t)
      
      ;; Message
      (message "✅ dscli loaded successfully! Use C-c d to start."))))

(defun dscli-reload ()
  "Reload dscli modules (for development)."
  (interactive)
  (message "🔄 Reloading dscli modules...")
  
  ;; Unload features first
  (when (featurep 'dscli) (unload-feature 'dscli))
  (when (featurep 'dscli-all) (unload-feature 'dscli-all))
  
  ;; Reload
  (setq dscli-loaded-p nil)
  (dscli-load)
  
  (message "✅ dscli reloaded!"))

;; ============================================================================
;; Development Utilities
;; ============================================================================

(defun dscli-open-dev-file ()
  "Open dscli.el main file for editing."
  (interactive)
  (find-file (expand-file-name "dscli.el" dscli-dev-path)))

(defun dscli-open-modules-dir ()
  "Open dscli modules directory."
  (interactive)
  (dired (expand-file-name "dscli-modules" dscli-dev-path)))

(defun dscli-run-tests ()
  "Run dscli tests."
  (interactive)
  (message "Running dscli tests...")
  ;; Add test commands here
  )

(defun dscli-view-saved-files ()
  "View saved output files."
  (interactive)
  (dired "~/.dscli/outputs/"))

;; ============================================================================
;; Auto-load on Demand
;; ============================================================================

(defun dscli-auto-load ()
  "Auto-load dscli when needed."
  (unless dscli-loaded-p
    (dscli-load)))

;; Advise dscli command to auto-load
(defadvice dscli (before auto-load-dscli activate)
  "Auto-load dscli before running."
  (dscli-auto-load))

(defadvice dscli-quick (before auto-load-dscli activate)
  "Auto-load dscli before running quick version."
  (dscli-auto-load))

;; ============================================================================
;; Menu and Mode
;; ============================================================================

(defvar dscli-dev-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c d l") 'dscli-load)
    (define-key map (kbd "C-c d r") 'dscli-reload)
    (define-key map (kbd "C-c d e") 'dscli-open-dev-file)
    (define-key map (kbd "C-c d m") 'dscli-open-modules-dir)
    (define-key map (kbd "C-c d t") 'dscli-run-tests)
    (define-key map (kbd "C-c d v") 'dscli-view-saved-files)
    map)
  "Keymap for dscli development mode.")

(define-minor-mode dscli-dev-mode
  "Minor mode for dscli development."
  :lighter " dscli-dev"
  :keymap dscli-dev-mode-map
  :global t
  :group 'dscli)

;; ============================================================================
;; Initialization
;; ============================================================================

;; Enable development mode
(dscli-dev-mode 1)

;; Auto-load if configured
;; (dscli-auto-load)

(provide 'dscli-quickload)

;;; dscli-quickload.el ends here