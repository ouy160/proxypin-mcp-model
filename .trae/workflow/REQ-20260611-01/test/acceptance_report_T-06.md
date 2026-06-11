# T-06 验收测试报告

## 任务信息
- Task-ID：T-06
- 标题：test/x509_test.dart 添加 AKI/SKI 单元测试
- 测试文件：`test/x509_test.dart`

## 测试用例

| 用例ID | 用例名称 | 测试步骤 | 预期结果 | 实际结果 | 通过 |
|---|---|---|---|---|---|
| L001 | SKI 字段断言 | 解析用 CA 签发的 leaf cert | `extensions.subjectKeyIdentifier.length == 20` | 20 bytes | ✅ |
| L002 | AKI 字段断言 | 解析用 CA 签发的 leaf cert | `extensions.authorityKeyIdentifier.length == 20` | 20 bytes | ✅ |
| L003 | SKI 一致性 | SKI == `computeSubjectKeyIdentifier(publicKey)` | 字节级相等 | 相等 | ✅ |

## 执行结果

```bash
$ dart test/x509_test.dart
CA subject hash: 243f0bfb
[OK] Leaf cert SKI: 20 bytes
[OK] Leaf cert AKI: 20 bytes
[OK] Leaf SKI matches computeSubjectKeyIdentifier

[OK] All AKI/SKI tests passed
```

## 验收
- ✅ L001 通过
- ✅ L002 通过
- ✅ L003 通过
- **综合匹配度：100%**
