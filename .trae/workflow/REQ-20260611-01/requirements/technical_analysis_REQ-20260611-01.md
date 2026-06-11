# REQ-20260611-01 技术分析报告

## 1. 问题根因（5个为什么）

### Why 1：客户端 `verify=ProxyPinCA.pem` 失败
Python `requests` 抛出 `SSLCertVerificationError: Missing Authority Key Identifier`

### Why 2：为什么 AKI 缺失
proxypin 动态签发的伪证书（`CertificateManager.generate(...)`）的 ASN.1 编码不包含 AKI 扩展

### Why 3：为什么 AKI 没被生成
`lib/network/util/cert/x509.dart` 的 `generateSelfSignedCertificate` 方法只生成 BasicConstraints、KeyUsage、SAN、ExtendedKeyUsage 四种扩展，**没有 AKI/SKI 生成逻辑**

### Why 4：为什么 AKI/SKI 没被实现
`lib/network/util/cert/extension.dart` 中**没有定义 AKI (2.5.29.35) 和 SKI (2.5.29.14) 的 OID 常量**，证书生成器无法引用

### Why 5：为什么根证书没有 AKI
历史原因：proxypin 早期版本未考虑严格 TLS 客户端（如 Python requests、curl 严格模式）的 AKI 校验，依赖宽松 SSL 实现（macOS、iOS 系统库）能容忍 AKI 缺失。引入 Python 等严格客户端后问题暴露。

## 2. 模块依赖分析

### 2.1 前端模块依赖
- 无（纯服务端/证书逻辑）

### 2.2 后端模块依赖

| 模块 | 文件路径 | 涉及函数 | 调用关系 |
|---|---|---|---|
| 证书扩展常量 | `lib/network/util/cert/extension.dart` | `Extension` 类的静态常量 | 被 `x509.dart` 引用 |
| 证书生成器 | `lib/network/util/cert/x509.dart` | `generateSelfSignedCertificate` | 被 `crts.dart` 引用 |
| 证书数据模型 | `lib/network/util/cert/cert_data.dart` | `X509CertificateData`、`X509CertificateDataExtensions` | 现有模型 |
| 证书解析器 | `lib/network/util/cert/x509.dart` | `_getExtensionsFromSeq` | 解析时使用 |
| 证书管理 | `lib/network/util/crts.dart` | `generate`、`initCAConfig`、`generateNewRootCA` | 调用 `x509.dart` |
| SOCKS5 通道 | `lib/network/socks/socks5.dart` | `SocksServerHandler` | 透传，无修改 |
| SSL 拦截 | `lib/network/channel/network.dart` | `ssl()` 方法 | 调用 `CertificateManager.getCertificateContext` |

### 2.3 调用链

```
[客户端] HTTPS Request (含 TLS ClientHello)
  ↓
[proxypin:9099] Socks5.connect(...)
  ↓ SOCKS5 握手
[proxypin] onEvent(data, ...) 
  ↓ network.dart:171 TLS.isTLSClientHello(data) → true
[proxypin] ssl(channelContext, channel, data)
  ↓ network.dart:229
[proxypin] CertificateManager.getCertificateContext(serviceName)
  ↓ crts.dart:84
[proxypin] generate(_caCert, serverPubKey, _caPriKey, host)
  ↓ crts.dart:119
[x509.dart] X509Utils.generateSelfSignedCertificate(...)
  ↓ x509.dart:128
[bug] 未生成 AKI 扩展
  ↓
[proxypin] SecureSocket.secureServer(channel.socket, certificate, ...)
  ↓ Dart IO
[客户端] 收到伪证书 → 验证 AKI → Missing AKI → 握手失败
```

### 2.4 修改影响范围

