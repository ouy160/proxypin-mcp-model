# REQ-20260611-01 标准化需求文档

## 1. 需求概述
proxypin 动态签发的 MITM 伪证书**缺少 Authority Key Identifier (AKI) 扩展**，导致严格 TLS 客户端（如 Python `requests` 携带 `verify=ProxyPinCA.pem`）在握手时验证失败，并触发服务端 SSL 状态机异常（`BAD_PACKET_LENGTH / DECRYPTION_FAILED_OR_BAD_RECORD_MAC`），最终导致代理抓包失败。

## 2. 核心问题
1. **客户端体验差**：用户用 ProxyPinCA 验证时无法完成 TLS 握手
2. **代理抓包失败**：MITM 拦截的 HTTPS 请求异常中断，proxypin 抓不到完整请求/响应
3. **与其他代理工具不一致**：Charles/Fiddler/Proxyman 等工具的伪证书都包含正确的 AKI/SKI 扩展

## 3. 功能点
| ID | 功能点 | 优先级 | 验收标准 |
|----|---|---|---|
| F-01 | 根 CA 证书（自签名）添加 SKI 扩展 | P0 | 根证书解析后 `extensions.subjectKeyIdentifier` 非空 |
| F-02 | 叶子证书（MITM 伪证书）添加 AKI 扩展指向 CA 的 SKI | P0 | 叶子证书解析后 `extensions.authorityKeyIdentifier` 非空 |
| F-03 | 叶子证书添加 SKI 扩展 | P0 | 叶子证书解析后 `extensions.subjectKeyIdentifier` 非空 |
| F-04 | 客户端用 `verify=ProxyPinCA.pem` 验证握手成功 | P0 | `requests.post(..., verify=cert_path)` 返回 HTTP 200 |
| F-05 | 代理（proxypin）正常抓取 HTTPS 请求 | P0 | 日志包含完整的 SOCKS5 connect + SSL handshake done + 业务帧记录 |
| F-06 | 兼容现有所有调用方 | P0 | 现有 `CertificateManager.getCertificateContext()`、`generateNewRootCA()` 等调用方行为不变 |
| F-07 | 单元测试覆盖 AKI/SKI 扩展的生成和解析 | P0 | `test/x509_test.dart` 中有断言：解析叶子证书得到非空 AKI/SKI |

## 4. 受影响模块
| 模块 | 文件 | 影响 |
|---|---|---|
| 证书扩展常量 | `lib/network/util/cert/extension.dart` | 新增 AKI/SKI OID 常量 |
| 证书生成器 | `lib/network/util/cert/x509.dart` | `generateSelfSignedCertificate` 添加 AKI/SKI 扩展生成逻辑 |
| 证书数据模型 | `lib/network/util/cert/cert_data.dart` | 添加 AKI/SKI 字段（可选；如现有模型可容纳则不扩展） |
| 证书解析器 | `lib/network/util/cert/x509.dart` | `_getExtensionsFromSeq` 解析 AKI/SKI 扩展 |
| 证书管理 | `lib/network/util/crts.dart` | 调用方不变（依赖底层 `generateSelfSignedCertificate` 行为变更） |

## 5. 验收标准
1. **AC-01**：单元测试 `test/x509_test.dart` 通过：解析由 `generateSelfSignedCertificate` 生成的叶子证书，AKI 扩展非空
2. **AC-02**：单元测试通过：解析自签名 CA 证书，SKI 扩展非空
3. **AC-03**：集成测试（手动）：`test/test_minimax_api.py` 使用 `verify="C:\Users\1\Desktop\ProxyPinCA.pem"` 返回 HTTP 200
4. **AC-04**：代理抓包：日志中 `proxypin_debug.log` 出现 `ssl handshake done`（无 ssl error）
5. **AC-05**：不破坏现有功能：`CertificateManager.generateNewRootCA()` 仍能正确生成新根证书
6. **AC-06**：现有 `test/cert_test.dart` 行为兼容（`generate(...)` 调用方式不变）

## 6. 优先级
- **P0**：核心修复，阻塞代理抓包正常工作
- **影响范围**：所有使用 proxypin HTTPS 抓包功能的用户

## 7. 风险
- **R-01**：已部署的根证书可能不包含 SKI —— 已安装 ProxyPinCA 的客户端在升级后需重新导出含 SKI 的新根证书
- **R-02**：现有 `_getExtensionsFromSeq` 解析器升级可能影响其他扩展字段读取
- **R-03**：扩展 ASN.1 编码错误会导致整个证书无效，需测试覆盖
