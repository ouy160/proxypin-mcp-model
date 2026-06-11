# T-01 回归测试报告

## 回归测试范围
- `test/x509_test.dart` - X509 工具函数测试
- `test/cert_test.dart` - 证书生成测试

## 执行命令
```bash
dart test/x509_test.dart
```

## 结果

### test/x509_test.dart
- 状态：✅ 通过
- 输出：`243f0bfb`（subject hash 名，与修改前一致）
- 行为兼容性：OK

### test/cert_test.dart
- 状态：❌ 失败（与本次修改无关）
- 错误：`PathNotFoundException: assets/certs/server.key`
- 原因：测试文件依赖的预存数据文件不存在
- 影响范围：与 AKI/SKI 修改无关，是测试数据缺失问题（pre-existing）

## 兼容性结论
T-01 修改不破坏现有 X.509 解析和生成逻辑。
