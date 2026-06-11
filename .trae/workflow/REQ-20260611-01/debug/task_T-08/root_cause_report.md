# T-08 根因分析报告: v3_purp.c:637 invalid certificate

## 根因 (共 3 个 Bug)

### Bug 1: SKI 扩展编码 — 单层 OCTET STRING

- **问题**: `generateSelfSignedCertificate` 把 leaf SKI 直接放入了 `extn_value`:
  ```dart
  skiSequence.add(ASN1OctetString(octets: leafSki));
  ```
  OpenSSL 期望 extn_value 是**双层** OCTET STRING 包装:
  ```
  extn_value = OCTET STRING { OCTET STRING { 20 bytes hash } }
               ^^ 22 bytes ^^
  ```
  Proxypin 编码:
  ```
  extn_value = OCTET STRING { 20 bytes hash }
               ^^ 20 bytes ^^
  ```
- **影响**: OpenSSL 的 `ossl_x509v3_cache_extensions` 无法解析此扩展 → `v3_purp.c:637 invalid certificate`
- **修复**: 改用双层包装:
  ```dart
  final skiInnerOs = ASN1OctetString(octets: leafSki);
  final skiOuterOs = ASN1OctetString(octets: skiInnerOs.encode());
  skiSequence.add(skiOuterOs);
  ```

### Bug 2: KeyUsage BIT STRING 常量值错误

- **问题**: `ExtensionKeyUsage.digitalSignature = (1 << 7) = 0x80` 实际对应 **encipherOnly**
  `ExtensionKeyUsage.keyEncipherment = (1 << 5) = 0x20` 实际对应 **keyCertSign**
- **影响**: 名称与 RFC 5280 的位定义不符。虽然常量值产生的字节值与 OpenSSL 兼容（BIT STRING 用 MSB=bit 0），但命名误导了调用方

### Bug 3: `keyUsageBytes` unused bits 硬编码

- **问题**: `keyUsageBytes` 强制 unused bits = 1
- **影响**: 当 value 高位有 set bit 时 unused bits 应为 0
- **修复**: 动态计算 unused bits = 8 - highest_bit(value) - 1

## 验证结果

```
openssl verify -CAfile assets/certs/ca.crt proxypin_leaf_v2.pem → OK
```

通过 SOCKS5 代理连接 api.minimaxi.com:443 时 SSL 验证通过（API 返回 429 rate limit，非证书错误）

## 修改的文件

| 文件 | 修改 |
|---|---|
| `lib/network/util/cert/x509.dart` | SKI 双层 OS 包装；keyUsageSequence 支持 critical 参数 |
| `lib/network/util/cert/key_usage.dart` | 常量值正确注释；keyUsageBytes 动态 unused bits 计算 |
| `lib/network/util/crts.dart` | CA chain 拼接；generate 添加 EKU + KeyUsage |
