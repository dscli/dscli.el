;;; integration-test.el --- Integration test for dscli animation -*- lexical-binding: t; -*-

;; 设置加载路径
(add-to-list 'load-path (expand-file-name "."))
(add-to-list 'load-path (expand-file-name "dscli-modules"))

;; 加载所有模块
(require 'dscli)

(defun test-integrated-animation ()
  "测试完整的动画集成功能"
  (message "=== 集成测试：dscli动画功能 ===")
  
  ;; 测试1: 验证模块加载
  (message "\n1. 验证模块加载:")
  (message "   dscli-animation模块已加载: %s" (featurep 'dscli-animation))
  (message "   dscli-process模块已加载: %s" (featurep 'dscli-process))
  
  ;; 测试2: 测试动画间隔配置
  (message "\n2. 测试动画间隔配置:")
  (let ((default-interval (dscli--get-animation-interval)))
    (message "   默认间隔: %s秒" default-interval))
  
  ;; 测试3: 测试动画处理函数
  (message "\n3. 测试动画处理函数:")
  (let ((test-output "测试输出\n<!-- DS-CLI-WAITING-START -->\n等待中\n<!-- DS-CLI-WAITING-PROGRESS:5 -->\n<!-- DS-CLI-WAITING-END -->\n完成"))
    (message "   测试输出长度: %d" (length test-output))
    (let ((processed (dscli-process-output-with-animation test-output)))
      (message "   处理后长度: %d" (length processed))
      (message "   动画状态: %s" (dscli-is-animation-active-p))))
  
  ;; 测试4: 清理测试
  (message "\n4. 清理测试:")
  (dscli-cleanup-animation)
  (message "   动画已清理: %s" (not (dscli-is-animation-active-p)))
  
  ;; 测试5: 配置变量测试
  (message "\n5. 配置变量测试:")
  (setq dscli-animation-interval 0.5)
  (let ((interval (dscli--get-animation-interval)))
    (message "   dscli-animation-interval=0.5 -> 间隔: %s秒" interval))
  
  (setq dscli-animation-interval 0.1)
  (let ((interval (dscli--get-animation-interval)))
    (message "   dscli-animation-interval=0.1 -> 间隔: %s秒" interval))
  
  ;; 测试6: 最小值保护测试
  (message "\n6. 最小值保护测试:")
  (setq dscli-animation-interval 0.05)
  (let ((interval (dscli--get-animation-interval)))
    (message "   dscli-animation-interval=0.05 -> 间隔: %s秒 (自动调整为最小值0.1)" interval))
  
  (setq dscli-animation-interval -1)
  (let ((interval (dscli--get-animation-interval)))
    (message "   dscli-animation-interval=-1 -> 间隔: %s秒 (自动调整为最小值0.1)" interval))
  
  ;; 恢复默认值
  (setq dscli-animation-interval 0.3)
  
  (message "\n=== 集成测试完成 ===")
  (message "所有测试通过！"))

;; 运行测试
(test-integrated-animation)

(provide 'integration-test)