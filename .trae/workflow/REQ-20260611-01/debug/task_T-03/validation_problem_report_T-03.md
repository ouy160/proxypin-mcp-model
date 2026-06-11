# T-03 问题确认报告

## 任务信息
- Task-ID：T-03
- 标题：generateSelfSignedCertificate 添加 AKI/SKI 扩展生成
- 脚本：`.trae/workflow/REQ-20260611-01/debug/task_T-03/debug_T-03_v1_problem.dart`

## 执行结果
**红灯 ✅ 符合预期**

### 输出
```
Leaf cert PEM length: 1266
Extensions in cert: [2.5.29.17]
Has AKI (2.5.29.35): false
Has SKI (2.5.29.14): false

[FAIL] AKI/SKI not present in leaf cert ASN.1 (expected for v1_problem)
```

退出码：1

## 问题确认
`generateSelfSignedCertificate` 生成的叶子证书只包含 SAN 扩展 (2.5.29.17)，缺少：
- AKI (2.5.29.35) - Authority Key Identifier
- SKI (2.5.29.14) - Subject Key Identifier

## 修复方向
在 `lib/network/util/cert/x509.dart` 的 `generateSelfSignedCertificate` 方法中：
- 添加 AKI 扩展编码（指向 CA 的 SKI）
- 添加 SKI 扩展编码（基于叶子公钥的 SHA-1）
- 自签名 CA 证书：只添加 SKI 扩展

实现细节：
- AKI 编码：`SEQUENCE { keyIdentifier [0] IMPLICIT OCTET STRING }`，值为 CA 证书的 SKI
- SKI 编码：`OCTET STRING`，值为叶子公钥 SHA-1 摘要
