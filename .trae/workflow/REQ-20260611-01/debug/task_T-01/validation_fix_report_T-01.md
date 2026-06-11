# T-01 修复验证报告

## 任务信息
- Task-ID：T-01
- 标题：在 extension.dart 添加 AKI/SKI OID
- 修改文件：`lib/network/util/cert/extension.dart`

## 修改内容
在 `Extension` 类中添加两个静态常量：
- `subjectKeyIdentifier` → 2.5.29.14 (RFC 5280 §4.2.1.2)
- `authorityKeyIdentifier` → 2.5.29.35 (RFC 5280 §4.2.1.1)

```dart
/// Subject Key Identifier (RFC 5280 §4.2.1.2) — 2.5.29.14
static final ASN1ObjectIdentifier subjectKeyIdentifier = ASN1ObjectIdentifier.fromIdentifierString("2.5.29.14");

/// Authority Key Identifier (RFC 5280 §4.2.1.1) — 2.5.29.35
static final ASN1ObjectIdentifier authorityKeyIdentifier = ASN1ObjectIdentifier.fromIdentifierString("2.5.29.35");
```

## 执行时间
2026-06-11 15:35:xx

## 执行命令
```bash
dart .trae/workflow/REQ-20260611-01/debug/task_T-01/debug_T-01_v2_fix.dart
```

## 执行结果
**绿灯 ✅**

### 输出
```
AKI OID: 2.5.29.35
SKI OID: 2.5.29.14
OK
```

退出码：0

## 验收
- ✅ AKI OID 正确解析为 `2.5.29.35`
- ✅ SKI OID 正确解析为 `2.5.29.14`
- ✅ 与 RFC 5280 一致
