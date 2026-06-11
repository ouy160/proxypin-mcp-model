# T-06 回归测试报告

## 回归测试范围
- `test/x509_test.dart` 全套测试

## 执行命令
```bash
dart test/x509_test.dart
```

## 结果
- 状态：✅ 通过
- 输出：
  ```
  CA subject hash: 243f0bfb
  [OK] Leaf cert SKI: 20 bytes
  [OK] Leaf cert AKI: 20 bytes
  [OK] Leaf SKI matches computeSubjectKeyIdentifier
  [OK] All AKI/SKI tests passed
  ```
- 兼容性：OK
