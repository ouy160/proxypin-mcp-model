# T-02 问题确认报告

## 任务信息
- Task-ID：T-02
- 标题：实现 SKI 计算工具函数
- 脚本：`.trae/workflow/REQ-20260611-01/debug/task_T-02/debug_T-02_v1_problem.dart`

## 执行时间
2026-06-11 15:35:xx

## 执行结果
**红灯（编译失败）✅ 符合预期**

### 错误输出
```
.trae/workflow/REQ-20260611-01/debug/task_T-02/debug_T-02_v1_problem.dart:22:35: Error: Member not found: 'X509Utils.computeSubjectKeyIdentifier'.
  final Uint8List ski = X509Utils.computeSubjectKeyIdentifier(publicKey);
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

## 修复方向
在 `lib/network/util/cert/x509.dart` 中添加 `static Uint8List computeSubjectKeyIdentifier(RSAPublicKey publicKey)` 方法，实现 RFC 5280 §4.2.1.2 method (1)。
