# T-06 修复验证报告

## 任务信息
- Task-ID：T-06
- 标题：test/x509_test.dart 添加 AKI/SKI 单元测试
- 修改文件：`test/x509_test.dart`

## 修改内容
在 `test/x509_test.dart` 中添加三个测试函数：
1. `_testLeafCertificateAkiSki()` - 验证生成的叶子证书 SKI 和 AKI 字段都是 20 字节
2. `_testAkiSkiConsistency()` - 验证叶子 SKI 等于 `computeSubjectKeyIdentifier(publicKey)`
3. 在 main() 中调用上述测试

新增 imports：`dart:typed_data`、`pointycastle/asymmetric/api.dart`、`proxypin/network/util/crypto.dart`。

## 执行结果
**绿灯 ✅**

### v1_problem 输出
```
test/x509_test.dart has AKI assertion: true
test/x509_test.dart has SKI assertion: true
[OK] AKI/SKI assertions present
```

### 实际单元测试运行输出
```
CA subject hash: 243f0bfb
[OK] Leaf cert SKI: 20 bytes
[OK] Leaf cert AKI: 20 bytes
[OK] Leaf SKI matches computeSubjectKeyIdentifier

[OK] All AKI/SKI tests passed
```

## 验收
- ✅ SKI 字段断言（20 字节）
- ✅ AKI 字段断言（20 字节）
- ✅ SKI 一致性断言（与 computeSubjectKeyIdentifier 输出一致）
- ✅ 与现有测试兼容（不破坏 ca subject hash 测试）
