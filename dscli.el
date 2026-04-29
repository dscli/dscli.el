;;; dscli.el --- DeepSeek CLI Emacs interface -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Nan Jun Jie

;; Author: Nan Jun Jie <nanjunjie@139.com>
;; Keywords: deepseek, ai, chat
;; Version: 0.4.2
;; Package-Requires: ((emacs "27.1"))

;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; dscli.el — Emacs interface for the dscli command-line tool.
;;
;; Quick start:
;;   M-x dscli-chat           → Start a chat session
;;   M-x dscli-copy-context   → Copy editing context to kill ring
;;
;; use-package example (recommended):
;;   (use-package dscli
;;     :load-path "~/src/gitcode.com/dscli/dscli.el"
;;     :commands (dscli-chat dscli-copy-context)
;;     :bind (("C-c c" . dscli-chat)
;;            ("C-c w" . dscli-copy-context)))
;;
;; The :commands keyword ensures M-x completion works before first use.
;;
;; Configuration: M-x customize-group RET dscli RET

;;; Code:

;; Add module directory to load path
(add-to-list 'load-path
             (expand-file-name "dscli-modules"
                               (file-name-directory load-file-name)))

;; Load all modules in dependency order
(require 'dscli-config)
(require 'dscli-project)
(require 'dscli-process)
(require 'dscli-ui)
(require 'dscli-animation)
(require 'dscli-main)
(require 'dscli-save)
(require 'dscli-context)

;; ── Reload (for development) ────────────────────────────────────────

(defun dscli-reload ()
  "Reload all dscli modules and reinitialize configuration."
  (interactive)
  (message "Reloading dscli modules...")
  (let ((saved-config
         (delq nil
               (list
                (when (boundp 'dscli-auto-save-output)
                  (cons 'dscli-auto-save-output dscli-auto-save-output))
                (when (boundp 'dscli-save-on-process-end)
                  (cons 'dscli-save-on-process-end dscli-save-on-process-end))
                (when (boundp 'dscli-save-on-buffer-kill)
                  (cons 'dscli-save-on-buffer-kill dscli-save-on-buffer-kill))
                (when (boundp 'dscli-output-directory)
                  (cons 'dscli-output-directory dscli-output-directory))
                (when (boundp 'dscli-output-filename-template)
                  (cons 'dscli-output-filename-template
                        dscli-output-filename-template))))))
    (let* ((dscli-dir (file-name-directory
                       (or load-file-name (buffer-file-name) default-directory)))
           (module-dir (expand-file-name "dscli-modules" dscli-dir))
           (module-files '("dscli-config.el" "dscli-project.el" "dscli-process.el"
                           "dscli-ui.el" "dscli-animation.el" "dscli-main.el"
                           "dscli-save.el" "dscli-context.el")))
      (message "Reloading from: %s" dscli-dir)
      (dolist (file module-files)
        (let ((full-path (expand-file-name file module-dir)))
          (if (file-exists-p full-path)
              (progn (message "  %s" file) (load full-path nil t t))
            (message "  Not found: %s" full-path))))
      (dolist (config saved-config)
        (when config (set (car config) (cdr config))))
      (when (fboundp 'dscli--init-save-hooks)
        (run-with-idle-timer 0.1 nil #'dscli--init-save-hooks))
      (message "dscli reloaded!"))))

(provide 'dscli)
;;; dscli.el ends here
