# AGENTS.md

This is **dscli.el**, an Emacs Lisp interface for the [dscli](https://github.com/dscli/dscli) command-line AI assistant. It wraps `dscli chat` in Emacs buffers with keybindings, process management, and IDE integration.

## Build, Test, and Lint

```bash
# Byte-compile after ANY .el change — Emacs prefers .elc over .el,
# and a stale .elc silently shadows newer source (*.elc is gitignored).
make compile          # byte-compile all sources (dscli-modules/*.el then dscli.el)
make clean            # remove all .elc artifacts (fallback: source-only loading)

# Check all modules for warnings and errors:
#   M-x flycheck-mode  (in each buffer, or see dscli-flycheck.el)
# Or via dscli itself:
dscli flycheck dscli-modules/

# Quick batch regression check of key functions:
emacs -Q --batch -L . -L dscli-modules \
  --eval '(progn (require (quote dscli-main)) \
                 (message "%s" (dscli--get-animation-interval)) \
                 (dscli-version))'

# Reload during development:
#   M-x dscli-reload
```

**Before committing:**
```bash
make compile                       # .elc must be in sync with source; must emit ZERO warnings
dscli flycheck dscli-modules/      # must pass clean
```

## Architecture

Entry point: `dscli.el` → adds `dscli-modules/` to `load-path` → `(require 'dscli-main)`.

`dscli-main.el` loads all other modules in dependency order and provides the public API.

### Module Map

| Module | Purpose |
|--------|---------|
| `dscli.el` | Entry point, `load-path` setup, `dscli-project-directory` |
| `dscli-config.el` | `defcustom` variables (model, API key, histsize, etc.) |
| `dscli-project.el` | Input buffer creation, header-line, keybindings |
| `dscli-process.el` | dscli subprocess management, hash table, sentinel |
| `dscli-main.el` | Public API (`dscli-chat`, `dscli-send-message`, etc.) |
| `dscli-ui.el` | Output formatting, font-lock, Org table alignment |
| `dscli-animation.el` | Animated dots during API calls |
| `dscli-save.el` | Session serialization / deserialization |
| `dscli-context.el` | Editing context extraction (`dscli-copy-context`) |
| `dscli-fim.el` | Fill-in-the-Middle code completion |
| `dscli-flycheck.el` | Emacs-side flycheck integration for dscli |

### Key Design Decisions

- **No external dependencies** beyond Emacs 27.1 — `Package-Requires: ((emacs "27.1"))`. flycheck is an *optional* runtime dependency: `dscli-flycheck.el` loads it with `(require 'flycheck nil t)` and forward-declares its API (`defvar` + `declare-function`), so byte-compilation stays clean without flycheck installed.
- **`lexical-binding: t`** on every `.el` file.
- **`dscli--` prefix** for private/internal functions, **`dscli-`** for public API.
- **Cross-module references**: functions via `declare-function`, variables via a bare `(defvar dscli-...)` forward declaration. `make compile` byte-compiles modules in alphabetical order, so a module referencing a later module's variable (e.g. `dscli-animation.el` → `dscli-animation-interval` in `dscli-config.el`) needs the declaration even though runtime load order is fine.
- **Docstrings must satisfy checkdoc**: first line is a complete sentence, ≤ 80 columns, literal single quotes escaped as `\='`, and no docstring line may start with a bare `(`.
- **Version sync**: `;; Version:` headers in every file AND the hardcoded string in `dscli-version` must match (the v0.5.2 bump missed `dscli-version` once — fixed 2026-08).
- **Process hash table**: `dscli-process.el` maintains a `(buffer . process)` hash to manage multiple concurrent chat sessions. Webchat processes are deliberately NOT registered — they run independently.
- **Dual-process** (GUI + daemon): blocking ops → daemon (`emacsclient --eval`); streaming ops → GUI (`start-process`). Emacs is single-threaded — blocking GUI freezes the editor; blocking daemon is harmless. See `dscli-flycheck-check-file-json` for temp-frame isolation pattern.
- **No ERT tests yet** — quality relies on flycheck (byte-compiler warnings + checkdoc), the `make compile` zero-warning policy, and the batch regression snippet above.
