;;; emacs-animation-example.el --- Example of configuring dscli animation interval -*- lexical-binding: t; -*-

;; 设置加载路径
(add-to-list 'load-path (expand-file-name "."))
(add-to-list 'load-path (expand-file-name "dscli-modules"))

;; 加载配置和动画模块
(require 'dscli-config)
(require 'dscli-animation)

(defun demo-emacs-animation-config ()
  "演示如何配置Emacs动画间隔"
  (message "=== Emacs动画间隔配置演示 ===")
  
  (message "\n1. 默认配置:")
  (message "   默认动画间隔: %s秒" (dscli--get-animation-interval))
  
  (message "\n2. 通过配置变量设置:")
  (setq dscli-animation-interval 0.5)
  (message "   dscli-animation-interval=0.5 -> 动画间隔: %s秒" (dscli--get-animation-interval))
  
  (setq dscli-animation-interval 1.0)
  (message "   dscli-animation-interval=1.0 -> 动画间隔: %s秒" (dscli--get-animation-interval))
  
  ;; 恢复默认值
  (setq dscli-animation-interval 0.3)
  
  (message "\n3. 实际使用示例:")
  (message "   ;; 在Emacs配置文件中设置:")
  (message "   (setq dscli-animation-interval 0.5)  ; 0.5秒间隔")
  (message "   ;; 或者使用customize界面:")
  (message "   M-x customize-group RET dscli RET")
  
  (message "\n4. 通过customize界面配置:")
  (message "   1. 运行 M-x customize-group RET dscli RET")
  (message "   2. 找到 dscli-animation-interval 选项")
  (message "   3. 设置值（如0.5表示0.5秒间隔）")
  (message "   4. 点击 Apply and Save 保存配置")
  
  (message "\n5. 在dscli.el中使用:")
  (message "   ;; 动画会自动根据配置调整间隔")
  (message "   (dscli-chat)  ; 使用配置的间隔显示等待动画")
  
  (message "\n=== 演示完成 ==="))

(defun test-animation-with-different-intervals ()
  "测试不同间隔的动画效果"
  (message "=== 测试不同动画间隔 ===")
  
  (let ((intervals '(0.1 0.3 0.5 1.0 2.0)))
    (dolist (interval intervals)
      (message "\n测试间隔: %s秒" interval)
      (setq dscli-animation-interval interval)
      (let ((actual-interval (dscli--get-animation-interval)))
        (message "   实际间隔: %s秒" actual-interval)
        (when (not (equal interval actual-interval))
          (message "   注意: 实际间隔被调整为 %s秒 (最小0.1秒)" actual-interval))))
    (setq dscli-animation-interval 0.3))
  
  (message "\n=== 间隔测试完成 ==="))

;; 运行演示
(demo-emacs-animation-config)
(test-animation-with-different-intervals)

(provide 'emacs-animation-example)