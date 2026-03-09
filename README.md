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
8. 颜色控制：支持 `--no-color` 参数避免 ANSI 颜色代码干扰 Org 模式显示
9. **等待动画**：支持显示等待动画（⏳ Thinking...）和进度指示器

## 安装与配置