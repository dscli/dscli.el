# dscli.el

dscli.el - DeepSeek编程助手的Emacs集成。

## 版本信息

当前版本：v0.4.0 (2026-03-09)

这是一个稳定的版本，包含完整的聊天功能、模型选择支持、模块化架构、可配置的等待动画、Emacs内置编辑器支持和改进的进程管理。

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
8. 颜色控制：支持 `--no-color` 参数避免 ANSI 颜色代码干扰 Org 模式显示
9. **等待动画**：支持显示等待动画（⏳ Thinking...）和进度指示器
10. **动画间隔配置**：支持通过 Emacs 自定义变量配置动画更新频率
10. **动画间隔配置**：支持通过 Emacs 自定义变量配置动画更新频率
11. **Emacs内置编辑器支持**：通过环境变量启用Emacs内置编辑器
12. **改进的进程管理**：彻底解决进程二次杀不死问题，提供更健壮的进程终止逻辑
## 安装与配置

### 安装 dscli

首先需要安装 dscli 命令行工具：

```bash
git clone https://gitcode.com/dscli/dscli.git
cd dscli/dscli
go build -o ~/.local/bin/dscli .
```

### 安装 dscli.el

1. 克隆仓库：
```bash
git clone https://gitcode.com/dscli/dscli.el.git
```

2. 将 dscli.el 目录添加到 Emacs 的 load-path：
```emacs-lisp
(add-to-list 'load-path "/path/to/dscli.el")
```

3. 加载 dscli.el：
```emacs-lisp
(require 'dscli)
```

### 配置选项

可以通过 `M-x customize-group RET dscli RET` 配置以下选项：

- `dscli-chat-model`: 选择使用的模型（如 "deepseek-chat"、"deepseek-reasoner"）
- `dscli-db-path`: 数据库文件路径
- `dscli-histsize`: 历史记录大小
- `dscli-verbose`: 启用详细输出
- `dscli-disable-color`: 禁用颜色输出
- `dscli-animation-interval`: 等待动画更新间隔（秒）

### Emacs内置编辑器支持

要启用Emacs内置编辑器，需要设置以下环境变量：

```emacs-lisp
;; 在Emacs配置文件中设置
(setenv "DS_CLI_USE_EMACS_EDITOR" "1")    ; 任意非空值即可
(setenv "INSIDE_EMACS" "t")               ; Emacs环境标识
(setenv "EMACS" "1")                      ; Emacs环境标识
```

**可选检查**：
- 如果设置了 `EDITOR` 或 `VISUAL` 环境变量但不包含"emacs"或"emacsclient"，会发出警告
- 建议将 `EDITOR` 或 `VISUAL` 设置为 `emacs` 或 `emacsclient` 以获得最佳体验
- `dscli-animation-interval`: 等待动画更新间隔（秒）

## 使用说明

### 基本使用

1. 运行 `M-x dscli-chat`
2. 在临时缓冲区中输入问题
3. 按 `C-c C-c` 发送
4. 查看输出缓冲区中的回答

### 等待动画配置

dscli.el 支持可配置的等待动画间隔。可以通过以下方式配置：

#### 1. 通过 Emacs 配置变量设置

```emacs-lisp
;; 在Emacs配置文件中设置
(setq dscli-animation-interval 0.5)  ; 0.5秒间隔
```

#### 2. 通过 customize 界面配置

1. 运行 `M-x customize-group RET dscli RET`
2. 找到 `dscli-animation-interval` 选项
3. 设置值（如 0.5 表示 0.5 秒间隔）
4. 点击 Apply and Save 保存配置

#### 3. 配置说明

- **默认值**：0.3秒
- **最小值**：0.1秒（防止过快更新）
- **建议范围**：0.1秒到2.0秒
- **无效值处理**：如果设置的值小于0.1秒，会自动调整为0.1秒

### 键绑定

### 改进的进程管理

v0.4.0 改进了进程管理，彻底解决了进程二次杀不死的问题：

1. **健壮的进程终止**：
   - 先发送中断信号 (`interrupt-process`)
   - 等待0.1秒让进程响应
   - 如果进程还在运行，再强制终止 (`delete-process`)
   - 总是清理哈希表中的进程条目

2. **更好的用户反馈**：
   ```emacs-lisp
   ;; 现在提供更清晰的反馈
   (dscli-interrupt-process)
   ;; => "dscli process stopped in buffer '*dscli-chat*'"
   ;; 或 "No active dscli process found in buffer '*dscli-chat*'"
   ```

3. **进程状态检查**：
   ```emacs-lisp
   ;; 检查是否有活动进程
   (dscli-has-active-process-p buffer-name)
   ;; => t 或 nil
   ```
- `C-c C-k`: 取消输入会话

#### 输出缓冲区
- `C-c C-c`: 中断当前进程（如果正在运行）
- `C-c C-n`: 从输出缓冲区开始新的聊天会话

## 模块化架构

dscli.el 采用模块化设计，便于维护和扩展：

- `dscli-main.el`: 主入口点和用户界面
- `dscli-config.el`: 配置管理
- `dscli-project.el`: 项目管理
- `dscli-process.el`: 进程管理
- `dscli-ui.el`: 用户界面组件
- `dscli-animation.el`: 等待动画处理

## 等待动画功能

### 功能特性

1. **动画显示**：在等待响应时显示旋转的等待指示器
2. **进度更新**：支持进度标记更新动画状态
3. **状态反馈**：显示等待状态（开始、进行中、完成、取消、超时）
4. **可配置间隔**：通过配置变量调整动画更新频率
5. **自动清理**：动画结束后自动清理资源

### 支持的标记

dscli 输出中的特殊标记会被处理并显示为动画：

- `<!-- DS-CLI-WAITING-START -->`: 开始等待动画
- `<!-- DS-CLI-WAITING-PROGRESS:N -->`: 更新进度到N
- `<!-- DS-CLI-WAITING-STATUS:text -->`: 显示状态信息
- `<!-- DS-CLI-WAITING-END -->`: 结束等待动画
- `<!-- DS-CLI-WAITING-COMPLETED -->`: 等待完成
- `<!-- DS-CLI-WAITING-CANCELLED -->`: 等待取消
- `<!-- DS-CLI-WAITING-TIMEOUT -->`: 等待超时

## 开发与测试

### 运行测试

```bash
# 测试等待动画功能
emacs --batch -l test-waiting-animation.el

# 测试动画间隔配置
emacs --batch -l emacs-animation-example.el

# 集成测试
emacs --batch -l integration-test.el
```

### 模块开发

每个模块都有清晰的职责边界：
1. 在模块中定义相关功能
2. 通过autoload声明公开接口
3. 在主文件中加载所有模块

## 许可证

Apache License 2.0

## 作者

Nan Jun Jie <nanjunjie@139.com>