# REQ-20260611-01 任务列表

## 任务总览

| Task-ID | 标题 | 文件 | 类型 | 优先级 |
|---|---|---|---|---|
| T-01 | 在 extension.dart 添加 AKI/SKI OID 常量 | `lib/network/util/cert/extension.dart` | 静态常量 | P0 |
| T-02 | 实现 SKI 计算工具函数 | `lib/network/util/cert/x509.dart` | 工具函数 | P0 |
| T-03 | 在 generateSelfSignedCertificate 添加 AKI/SKI 扩展生成 | `lib/network/util/cert/x509.dart` | 证书生成 | P0 |
| T-04 | 在 _getExtensionsFromSeq 添加 AKI/SKI 扩展解析 | `lib/network/util/cert/x509.dart` | 证书解析 | P0 |
| T-05 | 在 cert_data.dart 添加 AKI/SKI 字段 | `lib/network/util/cert/cert_data.dart` | 数据模型 | P0 |
| T-06 | 在 test/x509_test.dart 添加 AKI/SKI 单元测试 | `test/x509_test.dart` | 单元测试 | P0 |
| T-07 | 端到端集成验证（MITM 握手 + 代理抓包） | `test/test_minimax_api.py` | 集成测试 | P0 |

## 依赖关系

```
T-01 (Extension OID)
  ↓
T-02 (SKI 计算)
  ↓
T-03 (生成 AKI/SKI 扩展) ←── T-01, T-02
  ↓
T-05 (数据模型字段) ←── T-03
  ↓
T-04 (解析 AKI/SKI) ←── T-01, T-05
  ↓
T-06 (单元测试) ←── T-03, T-04
  ↓
T-07 (集成验证) ←── T-06
```

## 串行/并行决策

- 接口数 = 0（纯内部实现）
- 团队结构：单 agent 串行
- **决策：串行模式**，按 T-01 → T-02 → T-03 → T-05 → T-04 → T-06 → T-07 顺序

## 任务详细说明

### T-01: 在 extension.dart 添加 AKI/SKI OID 常量
- **目标**：在 `Extension` 类中添加 `authorityKeyIdentifier` 和 `subjectKeyIdentifier` 静态常量
- **OID**：
  - AKI: `2.5.29.35`
  - SKI: `2.5.29.14`
- **TDD**：
  - v1_problem: 引用 `Extension.authorityKeyIdentifier` 失败（确认常量缺失）
  - v2_fix: 添加常量后，引用成功

### T-02: 实现 SKI 计算工具函数
- **目标**：实现 RFC 5280 method (1) 的 SKI 计算
- **TDD**：
  - v1_problem: 引用不存在的 `computeSubjectKeyIdentifier` 函数，编译失败
  - v2_fix: 实现函数，编译通过

### T-03: 在 generateSelfSignedCertificate 添加 AKI/SKI 扩展生成
- **目标**：证书 ASN.1 编码中包含 AKI/SKI 扩展
- **TDD**：
  - v1_problem: 用 `openssl asn1parse` 解析生成的证书，AKI/SKI 缺失
  - v2_fix: 实现 AKI/SKI 编码后，ASN.1 包含 AKI/SKI

### T-04: 在 _getExtensionsFromSeq 添加 AKI/SKI 扩展解析
- **目标**：解析证书时正确提取 AKI/SKI 字段
- **TDD**：
  - v1_problem: 解析含 AKI/SKI 的证书，`extensions.authorityKeyIdentifier` 为空
  - v2_fix: 实现解析逻辑后，字段非空

### T-05: 在 cert_data.dart 添加 AKI/SKI 字段
- **目标**：在 `X509CertificateDataExtensions` 添加 AKI/SKI 字段
- **TDD**：与 T-04 合并

### T-06: 在 test/x509_test.dart 添加 AKI/SKI 单元测试
- **目标**：用 Dart test 框架验证生成和解析 AKI/SKI
- **TDD**：
  - v1_problem: 测试运行失败（AKI 缺失）
  - v2_fix: 修复后测试通过

### T-07: 端到端集成验证
- **目标**：`test/test_minimax_api.py` 用 `verify=ProxyPinCA.pem` 验证握手成功 + 代理抓包正常
- **TDD**：
  - v1_problem: 脚本运行返回 SSLError
  - v2_fix: 修复后脚本运行返回 HTTP 200 + 完整 SSE 帧
