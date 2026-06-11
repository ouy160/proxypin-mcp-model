"""
v1_problem - 问题确认脚本

目的: 验证 "将 verify=False 改为基于 ProxyPinCA.pem 的 verify=cert_path" 在 SOCKS5 代理模式下
      是否能成功 (即证书验证不失败 + 代理能正常抓取请求)。

当前架构: SOCKS5 代理 (socks5://127.0.0.1:9099) 只做 TCP 层转发, 不做 TLS MITM.
          客户端的 TLS 验证是直接对 api.minimaxi.com 公开 CA 签发的证书.

预期结果: 失败 (红)
    - 原因: verify=ProxyPinCA.pem 时, Python requests 会把 ProxyPinCA 当作 "信任的 CA 列表",
            但 api.minimaxi.com 的证书是由公开 CA 签发的, 链式验证会失败, 抛
            ssl.SSLCertVerificationError (或 urllib3.exceptions.SSLError).
    - 这一步是为了让代码说话, 证明在 SOCKS5 模式下, "使用 ProxyPinCA 作为 verify" 不可行.

运行: python .trae/workflow/REQ-20260611-01/debug/task_T-01/debug_T-01_v1_problem.py
"""
import sys
import warnings
import traceback

import requests
import urllib3

# 捕获 InsecureRequestWarning, 用来证明"未跳过证书验证"是预期行为
warnings.filterwarnings("error", category=urllib3.exceptions.InsecureRequestWarning)

URL = "https://api.minimaxi.com/anthropic/v1/messages"
PROXIES = {
    "http": "socks5://127.0.0.1:9099",
    "https": "socks5://127.0.0.1:9099",
}
CERT_PATH = r"C:\Users\1\Desktop\ProxyPinCA.pem"
TIMEOUT = 15

# 简化 headers (只需要 host 和 content-type, 触发实际的 HTTPS 调用)
HEADERS = {
    "host": "api.minimaxi.com",
    "content-type": "application/json",
    "x-api-key": "sk-test-invalid-key-just-for-tls-handshake",
    "anthropic-version": "2023-06-01",
}
DATA = {
    "model": "MiniMax-M2.7-highspeed",
    "messages": [{"role": "user", "content": "ping"}],
    "max_tokens": 16,
    "stream": False,
}


def main() -> int:
    print(f"[v1_problem] cert={CERT_PATH}")
    print(f"[v1_problem] cert exists={__import__('os').path.exists(CERT_PATH)}")
    print(f"[v1_problem] verify=cert_path (期望: InsecureRequestWarning 不应被 raise, 但 SSL 验证可能失败)")
    try:
        # 关键改动: verify 从 False 改为 cert 路径
        res = requests.post(URL, headers=HEADERS, json=DATA, timeout=TIMEOUT, proxies=PROXIES, verify=CERT_PATH)
        print(f"[v1_problem] HTTP {res.status_code} (unexpected, expected failure)")
        return 0  # 不应到达
    except urllib3.exceptions.InsecureRequestWarning as w:
        print(f"[v1_problem] InsecureRequestWarning raised -> 证书验证未生效 (unexpected)")
        return 2
    except requests.exceptions.SSLError as e:
        print(f"[v1_problem] SSLError (EXPECTED, this is the bug to confirm):")
        print(f"  {type(e).__name__}: {str(e)[:300]}")
        return 1  # 预期: 红灯
    except Exception as e:
        print(f"[v1_problem] {type(e).__name__}: {str(e)[:300]}")
        print(traceback.format_exc())
        return 1


if __name__ == "__main__":
    sys.exit(main())
