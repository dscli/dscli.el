;;; use-package-example.el --- Example use-package configuration for dscli.el

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat, configuration

;; This file provides example use-package configurations for dscli.el.
;; use-package is now built into Emacs and is the recommended way to
;; configure packages.

;;; Commentary:

;; Example use-package configurations for dscli.el
;;
;; dscli.el provides an Emacs interface for dscli, a command-line tool
;; for interacting with DeepSeek API.
;;
;; Main features:
;; - dscli-chat: Interactive chat with DeepSeek
;; - Project-specific chat sessions
;; - Waiting animation support
;; - Configurable model, database, and history settings

;;; Code:

;; ============================================================================
;; Basic use-package configuration
;; ============================================================================

(use-package dscli
  :ensure nil  ; Not available on MELPA, load from local path
  :load-path "~/path/to/dscli.el/directory"  ; Adjust this path
  :commands (dscli-chat)
  :bind (("C-c d c" . dscli-chat)
         ("C-c d n" . dscli-new-chat))
  :config
  ;; Basic configuration
  (setq dscli-executable "dscli")  ; Path to dscli executable
  (setq dscli-timeout-seconds 30)  ; Timeout for dscli response
  
  ;; UI configuration
  (setq dscli-input-window-height 20)  ; Height of input window
  (setq dscli-auto-scroll t)           ; Auto-scroll output buffer
  
  ;; Output formatting
  (setq dscli-convert-markdown-to-org t)  ; Convert Markdown to Org mode
  (setq dscli-disable-color t)            ; Disable color for Org mode
  
  ;; Advanced configuration (added by maintainer)
  (setq dscli-verbose nil)      ; Enable verbose output (debug mode)
  (setq dscli-histsize 50)      ; History size for chat sessions
  (setq dscli-chat-model "deepseek-chat")  ; Model to use
  
  ;; Database configuration
  (setq dscli-db-path "~/.dscli/custom.db")  ; Custom database path
  
  ;; Customize key bindings in output buffer
  (with-eval-after-load 'dscli
    (define-key dscli-output-mode-map (kbd "C-c C-r") 'dscli-retry-last)
    (define-key dscli-output-mode-map (kbd "C-c C-e") 'dscli-export-chat)))


;; ============================================================================
;; Advanced use-package configuration with lazy loading
;; ============================================================================

(use-package dscli
  :ensure nil
  :load-path "~/path/to/dscli.el/directory"
  :commands (dscli-chat dscli-new-chat dscli-export-chat)
  :bind (("C-c d c" . dscli-chat)
         ("C-c d n" . dscli-new-chat)
         ("C-c d e" . dscli-export-chat))
  :init
  ;; Settings that should be set before the package loads
  (setq dscli-verbose t)  ; Enable verbose mode for debugging
  
  :config
  ;; Settings that should be set after the package loads
  ;; Project-specific configuration
  (setq dscli-output-buffer-prefix "*dscli-chat-")
  
  ;; Model selection based on project type
  (defun my-dscli-model-selector ()
    "Select model based on project type."
    (cond
     ((string-match-p "\\.py\\'" (or (buffer-file-name) ""))
      "deepseek-coder")
     ((string-match-p "\\.go\\'" (or (buffer-file-name) ""))
      "deepseek-coder")
     ((string-match-p "\\.js\\'" (or (buffer-file-name) ""))
      "deepseek-coder")
     (t "deepseek-chat")))
  
  ;; Override model selection
  (advice-add 'dscli-get-model :override
              (lambda () (my-dscli-model-selector)))
  
  ;; Custom output buffer setup
  (defun my-dscli-output-setup ()
    "Custom setup for dscli output buffer."
    (when (derived-mode-p 'org-mode)
      (org-indent-mode 1)
      (visual-line-mode 1)))
  
  (add-hook 'dscli-output-mode-hook 'my-dscli-output-setup))


;; ============================================================================
;; Minimal use-package configuration
;; ============================================================================

(use-package dscli
  :ensure nil
  :load-path "~/path/to/dscli.el/directory"
  :commands dscli-chat
  :bind ("C-c d" . dscli-chat)
  :config
  ;; Only essential settings
  (setq dscli-convert-markdown-to-org t)
  (setq dscli-disable-color t))


;; ============================================================================
;; Configuration with customization interface
;; ============================================================================

(use-package dscli
  :ensure nil
  :load-path "~/path/to/dscli.el/directory"
  :commands dscli-chat
  
  :custom
  ;; Use :custom for variables that should be customizable via M-x customize
  (dscli-executable "dscli")
  (dscli-timeout-seconds 30)
  (dscli-input-window-height 20)
  (dscli-auto-scroll t)
  (dscli-convert-markdown-to-org t)
  (dscli-disable-color t)
  (dscli-verbose nil)
  (dscli-histsize 50)
  (dscli-chat-model "deepseek-chat")
  (dscli-db-path "~/.dscli/custom.db")
  
  :config
  ;; Additional configuration after custom variables are set
  (message "dscli configured with use-package"))


;; ============================================================================
;; Complete reference of all customizable variables
;; ============================================================================

;; dscli.el provides the following customizable variables:

;; 1. Basic Configuration:
;;    - dscli-executable: Path to dscli executable (default: "dscli")
;;    - dscli-chat-buffer-name: Name of temporary input buffer (default: "*dscli-chat-input*")
;;    - dscli-output-buffer-prefix: Prefix for project-specific output buffers (default: "*dscli-output")
;;    - dscli-input-window-height: Height of input window in lines (default: 20)
;;    - dscli-timeout-seconds: Timeout for dscli response (default: 30)
;;    - dscli-auto-scroll: Auto-scroll output buffer (default: t)

;; 2. Output Formatting:
;;    - dscli-convert-markdown-to-org: Convert Markdown to Org mode (default: t)
;;    - dscli-disable-color: Disable color output for Org mode (default: t)

;; 3. Advanced Configuration (added by maintainer):
;;    - dscli-verbose: Enable verbose/debug output (default: nil)
;;    - dscli-db-path: Custom database file path (default: nil, uses dscli default)
;;    - dscli-histsize: History size for chat sessions (default: nil, uses dscli default)
;;    - dscli-chat-model: DeepSeek model to use (default: nil, uses dscli default)

;; 4. Usage Examples:
;;    ;; Set model for coding projects
;;    (setq dscli-chat-model "deepseek-coder")
;;
;;    ;; Enable verbose mode for debugging
;;    (setq dscli-verbose t)
;;
;;    ;; Use custom database location
;;    (setq dscli-db-path "~/.config/dscli/chat.db")
;;
;;    ;; Limit history to 20 messages
;;    (setq dscli-histsize 20)
;;
;;    ;; Disable Markdown to Org conversion
;;    (setq dscli-convert-markdown-to-org nil)
;;
;;    ;; Enable color output
;;    (setq dscli-disable-color nil)

;; 5. Project-specific Configuration:
;;    Each project can have independent dscli sessions with different settings.
;;    The output buffer name includes the project directory name for isolation.

;;; use-package-example.el ends here