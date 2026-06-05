# dscli.el

dscli.el — DeepSeek Programming Assistant integration for Emacs.

## Version

Current version: v0.4.5 (2026-05-16)

## Introduction

dscli.el provides an Emacs interface for the [dscli](https://github.com/dscli/dscli) command-line tool, letting you use the DeepSeek programming assistant seamlessly within Emacs.

## Core Features

1. **`dscli-chat`**: Interactive DeepSeek chat (`M-x dscli-chat`)
2. **`dscli-fim`**: AI code completion (Fill-in-the-Middle) at point (`M-x dscli-fim`)
3. **Context awareness**: Automatically captures the current editing context (file location + selected region) and sends it to the AI
   - `C-u M-x dscli-chat`: Start chat with context
   - `M-x dscli-copy-context`: Copy editing context to the kill ring for later pasting
4. **Per-project sessions**: Each project has its own independent dscli session — multiple projects can run simultaneously without interference
5. **Streaming output**: Supports real-time streaming output (`dscli-enable-stream`)
6. **Org mode output**: Supports `--mode org` argument, outputting in Org mode format
7. **Markdown conversion**: Built-in Markdown to Org conversion (`dscli-convert-markdown-to-org`)
8. **Auto-save**: Output buffers are automatically saved to file to prevent data loss
9. **Process management**: Robust process termination with emergency kill-all capability

## Installation & Configuration

### Install dscli

First, install the dscli command-line tool:

```bash
git clone https://github.com/dscli/dscli.git
cd dscli
go build -o ~/.local/bin/dscli .
```

Ensure `~/.local/bin` is in your `PATH`, and set your API Key:

```bash
export DEEPSEEK_API_KEY="your-api-key"
```

### Install dscli.el

**Method 1: Manual installation**

```bash
git clone https://github.com/dscli/dscli.el.git ~/.emacs.d/dscli.el
```

Add the following to your Emacs configuration:

```emacs-lisp
(add-to-list 'load-path "~/.emacs.d/dscli.el")
(require 'dscli)
```

**Method 2: use-package**

```emacs-lisp
(use-package dscli
  :defer nil
  :load-path "~/.emacs.d/dscli.el"
  :bind (("C-c c" . dscli-chat)
         ("C-c w" . dscli-copy-context)))
```

### Configuration Options

You can configure via `M-x customize-group RET dscli RET` or by setting variables directly:

#### Basic Configuration

| Variable               | Default     | Description                           |
|------------------------|-------------|---------------------------------------|
| `dscli-executable`     | `"dscli"`   | Path to the dscli executable          |
| `dscli-chat-model`     | `nil`       | Model name, nil uses dscli default    |
| `dscli-db-path`        | `nil`       | Database file path, nil uses dscli default |
| `dscli-histsize`       | `nil`       | Chat history size, nil uses dscli default |
| `dscli-verbose`        | `nil`       | Enable verbose output                 |

#### FIM Completion Configuration

| Variable                         | Default   | Description                                       |
|----------------------------------|-----------|---------------------------------------------------|
| `dscli-fim-model`                | `nil`     | Model for FIM, nil uses dscli default             |
| `dscli-fim-temperature`          | `0.7`     | Sampling temperature (0.0–2.0)                    |
| `dscli-fim-max-tokens`           | `0`       | Max generated tokens (0 = default)                |
| `dscli-fim-stop-words`           | `nil`     | List of stop words                                |
| `dscli-fim-auto-stop`            | `t`       | Auto-derive stop words from suffix to avoid regenerating existing content |
| `dscli-fim-max-suffix-chars`     | `128000`  | Max suffix character count (prevents overly long command-line arguments) |

#### Output Format

| Variable                            | Default | Description                          |
|-------------------------------------|---------|--------------------------------------|
| `dscli-convert-markdown-to-org`     | `t`     | Convert Markdown to Org mode format  |
| `dscli-enable-stream`               | `nil`   | Enable streaming output              |
| `dscli-disable-color`               | `t`     | Disable ANSI color codes (recommended) |
| `dscli-disable-timestamp`           | `t`     | Disable timestamp output             |

#### Interface

| Variable                         | Default                 | Description                              |
|----------------------------------|-------------------------|------------------------------------------|
| `dscli-input-window-height`      | `20`                    | Input window height (lines), nil for default |
| `dscli-auto-scroll`              | `t`                     | Auto-scroll to latest output             |
| `dscli-timeout-seconds`          | `30`                    | Response timeout (seconds)               |
| `dscli-input-buffer-prefix`      | `"*dscli-input"`        | Input buffer name prefix (per project)   |
| `dscli-chat-buffer-name`         | `"*dscli-chat-input*"`  | (Deprecated) Input buffer name           |
| `dscli-output-buffer-prefix`     | `"*dscli-output"`       | Output buffer name prefix (per project)  |
| `dscli-animation-interval`       | `0.3`                   | Waiting animation interval (seconds), minimum 0.1 |

#### Auto-Save

| Variable                             | Default                          | Description                              |
|--------------------------------------|----------------------------------|------------------------------------------|
| `dscli-auto-save-output`             | `t`                              | Whether to auto-save output             |
| `dscli-output-directory`             | `"~/.dscli/outputs/"`            | Output file save directory              |
| `dscli-save-on-process-end`          | `t`                              | Save when process ends                  |
| `dscli-save-on-buffer-kill`          | `t`                              | Save when buffer is closed              |
| `dscli-save-on-emacs-exit`           | `t`                              | Save all outputs on Emacs exit          |
| `dscli-max-backup-files`             | `100`                            | Max backup files per project, nil for unlimited |
| `dscli-output-filename-template`     | `"{project}/{date}-{time}.org"`  | Filename template                       |
| `dscli-enable-incremental-save`      | `nil`                            | Incremental save (only save new content) |

The filename template supports the following placeholders: `{project}`, `{date}`, `{time}`, `{buffer}`, `{random}`.

### Emacs Built-in Editor

dscli.el automatically sets the following environment variables when launching the dscli process, no manual configuration required:

- `DS_CLI_USE_EMACS_EDITOR=1` — Enable Emacs built-in editor
- `INSIDE_EMACS=t`, `EMACS=1` — Emacs environment identifier
- `EDITOR=emacsclient` — Editor used by tools like `ask_user`

To override (e.g., use a different editor), set `process-environment` in your configuration.

## Usage

### Basic Usage

| Operation           | Command / Shortcut              | Description                         |
|---------------------|---------------------------------|-------------------------------------|
| Start chat          | `M-x dscli-chat`                | Open input buffer                   |
| Start with context  | `C-u M-x dscli-chat`            | Include current file and selection context |
| Send message        | `C-c C-c` (input buffer)        | Send content to DeepSeek            |
| Cancel input        | `C-c C-k` (input buffer)        | Close input buffer                  |
| Interrupt process   | `C-c C-c` (output buffer)       | Stop the running dscli process      |
| New session         | `C-c C-n` (output buffer)       | Start a new chat from output buffer |
| Emergency kill      | `M-x dscli-emergency-kill-all`  | Kill all dscli processes ("nuclear option") |

> ⚠️ **Note**: `C-c C-c` has different meanings in the input and output buffers — "Send" in the input buffer and "Interrupt process" in the output buffer. Be aware of which buffer is active to avoid unintended actions.

### FIM Code Completion

`dscli-fim` uses the DeepSeek FIM (Fill-in-the-Middle) model for code completion.

| Operation               | Command                      | Description                                    |
|-------------------------|------------------------------|------------------------------------------------|
| Complete at point       | `M-x dscli-fim`              | Send code before and after point, insert result at point |
| Replace region          | `C-u M-x dscli-fim`          | Replace selected region with AI completion     |

**How it works**:
- Content before point is sent as **prefix**
- Content after point is sent as **suffix**
- The model completes the missing middle portion and inserts it at point
- Lines ending with `}`, `#+end_src`, ` ``` ` etc. in the suffix automatically become **stop words**, preventing the model from regenerating existing closing blocks. When no explicit delimiter is present (translation, writing), paragraph boundaries `\n\n` act as a brake. You can add custom stop words via `dscli-fim-stop-words`, or set `dscli-fim-auto-stop` to `nil` to disable automatic derivation.

**Typical scenario**:
```go
func calculateSum(numbers []int) int {
    // cursor here → M-x dscli-fim
}
// ↓ AI completes function body ↓
func calculateSum(numbers []int) int {
    sum := 0
    for _, n := range numbers {
        sum += n
    }
    return sum
}
```

### Editing Context Features

dscli.el provides powerful editing context awareness, letting the AI know about the file you are editing and the code you have selected.

#### `dscli-copy-context`

Copies the current editing context to the kill ring in the following format:
- File location (Org mode link)
- Selected region content (`#+begin_src` block with language syntax highlighting)

```
M-x dscli-copy-context             → Copy current context (replace top of kill ring)
C-u M-x dscli-copy-context         → Append to previous context (accumulate multiple files)
```

**Typical workflow**:
1. Select a function in `file-a.el` → `M-x dscli-copy-context`
2. Select related code in `file-b.go` → `C-u M-x dscli-copy-context` (append)
3. Switch to the dscli input buffer → `C-y` (paste all context)
4. Type your question → `C-c C-c` (send)

Configuration example (binding to `C-c w`):

```emacs-lisp
(use-package dscli
  :bind
  ("C-c w" . dscli-copy-context))
```

#### `dscli-chat` with Prefix Argument

```emacs-lisp
C-u M-x dscli-chat   → Automatically fill current editing context into the input buffer
```

### Auto-Save

- Saves when process ends normally
- Saves when process exits abnormally
- Saves when closing output buffer

Save path: `~/.dscli/outputs/<project-name>/<date>-<time>.org`

Manual operations:
- `M-x dscli-enable-auto-save`: Enable auto-save
- `M-x dscli-disable-auto-save`: Disable auto-save
- `M-x dscli-manual-save-output`: Manually save current output

## Development & Testing

```bash
# Run integration tests
emacs --batch -l integration-test.el
```

### Module Development

Each module has a clear responsibility boundary:
1. Define related functionality in the module
2. Declare public interfaces with `;;;###autoload`
3. Load all modules in order from the `dscli.el` main file

Reloading:
```
M-x dscli-reload   → Reload all modules (for development)
```

## License

Apache License 2.0

## Author

Nan Jun Jie <nanjunjie@139.com>
