# dscli.el

dscli.el - DeepSeek编程助手的Emacs集成。

## 版本信息

当前版本：v0.4.2 (2026-04-27)

## 简介

dscli.el 为 [dscli](https://github.com/nanjunjie/dscli) 命令行工具提供
Emacs 界面，让你在 Emacs 中无缝使用 DeepSeek 编程助手。

## 核心功能

1. **`dscli-chat`**：交互式 DeepSeek 聊天（`M-x dscli-chat`）
2. **上下文感知**：自动获取当前编辑上下文（文件位置 + 选中区域），发送给 AI
   - `C-u M-x dscli-chat`：带上下文启动聊天
   - `M-x dscli-copy-context`：复制编辑上下文到 kill ring，方便后续粘贴
3. **独立项目会话**：每个项目拥有独立的 dscli 会话，多项目可同时运行互不干扰
4. **流式输出**：支持流式实时输出（`dscli-enable-stream`）
5. **Org 模式输出**：支持 `--mode org` 参数，输出为 Org 模式格式
6. **Markdown 转换**：内置 Markdown 到 Org 的转换（`dscli-convert-markdown-to-org`）
7. **自动保存**：输出缓冲区自动保存到文件，防止数据丢失
8. **进程管理**：健壮的进程终止，支持紧急杀死所有进程

## 安装与配置

### 安装 dscli

首先安装 dscli 命令行工具：

```bash
git clone https://github.com/nanjunjie/dscli.git
cd dscli
go build -o ~/.local/bin/dscli .
```

确保 `~/.local/bin` 在 `PATH` 中，并设置 API Key：
```bash
export DEEPSEEK_API_KEY="your-api-key"
```

### 安装 dscli.el

**方式一：手动安装**

```bash
git clone https://github.com/nanjunjie/dscli.el.git ~/.emacs.d/dscli.el
```

在 Emacs 配置中添加：
```emacs-lisp
(add-to-list 'load-path "~/.emacs.d/dscli.el")
(require 'dscli)
```

**方式二：use-package**

```emacs-lisp
(use-package dscli
  :load-path "~/.emacs.d/dscli.el"
  :bind
  ("C-c w" . dscli-copy-context))
```

### 配置选项

可通过 `M-x customize-group RET dscli RET` 或直接设置变量：

#### 基本配置
| 变量               | 默认值    | 说明                                                                         |
|--------------------|-----------|------------------------------------------------------------------------------|
| `dscli-executable` | `"dscli"` | dscli 可执行文件路径                                                         |
| `dscli-chat-model` | `nil`     | 模型选择（如 `"deepseek-chat"`、`"deepseek-reasoner"`），nil 使用 dscli 默认 |
| `dscli-db-path`    | `nil`     | 数据库文件路径，nil 使用 dscli 默认                                          |
| `dscli-histsize`   | `nil`     | 对话历史大小，nil 使用 dscli 默认                                            |
| `dscli-verbose`    | `nil`     | 是否启用详细输出                                                             |

#### 输出格式
| 变量                            | 默认值 | 说明                       |
|---------------------------------|--------|----------------------------|
| `dscli-convert-markdown-to-org` | `t`    | Markdown 转 Org 模式格式   |
| `dscli-enable-stream`           | `nil`  | 启用流式输出               |
| `dscli-disable-color`           | `t`    | 禁用 ANSI 颜色代码（推荐） |
| `dscli-disable-timestamp`       | `t`    | 禁用时间戳输出             |

#### 界面
| 变量                         | 默认值                 | 说明                               |
|------------------------------|------------------------|------------------------------------|
| `dscli-input-window-height`  | `20`                   | 输入窗口高度（行数），nil 使用默认 |
| `dscli-auto-scroll`          | `t`                    | 自动滚动到最新输出                 |
| `dscli-timeout-seconds`      | `30`                   | 等待响应超时（秒）                 |
| `dscli-animation-interval`   | `0.3`                  | 等待动画更新间隔（秒，最小 0.1）   |
| `dscli-chat-buffer-name`     | `"*dscli-chat-input*"` | 输入缓冲区名称                     |
| `dscli-output-buffer-prefix` | `"*dscli-output"`      | 输出缓冲区名称前缀                 |

#### 自动保存
| 变量                             | 默认值                          | 说明                             |
|----------------------------------|---------------------------------|----------------------------------|
| `dscli-auto-save-output`         | `t`                             | 是否自动保存输出                 |
| `dscli-output-directory`         | `"~/.dscli/outputs/"`           | 输出文件保存目录                 |
| `dscli-save-on-process-end`      | `t`                             | 进程结束时保存                   |
| `dscli-save-on-buffer-kill`      | `t`                             | 缓冲区关闭时保存                 |
| `dscli-save-on-emacs-exit`       | `t`                             | Emacs 退出时保存所有输出         |
| `dscli-max-backup-files`         | `100`                           | 每个项目最大备份文件数，nil 不限 |
| `dscli-output-filename-template` | `"{project}/{date}-{time}.org"` | 文件名模板                       |
| `dscli-enable-incremental-save`  | `nil`                           | 增量保存（只保存新增内容）       |

文件名模板支持的占位符：`{project}`、`{date}`、`{time}`、`{buffer}`、`{random}`。

### Emacs 内置编辑器

dscli.el 在启动 dscli 进程时自动设置以下环境变量，无需用户手动配置：

- `DS_CLI_USE_EMACS_EDITOR=1` — 启用 Emacs 内置编辑器
- `INSIDE_EMACS=t`、`EMACS=1` — Emacs 环境标识
- `EDITOR=emacsclient` — 供 ask_user 等工具使用的编辑器

如需覆盖（例如使用其他编辑器），可在配置中设置 `process-environment`。

## 使用说明

### 基本使用

| 操作         | 命令/快捷键                    | 说明                            |
|--------------|--------------------------------|---------------------------------|
| 启动聊天     | `M-x dscli-chat`               | 打开输入缓冲区                  |
| 带上下文启动 | `C-u M-x dscli-chat`           | 附带当前文件和选中区域上下文    |
| 发送消息     | `C-c C-c`（输入缓冲区）        | 发送内容到 DeepSeek             |
| 取消输入     | `C-c C-k`（输入缓冲区）        | 关闭输入缓冲区                  |
| 中断进程     | `C-c C-c`（输出缓冲区）        | 停止正在运行的 dscli 进程       |
| 新建会话     | `C-c C-n`（输出缓冲区）        | 从输出缓冲区启动新聊天          |
| 紧急终止     | `M-x dscli-emergency-kill-all` | 杀死所有 dscli 进程（"核选项"） |

> ⚠️ **注意**：`C-c C-c` 在输入和输出缓冲区中含义不同——输入缓冲区中为「发送」，输出缓冲区中为「中断进程」。请确认当前活跃缓冲区，避免误操作。

### 编辑上下文功能

dscli.el 提供强大的编辑上下文感知功能，让 AI 了解你当前正在编辑的文件和选中的代码。

#### `dscli-copy-context`

将当前编辑上下文复制到 kill ring，格式为：
- 文件位置（Org mode 链接）
- 选中区域内容（带语言语法高亮的 `#+begin_src` 块）

```
C-c w             → 复制当前上下文（替换 kill ring 顶部）
C-u C-c w         → 追加到上次上下文（累积多个文件）
```

**典型工作流**：
1. 在 `file-a.el` 中选中一个函数 → `C-c w`
2. 在 `file-b.go` 中选中相关代码 → `C-u C-c w`（追加）
3. 切换到 dscli 输入缓冲区 → `C-y`（粘贴所有上下文）
4. 输入问题 → `C-c C-c`（发送）

配置示例（绑定到 `C-c w`）：
```emacs-lisp
(use-package dscli
  :bind
  ("C-c w" . dscli-copy-context))
```

#### `dscli-chat` 带前缀参数

```emacs-lisp
C-u M-x dscli-chat   → 自动将当前编辑上下文填入输入缓冲区
```

### 自动保存
- 进程正常结束时保存
- 进程异常退出时保存
- 关闭输出缓冲区时保存
- Emacs 退出时保存所有输出缓冲区

保存路径：`~/.dscli/outputs/<项目名>/<日期>-<时间>.org`

手动操作：
- `M-x dscli-enable-auto-save`：启用自动保存
- `M-x dscli-disable-auto-save`：禁用自动保存
- `M-x dscli-manual-save-output`：手动保存当前输出

## 开发与测试

```bash
# 运行集成测试
emacs --batch -l integration-test.el
```

### 模块开发

每个模块都有清晰的职责边界：
1. 在模块中定义相关功能
2. 通过 `;;;###autoload` 声明公开接口
3. 在 `dscli.el` 主文件中按顺序加载所有模块

重新加载：
```
M-x dscli-reload   → 重新加载所有模块（开发时使用）
```

## 许可证

Apache License 2.0

## 作者

Nan Jun Jie <nanjunjie@139.com>