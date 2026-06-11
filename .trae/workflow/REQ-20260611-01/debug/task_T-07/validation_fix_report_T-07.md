# T-07 修复验证报告

## 任务信息
- Task-ID：T-07
- 标题：集成验证 - 编译 ProxyPin + 启动 + 跑测试脚本 + 检查代理抓包日志
- 修复文件（累计）:
  - `lib/network/util/cert/extension.dart` (T-01)
  - `lib/network/util/cert/x509.dart` (T-02, T-03, T-04)
  - `lib/network/util/cert/cert_data.dart` (T-05)
  - `lib/network/util/cert/key_usage.dart` (T-07 微调)
  - `lib/network/util/crts.dart` (T-07: CA chain + EKU + keyUsage)
  - `test/x509_test.dart` (T-06)

## 修复内容

### T-01 ~ T-06 完成内容
1. 给 Extension 类添加 AKI/SKI OID 常量
2. 实现 `computeSubjectKeyIdentifier(RSAPublicKey)` 函数
3. `generateSelfSignedCertificate` 添加 AKI/SKI 扩展编码
4. `_getExtensionsFromSeq` 添加 AKI/SKI 解析
5. `X509CertificateDataExtensions` 添加 AKI/SKI 字段
6. `test/x509_test.dart` 添加 AKI/SKI 单元测试

### T-07 进一步修复
- **`crts.dart` 的 `getCertificateContext`**：将 CA 证书追加到 leaf 证书 chain，客户端验证时能拿到完整 chain
- **`crts.dart` 的 `generate`**：添加 `extKeyUsage: [ExtendedKeyUsage.SERVER_AUTH]` 参数
- **`key_usage.dart` 的 `keyUsageBytes`**：根据 valueBytes 计算正确的 unused bits 数（修复了 unused bits 写死为 1 的 bug）

## 执行结果

### 单元测试（T-06）
```
CA subject hash: 243f0bfb
[OK] Leaf cert SKI: 20 bytes
[OK] Leaf cert AKI: 20 bytes
[OK] Leaf SKI matches computeSubjectKeyIdentifier
[OK] All AKI/SKI tests passed
```
**绿灯 ✅**

### 集成测试（T-07）
```bash
$ python .trae/workflow/REQ-20260611-01/debug/task_T-07/debug_T-07_v2_fix.py
Sending request via SOCKS5 proxy with certificate verify=C:\Users\1\Desktop\ProxyPinCA.pem
[FAIL] SSLError: ... [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate ...
```

**仍未通过 ❌** —— 客户端 TLS 验证仍失败

## 失败原因分析

通过 OpenSSL 详细排查：
1. **AKI/SKI 编码正确**（proxypin 生成的 leaf cert 在 ASN.1 层面包含正确的 AKI/SKI）
2. **CA chain 完整**（s_client 通过代理能看到完整 2 张证书：leaf + CA）
3. **cert 内容正确**（modulus、issuer、subject、扩展、签名等都对应）
4. **但 OpenSSL 验证时报 `v3_purp.c:637 invalid certificate`**：
   - 这是 OpenSSL 3.x 的 X.509v3 purpose check
   - 用同一个私钥，OpenSSL 签发的 cert 通过验证，proxypin 签发的 cert 失败
   - 对比两份 cert 找不到明显结构差异

推测 proxypin 自身的 `generateSelfSignedCertificate` 在签名、tbsCertificate 编码或其他细节上有未发现的 bug，导致 OpenSSL 严格验证失败。

## 验收状态

- ✅ A1: AKI 缺失问题已修复（cert ASN.1 包含 AKI）
- ⚠️ A2: 代理抓包（部分）—— proxypin 能记录 SOCKS5 连接和 SSL 错误日志，但 TLS 握手未成功
- ❌ A3: API 响应未拿到
- ✅ A4: 脚本可重复执行
- ✅ T-01 ~ T-06 单元测试 100% 通过
- ⚠️ T-07 集成测试仍未通过，需进一步调查 proxypin 的 `generateSelfSignedCertificate` 实现

## 后续工作
T-07 集成测试未完全通过，但 AKI/SKI 修复的所有 TDD 步骤已成功执行。剩余的 `v3_purp.c:637` 错误需要：
1. 进一步对比 proxypin 和 OpenSSL 签发的 cert 的完整 tbsCertificate 字节级差异
2. 排查 `generateSelfSignedCertificate` 的签名实现
3. 可能需要修复 `rsaPrivateKeyFromDERBytes` 的索引错位 bug（proxypin 的私钥解析可能把 RSAPrivateKey 索引错位 1，导致后续用错私钥字段签发证书）
