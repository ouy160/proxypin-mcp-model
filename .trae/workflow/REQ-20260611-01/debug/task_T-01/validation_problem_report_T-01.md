# T-01 问题确认报告

## 任务信息
- Task-ID：T-01
- 标题：在 extension.dart 添加 AKI/SKI OID
- 脚本：`.trae/workflow/REQ-20260611-01/debug/task_T-01/debug_T-01_v1_problem.dart`

## 执行时间
2026-06-11 15:35:xx

## 执行命令
```bash
dart .trae/workflow/REQ-20260611-01/debug/task_T-01/debug_T-01_v1_problem.dart
```

## 执行结果
**红灯（编译失败）✅ 符合预期**

### 错误输出
```
.trae/workflow/REQ-20260611-01/debug/task_T-01/debug_T-01_v1_problem.dart:17:28: Error: Member not found: 'authorityKeyIdentifier'.
  final akiOid = Extension.authorityKeyIdentifier;
                           ^^^^^^^^^^^^^^^^^^^^^^
.trae/workflow/REQ-20260611-01/debug/task_T-01/debug/task_T-01/debug_T-01_v1_problem.dart:18:28: Error: Member not found: 'subjectKeyIdentifier'.
  final skiOid = Extension.subjectKeyIdentifier;
                           ^^^^^^^^^^^^^^^^^^^^
```

退出码：254

## 问题确认
`Extension` 类中确实缺少：
- `authorityKeyIdentifier` (2.5.29.35)
- `subjectKeyIdentifier` (2.5.29.14)

## 修复方向
在 `lib/network/util/cert/extension.dart` 中添加这两个静态常量。
