# ProxyPin MCP

[English](README_EN.md) | 中文

> **本仓库是 [ProxyPin](https://github.com/wanghongenpin/proxypin) 的 MCP 增强版**，在保留原版全部抓包功能的基础上，内置了完整的 **MCP Server（Model Context Protocol）**，让 AI（Claude、Cursor、Windsurf 等）能够直接连接、读取、操控抓包数据，实现自动化流量分析、改包测试和安全审计。

---

## 🚨 BREAKING CHANGES - 近期破坏性变更

### 2026-06-11：MITM 证书链重构

本次更新修复了 OpenSSL `v3_purp.c:637` 证书验证失败的根因问题，涉及以下破坏性变更：

#### 1. SKI（Subject Key Identifier）编码方式变更

**影响范围**：所有由 ProxyPin 生成的 MITM 叶子证书。

| 项目 | 旧版 | 新版 |
|------|------|------|
| ASN.1 结构 | `04 14 <20byte>`（单层 OCTET STRING） | `04 16 04 14 <20byte>`（双层 OCTET STRING） |
| OpenSSL 兼容性 | ❌ `ossl_x509v3_cache_extensions` 解析失败 | ✅ 完全兼容 |

**影响**：更新后新生成的叶子证书 SKI 字段为双层 OCTET STRING 编码，与 RFC 5280 标准一致。旧证书不受影响。如果你的系统硬编码了 SKI 字段的 ASN.1 结构，需要相应调整。

#### 2. KeyUsage 常量顺序修正

**影响范围**：KeyUsage 扩展的 BIT STRING 编码。

| 常量 | 旧值（错误） | 新值（RFC 5280 修正） |
|------|------------|-------------------|
| `digitalSignature` | `0x01` | `0x80` |
| `nonRepudiation` | `0x02` | `0x40` |
| `keyEncipherment` | `0x04` | `0x20` |
| `dataEncipherment` | `0x08` | `0x10` |
| `keyAgreement` | `0x10` | `0x08` |
| `keyCertSign` | `0x20` | `0x04` |
| `cRLSign` | `0x40` | `0x02` |
| `encipherOnly` | `0x80` | `0x01` |

**影响**：使用自定义 KeyUsage 配置的策略需要更新常量值。默认生成的 MITM 证书自动使用修正后的值，无需手动调整。

#### 3. KeyUsage unusedBits 动态计算

**影响范围**：KeyUsage 扩展编码。

`keyUsageBytes` 改用 `_lowestBit`（最低有效位）计算 `unusedBits`，替代之前的硬编码值。新公式：`unusedBits = 7 - _lowestBit(value) + 1`，保证编码正确性。

#### 4. 自签名 CA 证书 AKI（Authority Key Identifier）修正

**影响范围**：CA 自签名证书。

自签名 CA 证书的 AKI 现在使用**自己的 SKI**（而不是叶子证书的 SKI），确保 `openssl verify -CAfile ca.crt ca.crt` 验证通过。

#### 5. generateNewRootCA 自动刷新配置

**影响范围**：重新生成根证书后的行为。

重新生成根证书后自动调用 `initCAConfig()` 刷新 UI 和运行时配置，不再需要手动重启应用。

#### 6. post_handshake_auth 扩展处理移除

**影响范围**：TLS MITM 握手流程。

移除了对 `post_handshake_auth` TLS 扩展的特殊跳过逻辑。此前因该扩展导致的 MITM 跳过行为已修复，现在此类连接正常执行 MITM 拦截。

#### 升级指南

1. 更新应用后，建议重新生成一次根证书（设置 → 证书管理 → 重新生成）
2. 重新安装新根证书到系统信任存储
3. 旧抓包数据不受影响

---

## 更新日志

### [1.2.9] - 2026-06-11

#### 修复

- **OpenSSL 证书验证修复**：修复 `v3_purp.c:637` 证书校验失败导致的 TLS 握手异常。根因：SKI 编码缺少双层 OCTET STRING 封装。[#T-08]
- **KeyUsage 编码修正**：BIT STRING 常量改为 RFC 5280 的 MSB-first 顺序（`digitalSignature=0x80`），修复 `keyCertSign` 被错误解析的问题。[#T-08]
- **CA 自签名 AKI 修正**：自签名 CA 证书使用自己的 SKI 作为 AKI，通过 `openssl verify` 自验证。[#T-07]
- **generateNewRootCA 刷新 CA 配置**：重新生成根证书后立即刷新运行时配置和 UI 显示。[#T-08]
- **移除 post_handshake_auth 跳过逻辑**：连接不再因该 TLS 扩展被跳过 MITM 拦截。[#T-05]
- **SSL 调试日志**：在 MITM 握手关键路径添加调试日志，便于排查 TLS 问题。[#T-05]

#### 变更

- **KeyUsage unusedBits 动态计算**：`keyUsageBytes` 改用 `_lowestBit` 算法，正确计算 BIT STRING 的未使用位数。[#T-08]
- **测试文件清理**：移除仓库中的调试测试文件和测试 API 脚本。

---

## MCP 核心功能

> **一句话**：打开 ProxyPin，AI 就能看到你在抓什么包，并且能帮你分析、改包、放行——就像 Fiddler 断点，但由 AI 控制。

### 连接方式

ProxyPin MCP Server 默认监听 **9099** 端口，SSE 传输协议，无需额外安装任何依赖。

在 Claude Desktop / Cursor 等 AI 工具中配置：

```json
{
  "mcpServers": {
    "proxypin": {
      "url": "http://127.0.0.1:9099/sse"
    }
  }
}
```

---

### 已实现的 MCP 工具（27 个）

#### 一、基础抓包查询（9 个）

| 工具 | 说明 |
|------|------|
| `get_request_list` | 获取请求列表，支持按域名/方法/状态码/关键词过滤、分页 |
| `get_request_detail` | 获取单条请求完整详情（请求头、请求体、响应头、响应体、耗时） |
| `get_request_body` | 单独获取大体积请求体或响应体原始内容 |
| `get_request_stats` | 统计摘要：域名分布、状态码分布、方法分布、平均耗时 |
| `search_requests` | 高级搜索：URL/Body/Header 关键词 + 时间范围多条件组合 |
| `get_domain_summary` | 按域名分组汇总：路径列表、方法分布、平均耗时 |
| `get_cookie_info` | 提取分析指定域名的 Cookie/Set-Cookie 及属性 |
| `compare_requests` | 对比两条请求的 URL/Header/Body/状态码差异 |
| `analyze_encrypted_content` | 检测 Base64/Hex/URL编码/JWT，计算信息熵，推测加密算法 |

#### 二、请求重放与代码生成（2 个）

| 工具 | 说明 |
|------|------|
| `replay_request` | 重放指定请求，可临时覆盖 Headers/Body，返回真实响应（改包测试） |
| `generate_code` | 将抓包请求转成 Python / JavaScript / cURL / Go 可执行代码 |

#### 三、断点拦截·改包放行（5 个，核心）

> 类似 Fiddler 的断点功能，但由 AI 控制修改后放行。

| 工具 | 说明 |
|------|------|
| `add_breakpoint` | 添加断点规则（URL 正则 + HTTP 方法 + 拦截请求或响应阶段） |
| `list_breakpoints` | 列出所有断点规则及启用状态 |
| `remove_breakpoint` | 删除指定断点规则 |
| `get_pending_intercepts` | 查看当前被暂停等待放行的请求/响应（含完整数据） |
| `release_intercept` | 放行拦截的请求/响应，可修改 Headers、Body、StatusCode，或直接中止 |

**典型用法：**
```
AI: add_breakpoint url=".*api/login.*"
→ 触发 App 登录
→ AI: get_pending_intercepts  ← 读到被拦截的完整请求
→ AI: release_intercept requestId=xxx body='{"user":"admin","pass":"123456"}'  ← 改包放行
```

#### 四、重写规则管理（3 个）

| 工具 | 说明 |
|------|------|
| `list_rewrite_rules` | 列出所有持久化重写规则 |
| `add_rewrite_rule` | 添加规则：替换响应/请求体、修改 Header、重定向（5 种类型） |
| `remove_rewrite_rule` | 删除指定规则 |

#### 五、JS 脚本管理（3 个）

| 工具 | 说明 |
|------|------|
| `list_scripts` | 列出所有 JS 拦截脚本 |
| `get_script_content` | 读取脚本代码 |
| `create_or_update_script` | AI 直接编写/修改 JS 脚本（含 `onRequest`/`onResponse`），持久生效 |

#### 六、安全分析（3 个）

| 工具 | 说明 |
|------|------|
| `find_sensitive_data` | 扫描手机号/身份证/邮箱/JWT/Bearer Token/API Key/密码字段/内网 IP |
| `analyze_auth` | 提取所有 Auth Header、API Key、Cookie Session Token，自动解析 JWT Payload |
| `extract_api_endpoints` | 路径归组（数字/UUID 替换占位符），统计调用频次和状态码分布 |

---

## 自动化构建与发布

本仓库使用 GitHub Actions 实现多平台自动构建，无需本地配置 Flutter 编译环境。

### 工作流说明

| 工作流文件 | 触发条件 | 产物 |
|-----------|---------|------|
| `windows-build.yml` | `mcp-main` 分支推送 / 手动触发 | Windows zip（CI 验证） |
| `release.yml` | `v*` tag 推送 / 手动触发 | Windows zip + Setup.exe + Android APK → GitHub Release |

### 发布新版本

```bash
git tag v1.2.7
git push origin v1.2.7
# GitHub Actions 自动构建并创建 Release，约 15-25 分钟
```

### Release 产物

- `proxypin-mcp-windows-{ver}.zip` — 直接解压运行
- `proxypin-mcp-windows-{ver}-setup.exe` — Inno Setup 安装包（支持中英双语）
- `proxypin-mcp-android-{ver}.apk` — Android APK（Release 签名 / Debug 签名）

### Android 签名配置（可选）

在 GitHub → Settings → Secrets → Actions 中配置以下 Secret，构建将自动切换为 Release 签名：

| Secret | 说明 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 your.keystore` 的输出 |
| `ANDROID_STORE_PASSWORD` | storePassword |
| `ANDROID_KEY_ALIAS` | keyAlias |
| `ANDROID_KEY_PASSWORD` | keyPassword |

---

## ProxyPin 原版核心特性

本仓库完整保留原版所有能力：

- **全平台支持**：Windows、Mac、Android、iOS、Linux
- **手机扫码连接**：无需手动配置 Wifi 代理
- **域名过滤**：精准拦截目标流量
- **请求搜索**：关键词、响应类型多维搜索
- **JS 脚本**：编写脚本动态处理请求/响应
- **请求重写**：重定向、替换报文、修改参数
- **请求映射**：本地文件/脚本替代远程响应
- **请求解密**：AES 密钥自动解密消息体
- **请求屏蔽**：URL 规则屏蔽请求
- **历史记录**：自动保存流量，支持 HAR 导出/导入

---

## 与上游同步

本仓库通过 `upstream` remote 追踪原作者更新：

```bash
git fetch upstream
git merge upstream/main
git push origin mcp-main
```

---

## 上游项目

原版 ProxyPin：[https://github.com/wanghongenpin/proxypin](https://github.com/wanghongenpin/proxypin)

感谢原作者 [@wanghongenpin](https://github.com/wanghongenpin) 的出色工作。

## MCP 项目来源

本仓库 MCP Server 的实现基于 [SuxyEE/proxypin-mcp](https://github.com/SuxyEE/proxypin-mcp) 项目，在保留原版全部抓包能力的基础上，将 MCP Server 内置集成到 ProxyPin 主进程中。

感谢 MCP 作者 [@SuxyEE](https://github.com/SuxyEE) 的开创性工作。

---

## License

Apache License 2.0，与上游保持一致。
