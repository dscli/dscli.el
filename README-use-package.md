# dscli.el use-package 配置指南

## 概述

`dscli.el` 是一个 Emacs 包，为 `dscli`（DeepSeek API 命令行工具）提供交互式界面。现在推荐使用 `use-package` 进行配置，因为它是 Emacs 内置的包管理工具。

## 安装

### 1. 克隆仓库
```bash
git clone https://gitcode.com/dscli/dscli.el.git ~/.emacs.d/dscli.el
```

### 2. 基本 use-package 配置

```emacs-lisp
(use-package dscli
  :ensure nil  ; 不在 MELPA 上，从本地加载
  :load-path "~/.emacs.d/dscli.el"  ; 调整为你本地的路径
  :commands (dscli-chat)
  :bind (("C-c d c" . dscli-chat))
  :config
  ;; 基本配置
  (setq dscli-executable "dscli")
  (setq dscli-timeout-seconds 30)
  
  ;; 输出格式
  (setq dscli-convert-markdown-to-org t)  ; 将 Markdown 转换为 Org 模式
  (setq dscli-disable-color t)            ; 禁用颜色输出（Org 模式推荐）
  
  ;; 高级配置
  (setq dscli-verbose nil)      ; 启用详细输出（调试模式）
  (setq dscli-histsize 50)      ; 聊天历史大小
  (setq dscli-chat-model "deepseek-chat")  ; 使用的模型
  (setq dscli-db-path "~/.dscli/custom.db"))  ; 自定义数据库路径
```

## 可定制变量详解

### 1. 基本配置变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `dscli-executable` | `"dscli"` | dscli 可执行文件路径 |
| `dscli-timeout-seconds` | `30` | dscli 响应超时时间（秒） |
| `dscli-input-window-height` | `20` | 输入窗口高度（行数） |
| `dscli-auto-scroll` | `t` | 自动滚动输出缓冲区 |

### 2. 输出格式化变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `dscli-convert-markdown-to-org` | `t` | 将 Markdown 输出转换为 Org 模式格式 |
| `dscli-disable-color` | `t` | 禁用颜色输出（推荐用于 Org 模式） |

### 3. 高级配置变量（由维护者添加）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `dscli-verbose` | `nil` | 启用详细/调试输出 |
| `dscli-db-path` | `nil` | 自定义数据库文件路径 |
| `dscli-histsize` | `nil` | 聊天历史大小限制 |
| `dscli-chat-model` | `nil` | DeepSeek 模型选择 |

## 高级配置示例

### 1. 懒加载配置

```emacs-lisp
(use-package dscli
  :ensure nil
  :load-path "~/.emacs.d/dscli.el"
  :commands (dscli-chat dscli-new-chat)
  :bind (("C-c d c" . dscli-chat)
         ("C-c d n" . dscli-new-chat))
  :init
  ;; 包加载前的设置
  (setq dscli-verbose t)  ; 启用调试模式
  
  :config
  ;; 包加载后的设置
  ;; 根据项目类型选择模型
  (defun my-dscli-model-selector ()
    "根据项目类型选择模型。"
    (cond
     ((string-match-p "\\.py\\'" (or (buffer-file-name) ""))
      "deepseek-coder")
     ((string-match-p "\\.go\\'" (or (buffer-file-name) ""))
      "deepseek-coder")
     (t "deepseek-chat")))
  
  (advice-add 'dscli-get-model :override
              (lambda () (my-dscli-model-selector))))
```

### 2. 使用 :custom 关键字

```emacs-lisp
(use-package dscli
  :ensure nil
  :load-path "~/.emacs.d/dscli.el"
  :commands dscli-chat
  
  :custom
  ;; 这些变量可以通过 M-x customize 界面修改
  (dscli-executable "dscli")
  (dscli-timeout-seconds 30)
  (dscli-convert-markdown-to-org t)
  (dscli-disable-color t)
  (dscli-verbose nil)
  (dscli-histsize 50)
  (dscli-chat-model "deepseek-chat")
  (dscli-db-path "~/.dscli/custom.db")
  
  :config
  ;; 额外的配置
  (message "dscli 已通过 use-package 配置"))
```

