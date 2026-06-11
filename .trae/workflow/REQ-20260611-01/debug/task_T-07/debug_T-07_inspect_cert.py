"""T-07 调试: 查看 proxypin 生成的伪证书的实际内容"""
import os
import ssl
import socket
import struct

# 通过 SOCKS5 代理连接到 api.minimaxi.com:443
# 抓取客户端收到的 ServerHello + Certificate
# 然后用 OpenSSL 解析证书

import urllib3

# 用 requests 但只获取证书信息 (CONNECT 但不验证)
# 不太容易, 改用 OpenSSL 命令行
print("Use OpenSSL to inspect the leaf cert:")
print()
print("Step 1: 获取伪证书 (需要禁用 MITM 的 ProxyPin 路径)")
print("Step 2: 用 openssl x509 -text -noout 查看证书")
print()

# 另一种方法: 用 Python 直接生成伪证书
import sys
sys.path.insert(0, '.')

# 通过 import 间接调用
import subprocess
result = subprocess.run(['openssl', 'x509', '-in', 'assets/certs/ca.crt', '-text', '-noout'], capture_output=True, text=True)
print("CA cert content:")
print(result.stdout[:3000])
