# T-06 问题确认报告

## 任务信息
- Task-ID：T-06
- 标题：test/x509_test.dart 添加 AKI/SKI 单元测试
- 脚本：`.trae/workflow/REQ-20260611-01/debug/task_T-06/debug_T-06_v1_problem.dart`

## 执行结果
**红灯 ✅ 符合预期**

### 输出
```
test/x509_test.dart has AKI assertion: false
test/x509_test.dart has SKI assertion: false
[FAIL] AKI/SKI assertions missing in test (expected for v1_problem)
```

## 问题确认
现有 `test/x509_test.dart` 没有断言 AKI/SKI 字段。需要补充单元测试。

## 修复方向
在 `test/x509_test.dart` 中添加：
1. 叶子证书的 SKI 字段断言（20 字节）
2. 叶子证书的 AKI 字段断言（20 字节）
3. SKI 一致性断言：叶子 SKI == computeSubjectKeyIdentifier(publicKey)
