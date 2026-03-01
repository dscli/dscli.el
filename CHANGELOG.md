# Changelog

所有对 dscli.el 的重大变更都将记录在此文件中。

## 版本 [v0.1.2] - 2026-02-28

### 新增
- 支持 `--abort` 参数：当输入为 `--abort` 时使用，用于放弃工具执行
- 完善了特殊输入的处理逻辑

### 变更
- 更新了 `dscli-send-message` 函数，支持 `--abort` 的特殊显示
- 更新了 `dscli-chat` 函数文档，添加 `--abort` 说明
- 更新了 README.md 文档，添加放弃功能说明

### 配置示例
```emacs-lisp
;; 基本配置
(setq dscli-executable "dscli")
(setq dscli-chat-model "deepseek-chat") ; 或 "deepseek-reasoner"

;; 转换选项
(setq dscli-convert-markdown-to-org t)

;; 颜色控制（推荐启用以避免 ANSI 代码干扰 Org 模式）
(setq dscli-disable-color t)

;; 界面选项
(setq dscli-input-window-height 20)
(setq dscli-auto-scroll t)
```

### 使用方法
- 输入 `--abort` 将使用 `--abort` 参数放弃工具执行
- 发送空消息（直接按 `C-c C-c` 不输入内容）将使用 `--continue` 参数
- 默认启用 `--no-color` 以避免 ANSI 颜色代码干扰 Org 模式显示

## 版本 [v0.1.1] - 2026-02-28

### 新增
- 支持 `--continue` 参数：当输入为空消息时自动使用，用于继续工具调用或对话
- 支持 `--no-color` 参数：默认启用以避免 ANSI 颜色代码干扰 Org 模式显示
- 新增 `dscli-disable-color` 自定义变量控制颜色输出

### 变更
- 更新了文档，详细说明新特性
- 改进了命令构建逻辑，支持多个可选参数
- 优化了状态提示信息，显示使用的参数

### 配置示例
```emacs-lisp
;; 基本配置
(setq dscli-executable "dscli")
(setq dscli-chat-model "deepseek-chat") ; 或 "deepseek-reasoner"

;; 转换选项
(setq dscli-convert-markdown-to-org t)

;; 颜色控制（推荐启用以避免 ANSI 代码干扰 Org 模式）
(setq dscli-disable-color t)

;; 界面选项
(setq dscli-input-window-height 20)
(setq dscli-auto-scroll t)
```

### 使用方法
- 发送空消息（直接按 `C-c C-c` 不输入内容）将使用 `--continue` 参数
- 默认启用 `--no-color` 以避免 ANSI 颜色代码干扰 Org 模式显示

## 版本 [v0.1] - 2026-02-23

### 新增
- 完整的 dscli 聊天集成功能
- 支持模型选择：通过 `dscli-chat-model` 自定义变量配置
- 支持 `deepseek-chat` 和 `deepseek-reasoner` 等模型
- Org mode 格式输出，包含水平线分隔符
- Markdown 到 Org 模式的转换支持（内置 markdown2org）
- 可配置的转换选项

### 修复
- 修复了 `dscli--run-chat-command` 函数中的括号不匹配错误
- 改进了错误处理和用户反馈

### 变更
- 改进了用户界面，显示当前使用的模型和转换状态
- 优化了命令构建逻辑，支持 `--model` 参数
- 增强了状态提示信息

### 特性
- `M-x dscli-chat`：启动聊天会话
- 临时输入缓冲区（org mode）
- 实时输出显示（org mode）
- 支持项目隔离的对话历史
- 可中断的进程处理

### 配置示例
```emacs-lisp
;; 基本配置
(setq dscli-executable "dscli")
(setq dscli-chat-model "deepseek-chat") ; 或 "deepseek-reasoner"

;; 转换选项
(setq dscli-convert-markdown-to-org t)
(setq dscli-convert-markdown-to-org t)  ; 启用内置markdown2org转换

;; 界面选项
(setq dscli-input-window-height 20)
(setq dscli-auto-scroll t)
```

### 使用方法
1. 安装 dscli 工具：`go install gitcode.com/dscli/dscli@latest`
2. 设置环境变量：`DEEPSEEK_API_KEY`
3. 加载 dscli.el 并运行：`M-x dscli-chat`

这是一个稳定的初始版本，适合生产使用。