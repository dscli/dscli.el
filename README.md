# dscli.el

dscli.el - DeepSeek编程助手的Emacs集成。

## 版本信息

当前版本：v0.1 (2026-02-28)

这是一个稳定的初始版本，包含完整的聊天功能和模型选择支持。

## 简介

dscli.el 为 [dscli](https://gitcode.com/dscli/dscli) 命令行工具提供 Emacs 界面，更好地使用 `dscli` 编程助手。

## 设计概述

dscli.el 目前实现以下核心功能：

1. `dscli-chat` 命令：通过 `M-x dscli-chat` 调用
2. 临时输入缓冲区：弹出 org mode 的临时 buffer 等待用户输入
3. 发送机制：用户输入后按 `C-c C-c`，将临时 buffer 的内容作为标准输入传递给 `dscli chat` 命令
4. 输出显示：`dscli chat` 的输出显示在另一个 buffer 中，该 buffer 也开启 org mode
5. 缓冲区管理：临时 buffer 在发送后消失（或隐藏），下次运行时为空
6. 模型选择：支持选择不同的 DeepSeek 模型（如 deepseek-chat, deepseek-reasoner）
7. Org 模式输出：支持使用 `--mode org` 参数获得 Org 模式格式的输出

## 安装与配置

### 1. 安装 dscli 工具：

```bash
go install gitcode.com/dscli/dscli@latest
```

或者参考 [dscli README](../dscli/README.org) 中的其他安装方法。

### 2. 将 dscli.el 添加到 load-path 并加载：

```emacs-lisp
(add-to-list 'load-path "/path/to/dscli.el/directory")
(require 'dscli)
```

### 3. 可选配置：

```emacs-lisp
;; 基本配置
(setq dscli-executable "/path/to/dscli")  ; 如果 dscli 不在 PATH 中
(setq dscli-chat-buffer-name "*dscli-input*")  ; 自定义输入缓冲区名称
(setq dscli-output-buffer-prefix "*dscli-output")  ; 输出缓冲区前缀

;; 模型选择
(setq dscli-chat-model "deepseek-chat")  ; 默认聊天模型
;; (setq dscli-chat-model "deepseek-reasoner")  ; 使用推理模型

;; 输出格式（推荐使用 Org 模式）
(setq dscli-convert-markdown-to-org t)  ; 启用 --mode org 输出

;; 界面选项
(setq dscli-input-window-height 20)  ; 输入窗口高度
(setq dscli-auto-scroll t)  ; 自动滚动输出
```

## 使用方法

1. 启动聊天：`M-x dscli-chat`
2. 输入消息：在出现的临时缓冲区中输入您的问题或消息
3. 发送消息：按 `C-c C-c` 发送消息
4. 查看响应：响应将显示在输出缓冲区中，使用 Org mode 格式，包含水平线分隔符

## 模型选择

dscli.el 支持选择不同的 DeepSeek 模型：

1. `deepseek-chat`：通用聊天模型（默认）
2. `deepseek-reasoner`：推理专用模型，适合复杂问题求解
3. 其他 DeepSeek API 支持的模型

### 设置方法：
- 在配置文件中设置：`(setq dscli-chat-model "deepseek-reasoner")`
- 使用 customize 界面：`M-x customize-group RET dscli RET`
- 临时设置：`(let ((dscli-chat-model "deepseek-reasoner")) (dscli-chat))`

## 实现细节

### 缓冲区管理
- 输入缓冲区：`*dscli-chat-input*`，org mode，发送后自动关闭
- 输出缓冲区：项目特定的缓冲区名称，如 `*dscli-output-project*`，org mode
- 水平线分隔符：在用户消息和 AI 响应之间添加 `-----` 分隔线

### 进程通信
- 使用 Emacs 的 `start-process` 创建子进程
- 通过标准输入将用户消息传递给 `dscli chat --model <model-name>`
- 输出直接显示在输出缓冲区中，支持 Org 模式格式

### 键盘绑定
- `C-c C-c`：发送当前输入缓冲区的消息
- `C-c C-k`：取消输入会话
- 输出缓冲区中的 `C-c C-c`：中断当前进程

### 输出格式
- 默认启用 `--mode org` 参数，获得 Org 模式格式的输出
- 可通过设置 `dscli-convert-markdown-to-org` 为 `nil` 禁用

## 示例输出格式

```
* dscli-chat: 2026-02-28 10:30:00
用户的问题或消息内容...

-----

DeepSeek 的响应内容...

** 二级标题
- 列表项1
- 列表项2

** 代码示例
#+begin_src python
print("Hello, World!")
#+end_src
```

## 未来扩展方向

1. 历史记录：保存和加载聊天历史
2. 会话管理：支持多轮对话上下文
3. 其他子命令：集成 `dscli models`、`dscli balance` 等功能
4. 错误处理：更完善的错误提示和恢复机制
5. 自定义模板：预定义的消息模板
6. 异步处理：更好的异步响应处理

## 注意事项

1. 需要先安装并配置 dscli 工具
2. 确保 `DEEPSEEK_API_KEY` 环境变量已正确设置
3. 输出格式基于 dscli 的 `--mode org` 参数
4. 模型选择需要相应的 API 权限

## 许可证

Apache License 2.0（同 dscli 项目）

## 贡献指南

欢迎贡献！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与开发。

## 变更历史

详见 [CHANGELOG.md](CHANGELOG.md) 文件。