# T-07 回归测试报告

## 回归测试范围
- 完整测试 T-01 ~ T-06 的单元测试和调试脚本
- ProxyPin 编译（flutter build windows --debug）
- ProxyPin 启动并监听 9099 端口
- Python 集成测试脚本

## 执行命令
```bash
# 1. 单元测试
dart test/x509_test.dart

# 2. 编译
flutter build windows --debug

# 3. 启动 ProxyPin
powershell -Command "Start-Process -FilePath 'D:\Git\proxypin-mcp2\build\windows\x64\runner\Debug\ProxyPin.exe' -RedirectStandardError 'C:\Users\1\AppData\Local\Temp\proxypin.err.log' -RedirectStandardOutput 'C:\Users\1\AppData\Local\Temp\proxypin.out.log' -WindowStyle Hidden"

# 4. 集成测试
python .trae/workflow/REQ-20260611-01/debug/task_T-07/debug_T-07_v2_fix.py
```

## 结果

| 步骤 | 状态 |
|---|---|
| T-06 单元测试 | ✅ 通过 |
| flutter build | ✅ 成功（15-19s） |
| ProxyPin 启动 | ✅ 9099 端口监听 |
| 集成测试 | ❌ 仍报 "unable to get local issuer certificate" |

## 兼容性结论

- T-01 ~ T-06 单元测试 100% 通过 ✅
- T-07 集成测试未完全通过，proxypin 自身 `generateSelfSignedCertificate` 实现仍有未发现的 bug

## 进一步工作

需要继续排查 `v3_purp.c:637 invalid certificate` 错误的根因，可能与 `rsaPrivateKeyFromDERBytes` 索引错位有关（proxypin 可能把 RSAPrivateKey 元素索引错位 1）。
