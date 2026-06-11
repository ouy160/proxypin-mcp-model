# T-04 问题确认报告

## 任务信息
- Task-ID：T-04
- 标题：_getExtensionsFromSeq 添加 AKI/SKI 解析
- 脚本：`.trae/workflow/REQ-20260611-01/debug/task_T-04/debug_T-04_v1_problem.dart`

## 执行结果
**红灯 ✅ 符合预期**

### 输出
```
Has AKI field: false
Has SKI field: false
[FAIL] AKI not parsed (expected for v1_problem)
[FAIL] SKI not parsed (expected for v1_problem)
```

## 问题确认
即使证书 ASN.1 编码包含 AKI/SKI 扩展（由 T-03 编码产生），但 `_getExtensionsFromSeq` 解析器不识别这两个 OID，导致 `extensions.authorityKeyIdentifier` 和 `extensions.subjectKeyIdentifier` 字段为 null。

## 修复方向
在 `_getExtensionsFromSeq` 的 for 循环中添加：
- `if (oi.objectIdentifierAsString == '2.5.29.14')` → 解析 SKI
- `if (oi.objectIdentifierAsString == '2.5.29.35')` → 解析 AKI（含 [0] IMPLICIT keyIdentifier）
