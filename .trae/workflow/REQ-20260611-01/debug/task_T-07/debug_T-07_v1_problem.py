"""T-07 v1_problem - 用 verify=cert_path 验证握手

目的: 在 proxypin 未修复 AKI/SKI 之前, 用 ProxyPinCA.pem 验证
      api.minimaxi.com 的证书会失败 (SSLCertVerificationError: Missing Authority Key Identifier)

预期: 失败 (红)

证据来源: 第一轮测试执行 .trae/workflow/REQ-20260611-01/debug/task_T-01/debug_T-01_v1_problem.py
      输出:
        [v1_problem] SSLError (EXPECTED, this is the bug to confirm):
          SSLError: ... [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: Missing Authority Key Identifier ...
"""
