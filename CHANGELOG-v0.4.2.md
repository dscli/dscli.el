# dscli.el v0.4.2 Release Notes

## 🚀 New Features

### 1. Region Content Support for dscli-chat
- **Feature**: When using `C-u M-x dscli-chat` with a region selected, the selected region content is automatically included in the context
- **Smart Handling**: 
  - Empty regions are ignored
  - Whitespace-only regions are ignored
  - Only non-empty, meaningful content is included

### 2. Org-mode Format Optimization
- **Improved Format**: Uses org-mode source blocks instead of markdown code blocks
- **Benefits**:
  - Better syntax highlighting in org-mode buffers
  - Better integration with org-mode features
  - More consistent with the rest of the org-mode interface

### 3. Language-specific Mode Detection
- **Automatic Detection**: Automatically detects the correct org-mode language based on file extension
- **Wide Language Support**: Supports 20+ programming languages including:
  - Emacs Lisp (.el, .elisp)
  - Python (.py)
  - JavaScript (.js)
  - TypeScript (.ts)
  - Go (.go)
  - Rust (.rs)
  - Java (.java)
  - C++ (.cpp, .cc, .cxx)
  - C (.c)
  - Ruby (.rb)
  - PHP (.php)
  - Shell (.sh, .bash)
  - SQL (.sql)
  - HTML (.html, .htm)
  - CSS (.css)
  - JSON (.json)
  - XML (.xml)
  - YAML (.yaml, .yml)
  - TOML (.toml)
  - Markdown (.md, .markdown)
  - Org-mode (.org)
  - Text (.txt, .text)
- **Fallback**: Unknown extensions default to "text" mode

## 📋 Usage Example

```emacs-lisp
;; 1. Select some code
(defun example ()
  "This is an example function."
  (message "Hello, world!"))

;; 2. Use C-u M-x dscli-chat
;; 3. Input buffer will show:
;; Current editing context: [[file:/path/to/file.el::10][file.el:10]]
;;
;; Selected region content:
;; #+begin_src emacs-lisp
;; (defun example ()
;;   "This is an example function."
;;   (message "Hello, world!"))
;; #+end_src
```

## 🔧 Technical Details

### Updated Files
- `dscli.el`: Version bumped to 0.4.2
- `dscli-modules/dscli-main.el`: Version bumped to 0.4.2
- `dscli-modules/dscli-project.el`: Version bumped to 0.4.2
- `dscli-modules/dscli-ui.el`: Version bumped to 0.4.2
- `dscli-modules/dscli-context.el`: New module with context-aware functions

### New Functions
- `dscli--get-current-context`: Gets current editing context
- `dscli--format-context-as-org-link`: Formats context as org-mode link
- `dscli--format-context-for-input`: Formats context for AI input
- `dscli--detect-mode-from-file`: Detects org-mode language from file extension

## 📦 Installation

```emacs-lisp
;; Using quelpa
(quelpa '(dscli :fetcher git :url "https://gitcode.com/dscli/dscli.el.git" :branch "main"))

;; Or manually
(add-to-list 'load-path "/path/to/dscli.el")
(require 'dscli)
```

## 🔗 Links
- **Repository**: https://gitcode.com/dscli/dscli.el
- **Tag**: v0.4.2
- **Previous Version**: v0.4.1

## 🙏 Acknowledgments
Thanks to all contributors and users for their feedback and support!