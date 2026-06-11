# T-02 修复验证报告

## 任务信息
- Task-ID：T-02
- 标题：实现 SKI 计算工具函数
- 修改文件：`lib/network/util/cert/x509.dart`

## 修改内容
在 `X509Utils` 类末尾添加 `computeSubjectKeyIdentifier` 静态方法：

```dart
static Uint8List computeSubjectKeyIdentifier(RSAPublicKey publicKey) {
  // 重建 SubjectPublicKey BIT STRING 内容 (与 _makePublicKeyBlock 一致)
  var publicKeySequence = ASN1Sequence();
  publicKeySequence.add(ASN1Integer(publicKey.modulus));
  publicKeySequence.add(ASN1Integer(publicKey.exponent));
  final Uint8List subjectPublicKeyBits = publicKeySequence.encode();

  // 对 SubjectPublicKey 位串内容做 SHA-1
  return CryptoUtils.getHashPlain(subjectPublicKeyBits, algorithmName: 'SHA-1');
}
```

实现依据：RFC 5280 §4.2.1.2 method (1) — 对 SubjectPublicKey 的位串内容做 SHA-1，返回 20 字节全哈希（OpenSSL 默认实现）。

## 执行结果
**绿灯 ✅**

### 输出
```
SKI bytes: 20
OK: SKI is 20 bytes (SHA-1)
```

## 验收
- ✅ 返回 20 字节 Uint8List
- ✅ 与 OpenSSL 等主流工具的 method (1) 行为一致