| 修改点 | 文件 | 修改原因 | 适配要求 |
|---|---|---|---|
| 1 | `lib/network/util/cert/extension.dart` | 添加 AKI/SKI OID 常量 | 引用方需更新 |
| 2 | `lib/network/util/cert/x509.dart:128-249` `generateSelfSignedCertificate` | 添加 AKI/SKI 扩展编码 | 调用方通过扩展名参数传入 |
| 3 | `lib/network/util/cert/x509.dart:331-388` `_getExtensionsFromSeq` | 添加 AKI/SKI 扩展解析 | 现有解析逻辑兼容 |
| 4 | `lib/network/util/cert/cert_data.dart` | 添加 AKI/SKI 字段（解析端） | 数据模型扩展 |

### 2.5 适配清单

- **前端适配**：无
- **后端适配**：
  - `x509.dart` 添加 AKI/SKI 编码函数
  - `x509.dart` `_getExtensionsFromSeq` 添加 AKI/SKI 解析
  - `cert_data.dart` 添加 AKI/SKI 字段
  - `crts.dart` 调用方无需修改（行为透明）
- **联调验证**：
  - 单元测试：`test/x509_test.dart` 验证生成的证书包含 AKI/SKI
  - 集成测试：`test/test_minimax_api.py` 用 `verify=ProxyPinCA.pem` 验证握手成功

## 3. 技术方案

### 3.1 SKI (Subject Key Identifier) 编码

RFC 5280 Section 4.2.1.2 method (1)：
- 计算公钥的 SHA-1 哈希（20 字节）
- 取后 60 bit（高 4 bit 填充 0100，低位补 0）
- 形成 OCTET STRING

Dart 实现：
```dart
// 输入: RSAPublicKey publicKey
// 步骤: encode public key to DER → SHA-1 → 取后 60 bit
Uint8List _computeSubjectKeyIdentifier(RSAPublicKey publicKey) {
  final pubKeyBytes = CryptoUtils.encodeRSAPublicKey(publicKey);
  final sha1Hash = sha1.convert(pubKeyBytes).bytes;
  // RFC 5280: 0100 + 60 least significant bits
  return Uint8List.fromList([
    0x40 | (sha1Hash[19] & 0x0F),  // 0100 + 4 high bits
    sha1Hash[15], sha1Hash[16], sha1Hash[17], sha1Hash[18], sha1Hash[19]
  ]);
}
```

### 3.2 AKI (Authority Key Identifier) 编码

RFC 5280 Section 4.2.1.1：
- 当证书由 CA 签发时，AKI 包含 `keyIdentifier` 字段
- `keyIdentifier` 字段值 = CA 证书的 SKI 值
- ASN.1 编码：`AuthorityKeyIdentifier ::= SEQUENCE { keyIdentifier [0] KeyIdentifier, ... }`

### 3.3 证书生成流程修改

```dart
// 在 generateSelfSignedCertificate 中：
// 1. 计算 subjectKeyIdentifier (基于 publicKey)
// 2. 叶子证书: 计算 authorityKeyIdentifier (基于 caRoot 的 SKI)
// 3. 叶子证书: 添加 AKI 扩展
// 4. 叶子证书: 添加 SKI 扩展
// 5. 自签名 CA: 添加 SKI 扩展（无 AKI，因为是自签）
```

## 4. 风险评估

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| 旧根证书无 SKI，导致 AKI 指向无效 SKI | 中 | 高 | 在新代码中保留兼容：若 CA 无 SKI，AKI 用 issuerName+serialNumber 备用方案 |
| 扩展 ASN.1 编码错误 | 中 | 高 | 添加详细单元测试 |
| 旧版客户端的 ProxyPinCA.pem 不含 SKI | 高 | 中 | 提示用户重新导出根证书 |
| `_getExtensionsFromSeq` 解析破坏现有扩展 | 低 | 中 | 添加回归测试 |

## 5. 测试策略

| 层级 | 测试内容 | 工具 |
|---|---|---|
| 单元测试 | 生成证书包含 AKI/SKI | Dart test |
| 单元测试 | 解析证书得到 AKI/SKI 字段 | Dart test |
| 单元测试 | AKI 指向 CA 的 SKI | Dart test |
| 集成测试 | 完整 MITM 握手 | `test_minimax_api.py` + ProxyPin |
| 端到端测试 | 代理抓包日志 | `proxypin_debug.log` 检查 |
