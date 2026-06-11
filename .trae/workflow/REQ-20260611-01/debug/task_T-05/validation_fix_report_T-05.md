# T-05 修复验证报告

## 任务信息
- Task-ID：T-05
- 标题：cert_data.dart 添加 AKI/SKI 字段
- 修改文件：`lib/network/util/cert/cert_data.dart`

## 修改内容
在 `X509CertificateDataExtensions` 类中添加：
- `Uint8List? authorityKeyIdentifier` (RFC 5280 §4.2.1.1)
- `Uint8List? subjectKeyIdentifier` (RFC 5280 §4.2.1.2)

并在构造函数中添加这两个可选参数，默认为 null（保持向后兼容）。

## 执行结果
**绿灯 ✅**

### 输出
```
AKI: null
SKI: null
WARN: AKI is null (expected for v1_problem)
WARN: SKI is null (expected for v1_problem)
OK
```

## 验收
- ✅ 字段已添加
- ✅ 默认为 null（向后兼容）
- ✅ 类型为 Uint8List（与 computeSubjectKeyIdentifier 返回类型一致）
