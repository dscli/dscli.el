;;; test-waiting-animation.el --- Test waiting animation -*- lexical-binding: t; -*-

;; 设置加载路径
(add-to-list 'load-path (expand-file-name "."))
(add-to-list 'load-path (expand-file-name "dscli-modules"))

;; 加载配置和动画模块
(require 'dscli-config)
(require 'dscli-animation)

(defun test-waiting-animation ()
  "测试等待动画功能"
  (let ((test-buffer (get-buffer-create "*dscli-waiting-test*")))
    (with-current-buffer test-buffer
      (erase-buffer))
    
    (message "=== 测试等待动画处理 ===")
    
    ;; 测试动画间隔获取
    (message "\n1. 测试动画间隔获取:")
    (let ((default-interval (dscli--get-animation-interval)))
      (message "默认间隔: %s 秒" default-interval))
    
    ;; 测试配置变量设置
    (message "\n2. 测试配置变量设置:")
    (setq dscli-animation-interval 0.5)
    (let ((interval (dscli--get-animation-interval)))
      (message "dscli-animation-interval=0.5 间隔: %s 秒" interval))
    
    (setq dscli-animation-interval 1.0)
    (let ((interval (dscli--get-animation-interval)))
      (message "dscli-animation-interval=1.0 间隔: %s 秒" interval))
    
    ;; 恢复默认值
    (setq dscli-animation-interval 0.3)
    
    ;; 测试3: 处理等待开始标记
    (message "\n3. 测试等待开始标记:")
    (let ((output "Some text before\n<!-- DS-CLI-WAITING-START -->\nMore text"))
      (with-current-buffer test-buffer
        (erase-buffer))
      (set-buffer test-buffer)
      (let ((processed (dscli-process-output-with-animation output)))
        (message "原始输出: %S" output)
        (message "处理后输出: %S" processed)
        (message "等待动画是否激活: %s" (dscli-is-animation-active-p))))
    
    ;; 测试4: 处理等待进度标记
    (message "\n4. 测试等待进度标记:")
    (let ((output "<!-- DS-CLI-WAITING-PROGRESS:3 -->"))
      (set-buffer test-buffer)
      (let ((processed (dscli-process-output-with-animation output)))
        (message "原始输出: %S" output)
        (message "处理后输出: %S" processed)))
    
    ;; 测试5: 处理等待状态标记
    (message "\n5. 测试等待状态标记:")
    (let ((output "<!-- DS-CLI-WAITING-STATUS:progress=10 -->"))
      (set-buffer test-buffer)
      (let ((processed (dscli-process-output-with-animation output)))
        (message "原始输出: %S" output)
        (message "处理后输出: %S" processed)))
    
    ;; 测试6: 处理等待完成标记
    (message "\n6. 测试等待完成标记:")
    (let ((output "<!-- DS-CLI-WAITING-COMPLETED -->"))
      (set-buffer test-buffer)
      (let ((processed (dscli-process-output-with-animation output)))
        (message "原始输出: %S" output)
        (message "处理后输出: %S" processed)))
    
    ;; 测试7: 处理等待取消标记
    (message "\n7. 测试等待取消标记:")
    (let ((output "<!-- DS-CLI-WAITING-CANCELLED -->"))
      (set-buffer test-buffer)
      (let ((processed (dscli-process-output-with-animation output)))
        (message "原始输出: %S" output)
        (message "处理后输出: %S" processed)))
    
    ;; 测试8: 处理等待超时标记
    (message "\n8. 测试等待超时标记:")
    (let ((output "<!-- DS-CLI-WAITING-TIMEOUT -->"))
      (set-buffer test-buffer)
      (let ((processed (dscli-process-output-with-animation output)))
        (message "原始输出: %S" output)
        (message "处理后输出: %S" processed)))
    
    ;; 测试9: 处理等待结束标记
    (message "\n9. 测试等待结束标记:")
    (let ((output "<!-- DS-CLI-WAITING-END -->"))
      (set-buffer test-buffer)
      (let ((processed (dscli-process-output-with-animation output)))
        (message "原始输出: %S" output)
        (message "处理后输出: %S" processed)
        (message "等待动画是否激活: %s" (dscli-is-animation-active-p))))
    
    ;; 测试10: 完整流程测试
    (message "\n10. 完整流程测试:")
    (let ((output "开始对话\n<!-- DS-CLI-WAITING-START -->\n正在思考\n<!-- DS-CLI-WAITING-PROGRESS:1 -->\n<!-- DS-CLI-WAITING-PROGRESS:2 -->\n<!-- DS-CLI-WAITING-STATUS:progress=2 -->\n<!-- DS-CLI-WAITING-END -->\n<!-- DS-CLI-WAITING-COMPLETED -->\n思考完成"))
      (with-current-buffer test-buffer
        (erase-buffer))
      (set-buffer test-buffer)
      (let ((processed (dscli-process-output-with-animation output)))
        (message "原始输出长度: %d" (length output))
        (message "处理后输出长度: %d" (length processed))
        (message "处理后输出: %S" processed)))
    
    ;; 清理
    (dscli-cleanup-animation)
    (kill-buffer test-buffer)
    
    (message "\n=== 测试完成 ===")))

(defun test-animation-interval-config ()
  "测试动画间隔配置功能"
  (message "=== 测试动画间隔配置 ===")
  
  (message "\n配置示例:")
  (message "1. 设置动画间隔为0.5秒:")
  (message "   (setq dscli-animation-interval 0.5)")
  (setq dscli-animation-interval 0.5)
  (message "   动画间隔: %s秒" (dscli--get-animation-interval))
  
  (message "\n2. 设置动画间隔为1秒:")
  (message "   (setq dscli-animation-interval 1.0)")
  (setq dscli-animation-interval 1.0)
  (message "   动画间隔: %s秒" (dscli--get-animation-interval))
  
  (message "\n3. 设置动画间隔为0.1秒（最快）:")
  (message "   (setq dscli-animation-interval 0.1)")
  (setq dscli-animation-interval 0.1)
  (message "   动画间隔: %s秒" (dscli--get-animation-interval))
  
  (message "\n4. 无效值测试（小于0.1）:")
  (message "   (setq dscli-animation-interval 0.05)")
  (setq dscli-animation-interval 0.05)
  (message "   动画间隔: %s秒（自动调整为0.1秒）" (dscli--get-animation-interval))
  
  (message "\n5. 负值测试:")
  (message "   (setq dscli-animation-interval -1)")
  (setq dscli-animation-interval -1)
  (message "   动画间隔: %s秒（自动调整为0.1秒）" (dscli--get-animation-interval))
  
  (message "\n6. 恢复默认值:")
  (message "   (setq dscli-animation-interval 0.3)")
  (setq dscli-animation-interval 0.3)
  (message "   默认动画间隔: %s秒" (dscli--get-animation-interval))
  
  (message "\n=== 配置测试完成 ==="))

;; 运行测试
(test-waiting-animation)
(test-animation-interval-config)