# T-03 修复验证报告

## 任务信息
- Task-ID：T-03
- 标题：generateSelfSignedCertificate 添加 AKI/SKI 扩展生成
- 修改文件：`lib/network/util/cert/x509.dart`

## 修改内容
在 `generateSelfSignedCertificate` 中：
1. 计算叶子公钥的 SKI（使用 T-02 的 `computeSubjectKeyIdentifier`）
2. 从 `caRoot.tbsCertificateSeqAsString` 重新解析出 CA 的 SubjectPublicKey BIT STRING，计算 CA 的 SKI
3. 扩展 `if` 条件：只要 `caSki != null` 就添加 extensions 块
4. 在 extensions 序列中添加 SKI 扩展：`SEQUENCE { OID(2.5.29.14), OCTET STRING <20 bytes> }`
5. 在 extensions 序列中添加 AKI 扩展：`SEQUENCE { OID(2.5.29.35), OCTET STRING <DER of AuthorityKeyIdentifier> }`
   - AuthorityKeyIdentifier 内部：`SEQUENCE { [0] IMPLICIT OCTET STRING <caSki> }`

## 关键技术点
- **SPKI 索引计算**：tbsCertificate 中 SubjectPublicKeyInfo 的位置取决于是否有 version 字段
  - 有 version（V3 证书）：tbs 第一个是 ASN1Object（tag 0xA0），spki 在索引 6
  - 无 version（V1 证书）：tbs 第一个是 ASN1Integer，spki 在索引 5

## 执行结果
**绿灯 ✅**

### 输出
```
Leaf cert PEM length: 1348
Extensions in cert: [2.5.29.17, 2.5.29.14, 2.5.29.35]
Has AKI (2.5.29.35): true
Has SKI (2.5.29.14): true

[OK] AKI/SKI present in leaf cert
```

## 验收
- ✅ SAN (2.5.29.17) 保留
- ✅ SKI (2.5.29.14) 已添加
- ✅ AKI (2.5.29.35) 已添加
- ✅ PEM 长度从 1266 增加到 1348（合理）
- ✅ 与 RFC 5280 §4.2.1.1 / §4.2.1.2 一致