### 3. 项目特定配置

```emacs-lisp
(use-package dscli
  :ensure nil
  :load-path "~/.emacs.d/dscli.el"
  :commands dscli-chat
  :config
  ;; 编程项目使用代码模型
  (defun my-project-specific-config ()
    "根据项目类型进行配置。"
    (when (and (projectile-project-p)
               (string-match-p "code" (projectile-project-name)))
      (setq-local dscli-chat-model "deepseek-coder")
      (setq-local dscli-histsize 100)))  ; 编程项目保留更多历史
  
  (add-hook 'projectile-after-switch-project-hook 
            'my-project-specific-config))
```

## 使用场景配置

### 1. 编程助手配置

```emacs-lisp
(use-package dscli
  :ensure nil
  :load-path "~/.emacs.d/dscli.el"
  :commands dscli-chat
  :config
  ;; 编程相关设置
  (setq dscli-chat-model "deepseek-coder")  ; 使用代码模型
  (setq dscli-histsize 100)                 ; 保留更多上下文
  (setq dscli-verbose nil)                  ; 关闭调试输出
  
  ;; 编程相关的键绑定
  (with-eval-after-load 'dscli
    (define-key dscli-output-mode-map (kbd "C-c C-c") 'compile)
    (define-key dscli-output-mode-map (kbd "C-c C-e") 'eval-last-sexp)))
```

### 2. 写作助手配置

```emacs-lisp
(use-package dscli
  :ensure nil
  :load-path "~/.emacs.d/dscli.el"
  :commands dscli-chat
  :config
  ;; 写作相关设置
  (setq dscli-chat-model "deepseek-chat")  ; 使用聊天模型
  (setq dscli-histsize 30)                 ; 适中的历史大小
  (setq dscli-convert-markdown-to-org t)   ; 转换为 Org 模式
  (setq dscli-disable-color t)             ; 禁用颜色
  
  ;; 写作相关的键绑定
  (with-eval-after-load 'dscli
    (define-key dscli-output-mode-map (kbd "C-c C-f") 'fill-paragraph)
    (define-key dscli-output-mode-map (kbd "C-c C-s") 'ispell-buffer)))
```

## 常见问题

### 1. 如何启用调试模式？
```emacs-lisp
(setq dscli-verbose t)  ; 启用详细输出
```

### 2. 如何更改模型？
```emacs-lisp
;; 使用聊天模型
(setq dscli-chat-model "deepseek-chat")

;; 使用代码模型
(setq dscli-chat-model "deepseek-coder")
```

### 3. 如何自定义数据库位置？
```emacs-lisp
(setq dscli-db-path "~/.config/dscli/chat.db")
```

### 4. 如何调整历史大小？
```emacs-lisp
(setq dscli-histsize 20)  ; 保留最近20条消息
```

### 5. 如何禁用 Markdown 转换？
```emacs-lisp
(setq dscli-convert-markdown-to-org nil)  ; 保持原始 Markdown 格式
```

## 键绑定参考

| 快捷键 | 功能 | 缓冲区 |
|--------|------|--------|
| `C-c d c` | 开始新聊天 | 任意 |
| `C-c C-c` | 发送消息 | 输入缓冲区 |
| `C-c C-k` | 取消输入 | 输入缓冲区 |
| `C-c C-c` | 中断进程 | 输出缓冲区 |
| `C-c C-n` | 开始新会话 | 输出缓冲区 |

## 模块化结构

dscli.el 采用模块化设计：
- `dscli.el` - 主文件（72行，只包含加载逻辑）
- `dscli-modules/` - 所有功能模块
  - `dscli-config.el` - 配置变量
  - `dscli-project.el` - 项目管理
  - `dscli-process.el` - 进程管理
  - `dscli-animation.el` - 等待动画
  - `dscli-ui.el` - 用户界面
  - `dscli-main.el` - 主逻辑

这种设计使得代码更易于维护和扩展。

## 更多资源

- 完整文档：`README-modules.md`
- 模块化示例：`use-package-example.el`
- 源代码：`dscli.el` 和 `dscli-modules/` 目录

---

**注意**：确保 `dscli` 命令行工具已正确安装并可在系统路径中找到。