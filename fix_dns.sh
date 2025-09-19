#!/bin/bash
# 一键修复 DNS 脚本

# 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "请用 root 权限运行：sudo bash fix-dns.sh"
    exit 1
fi

echo "正在检测网络环境..."

# 测试 IPv4
ping -c1 -4 8.8.8.8 >/dev/null 2>&1 && ipv4_ok=1 || ipv4_ok=0

# 测试 IPv6
ping -c1 -6 2001:4860:4860::8888 >/dev/null 2>&1 && ipv6_ok=1 || ipv6_ok=0

# 清空 resolv.conf
echo "" > /etc/resolv.conf

if [ "$ipv4_ok" -eq 1 ]; then
    echo "检测到 IPv4 网络可用，设置 IPv4 DNS..."
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
fi

if [ "$ipv6_ok" -eq 1 ]; then
    echo "检测到 IPv6 网络可用，设置 IPv6 DNS..."
    echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
    echo "nameserver 2606:4700:4700::1111" >> /etc/resolv.conf
fi

if [ "$ipv4_ok" -eq 0 ] && [ "$ipv6_ok" -eq 0 ]; then
    echo "❌ 没有检测到可用的网络，请检查 VPS 网络连接。"
    exit 1
fi

echo "✅ DNS 修复完成，测试解析..."
ping -c 3 www.google.com
