"""通过代理抓取 server cert 并保存"""
import ssl
import socket
import subprocess

# 用 python 通过 SOCKS5 代理获取证书
import urllib3
import warnings

# 用 curl 通过代理获取 server certificate chain
# 实际上更简单: 用 OpenSSL 客户端通过代理连接, 保存证书

import os

# 写入一个测试请求脚本
print("Save cert from proxypin MITM by using openssl s_client through proxy")
print()
print("Use the s_client output saved to /tmp/server_chain.pem")
