# T-05 问题确认报告

## 任务信息
- Task-ID：T-05
- 标题：cert_data.dart 添加 AKI/SKI 字段
- 脚本：`.trae/workflow/REQ-20260611-01/debug/task_T-05/debug_T-05_v1_problem.dart`

## 执行结果
**红灯（编译失败）✅ 符合预期**

### 错误输出
```
.trae/workflow/REQ-20260611-01/debug/task_T-05/debug_T-05_v1_problem.dart:17:24: Error: The getter 'authorityKeyIdentifier' isn't defined for the type 'X509CertificateDataExtensions'.
  final akiValue = ext.authorityKeyIdentifier;
.trae/workflow/REQ-20260611-01/debug/task_T-05/debug_T-05_v1_problem.dart:18:24: Error: The getter 'subjectKeyIdentifier' isn't defined for the type 'X509CertificateDataExtensions'.
  final skiValue = ext.subjectKeyIdentifier;
```

## 修复方向
在 `X509CertificateDataExtensions` 类中添加：
- `Uint8List? authorityKeyIdentifier` (RFC 5280 §4.2.1.1, 2.5.29.35)
- `Uint8List? subjectKeyIdentifier` (RFC 5280 §4.2.1.2, 2.5.29.14)
