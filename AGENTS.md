# AGENTS.md

This is **dscli.el**, an Emacs Lisp interface for the [dscli](https://github.com/dscli/dscli) command-line AI assistant. It wraps `dscli chat` in Emacs buffers with keybindings, process management, and IDE integration.

## Build, Test, and Lint

```bash
# There is no Makefile — dscli.el is loaded directly by Emacs.
# Byte-compile on the fly:
emacs --batch -L . -L dscli-modules -f batch-byte-compile dscli.el

# Check all modules for warnings and errors:
#   M-x flycheck-mode  (in each buffer, or see dscli-flycheck.el)
# Or via dscli itself:
dscli flycheck dscli-modules/

# Reload during development:
#   M-x dscli-reload
```

**Before committing:**
```bash
dscli flycheck dscli-modules/    # must pass clean
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

- **No external dependencies** beyond Emacs 27.1 — `Package-Requires: ((emacs "27.1"))`.
- **`lexical-binding: t`** on every `.el` file.
- **`dscli--` prefix** for private/internal functions, **`dscli-`** for public API.
- **`declare-function`** to suppress byte-compiler warnings for cross-module calls and Org table functions.
- **Process hash table**: `dscli-process.el` maintains a `(buffer . process)` hash to manage multiple concurrent chat sessions. Webchat processes are deliberately NOT registered — they run independently.
- **Dual-process** (GUI + daemon): blocking ops → daemon (`emacsclient --eval`); streaming ops → GUI (`start-process`). Emacs is single-threaded — blocking GUI freezes the editor; blocking daemon is harmless. See `dscli-flycheck-check-file-json` for temp-frame isolation pattern.
- **No ERT tests yet** — quality relies on flycheck (byte-compiler warnings) and manual testing.
