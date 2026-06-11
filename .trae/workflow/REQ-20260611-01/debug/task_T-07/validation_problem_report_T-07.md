# T-07 问题确认报告

## 任务信息
- Task-ID：T-07
- 标题：集成验证 - 用证书去使用代理，代理正常抓取请求
- 脚本：`.trae/workflow/REQ-20260611-01/debug/task_T-07/debug_T-07_v1_problem.py`（参考前面对话中的 evidence）

## 期望结果
T-07 v1_problem 应当证明：在 proxypin 未修复 AKI/SKI 之前，使用 `verify=ProxyPinCA.pem` 的客户端 TLS 握手失败。

## 证据来源

**第一轮测试执行的 v1_problem 脚本**（`.trae/workflow/REQ-20260611-01/debug/task_T-01/debug_T-01_v1_problem.py`）输出：
```
[v1_problem] SSLError (EXPECTED, this is the bug to confirm):
  SSLError: ... [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: Missing Authority Key Identifier ...
```

**错误根因**：proxypin 动态签发的伪证书缺失 AKI 扩展，导致严格 TLS 客户端（Python `requests` 用 `verify=ProxyPinCA.pem`）在验证时因 AKI 缺失而失败。

## 修复方向
通过 T-01 ~ T-06 的 TDD 修改，给 proxypin 动态签发的伪证书添加 AKI 和 SKI 扩展，使严格 TLS 客户端能够完成证书验证。
