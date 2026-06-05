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
- **No ERT tests yet** — quality relies on flycheck (byte-compiler warnings) and manual testing.

## Chat Command Flow

```
M-x dscli-chat
  → dscli-project.el creates input buffer (bottom window)
  → User types message, presses C-c C-c or C-c C-s
  → dscli-main.el calls dscli --input via start-process
  → dscli-process.el sentinel reads output, inserts into output buffer
  → dscli-ui.el formats output (font-lock, Org tables)
```

### Keybindings (in input buffer)

| Key | Command |
|-----|---------|
| `C-c C-c` | `dscli-send-message` — send input, wait for response |
| `C-c C-s` | `dscli-webchat-send-message` — send via webchat (non-blocking) |
| `C-c C-k` | `dscli-cancel-input` — kill input buffer |
| `C-c C-g` | `dscli-interrupt-process` — kill dscli subprocess |

## Code Style

- **All files start with** `;;; <name>.el --- <desc> -*- lexical-binding: t; -*-`
- **`;;;###autoload`** cookie on every public command (`dscli-chat`, `dscli-version`, `dscli-reload`, etc.)
- **Docstrings**: every public function has one. Use imperative mood ("Return...", "Start..."). No need to restate parameter names in docstring body.
- **`declare-function`**: place right before the `require` or first call site, e.g.:
  ```elisp
  (declare-function dscli-project-directory "dscli")
  ```
- **Organize code in sections** with `;; ── Section Name ──` separators (box-drawing characters).
- **Prefer `pcase` over `cond`** for pattern matching when the structure is clear.
- **Avoid `cl-lib`** unless necessary — keep it plain Elisp.

## Version Bump

Use the `version-bump` skill:
```
dscli skill version-bump
```
It bumps the version in `dscli.el`, commits, tags, and pushes automatically.

## AI Assistant Notes

When working on dscli.el:

1. **Always run `dscli flycheck dscli-modules/`** before committing — clean pass is mandatory.
2. **New public functions** need `;;;###autoload` cookie + docstring.
3. **Cross-module calls** from `dscli-main.el` into other modules: add a `declare-function` form before `require`.
4. **Org table alignment**: if you modify output formatting, `dscli--align-org-tables-in-buffer` uses `org-table-align` — ensure `declare-function` covers it.
5. **Process management**: don't register short-lived processes in the hash table; only long-running chat sessions.
6. **Copyright header**: all new files must include the Apache 2.0 license header matching existing files.
