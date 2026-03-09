# Changelog

所有对 dscli.el 的重大变更都将记录在此文件中。

## 版本 [v0.2.1] - 2026-03-09

### 新增
- **动画间隔配置**：支持通过环境变量配置等待动画更新频率
  - 通过 `EMACS` 环境变量设置间隔（秒）
  - 通过 `INSIDE_EMACS` 环境变量设置间隔（秒）
  - `EMACS` 环境变量优先级高于 `INSIDE_EMACS`
  - 默认间隔：0.3秒
  - 最小间隔：0.1秒
- **增强的等待动画状态**：支持更多状态标记
  - `<!-- DS-CLI-WAITING-STATUS:text -->`: 显示状态信息
  - `<!-- DS-CLI-WAITING-COMPLETED -->`: 等待完成
  - `<!-- DS-CLI-WAITING-CANCELLED -->`: 等待取消
  - `<!-- DS-CLI-WAITING-TIMEOUT -->`: 等待超时
- **测试工具**：新增完整的动画功能测试
  - `test-waiting-animation.el`: 测试等待动画处理
  - `emacs-animation-example.el`: 演示动画间隔配置

### 变更
- 更新了 `dscli-animation.el` 模块，支持可配置的动画间隔
- 改进了动画处理逻辑，支持更多状态标记
- 更新了文档，添加动画间隔配置说明
- 优化了代码结构，提高可维护性

### 配置示例
```emacs-lisp
;; 动画间隔配置（在Emacs配置文件中设置）
(setenv "EMACS" "1")  ; 1秒间隔
;; 或
(setenv "INSIDE_EMACS" "0.5")  ; 0.5秒间隔

;; 在shell中设置
export EMACS=2  # 2秒间隔
```

### 使用方法
- 动画间隔可以通过环境变量动态配置
- 支持更丰富的等待状态反馈
- 默认动画间隔为0.3秒，可通过环境变量调整

## 版本 [v0.2.0] - 2026-03-09

### 新增
- 模块化架构：将代码拆分为多个独立的模块
  - `dscli-config.el`：配置管理模块
  - `dscli-project.el`：项目管理模块
  - `dscli-process.el`：进程管理模块
  - `dscli-ui.el`：用户界面模块
  - `dscli-animation.el`：动画支持模块
  - `dscli-main.el`：主模块
  - `dscli-all.el`：一键加载所有模块
- 支持并发会话：不同项目可以同时运行独立的dscli会话
- 改进的等待动画：更流畅的进度指示器

### 变更
- 重构了代码结构，提高了可维护性
- 改进了错误处理和用户反馈
- 更新了文档和示例配置
- 统一了版本号到0.2.0

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
- 使用 `M-x dscli-chat` 启动聊天会话
- 支持项目隔离的对话历史
- 支持并发会话管理
- 默认启用 `--no-color` 以避免 ANSI 颜色代码干扰 Org 模式显示

## 版本 [v0.1.3] - 2026-03-03

### 移除
- 移除了 `--continue` 参数支持：不再支持通过空消息继续工具调用或对话
- 移除了 `--abort` 参数支持：不再支持通过输入 `--abort` 放弃工具执行

### 变更
- 简化了 `dscli-send-message` 函数，移除了特殊输入处理逻辑
- 简化了 `dscli--run-chat-command` 函数，移除了 `--abort` 和 `--continue` 参数处理
- 更新了 `dscli-chat` 函数文档，移除了特殊行为说明
- 更新了 README.md 文档，移除了关于继续功能和放弃功能的说明
- 更新了注释，移除了特殊行为说明

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
- 现在只支持正常的消息输入，不再支持特殊输入
- 默认启用 `--no-color` 以避免 ANSI 颜色代码干扰 Org 模式显示

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