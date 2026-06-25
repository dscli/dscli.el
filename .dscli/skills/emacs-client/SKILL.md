---
name: emacs-client
description: 通过 emacsclient --eval 查询和控制运行中的 Emacs 实例。封装 describe-function、describe-variable、list-funcs、reload 等常用操作。
keywords:
- emacs
- emacsclient
- eval
- describe
- reload
- debug
---

# emacs-client

通过 `emacsclient --eval` 查询和控制运行中的 Emacs 实例。

## 原则

利用 Emacs 独有的运行时能力（查文档、读状态、改状态），不替代文件 I/O 工具。

## 脚本

| 脚本 | 用途 |
|------|------|
| `describe-func.sh <name>` | 查看函数完整文档（signature + docstring + keybindings） |
| `describe-var.sh <name>` | 查看变量文档和当前值 |
| `list-funcs.sh [prefix]` | 列出指定前缀的函数（默认 `dscli-`） |
| `reload.sh` | 重载 dscli.el |
| `eval.sh <expr>` | 执行任意 Elisp 表达式（兜底） |

## 使用方式

```bash
# 查函数文档
bash ~/.dscli/skills/emacs-client/scripts/describe-func.sh dscli-send-message

# 查变量文档
bash ~/.dscli/skills/emacs-client/scripts/describe-var.sh dscli-chat-buffer-name

# 列出所有 dscli- 函数
bash ~/.dscli/skills/emacs-client/scripts/list-funcs.sh

# 列出指定前缀
bash ~/.dscli/skills/emacs-client/scripts/list-funcs.sh org-

# 重载
bash ~/.dscli/skills/emacs-client/scripts/reload.sh

# 任意表达式
bash ~/.dscli/skills/emacs-client/scripts/eval.sh "(emacs-version)"
```

## 注意事项

- emacsclient 自动通过 `$XDG_RUNTIME_DIR/emacs/server` 连接（Emacs 29+ 默认位置），
  已不再使用 `~/.emacs.d/server/server`（旧版本兼容）
- 不适合文件读写（用 `write_file` / `read_file` 工具）
- `describe-func.sh` 和 `describe-var.sh` 输出 *Help* buffer 的完整格式化内容，比 `(documentation ...)` 更丰富
- `emacsclient --eval` **不要**加 `-c` 参数。`-c` 创建新帧（用于文件编辑），
  而 `--eval` 只需要在后台执行表达式并返回值，加 `-c` 会导致不必要的帧创建
  且在某些构建（如 PGTK/Wayland）上可能阻塞
