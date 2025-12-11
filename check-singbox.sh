#!/bin/zsh
# sing-box 状态检查脚本（适配容器环境）

echo '🔍 sing-box 状态检查'
echo ''

echo '1️⃣ 进程状态:'
ps aux | grep '[s]ing-box' || echo '❌ 未找到 sing-box 进程'
echo ''

echo '2️⃣ 端口监听 (使用 lsof):'
if command -v lsof > /dev/null 2>&1; then
    lsof -i :2080 2>/dev/null || echo '❌ 端口 2080 未监听'
else
    # 尝试用 netstat
    if command -v netstat > /dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep 2080 || echo '⚠ 端口检查失败（需要安装 net-tools）'
    else
        echo '⚠ 跳过端口检查（缺少工具）'
    fi
fi
echo ''

echo '3️⃣ sing-box 日志 (最后 10 行):'
if [ -f /var/log/sing-box.log ]; then
    tail -10 /var/log/sing-box.log
else
    echo '⚠ 日志文件不存在'
fi
echo ''

echo '4️⃣ 测试连接 Google (不通过 HTTP 代理):'
# TUN 模式应该是全局的，不需要设置代理环境变量
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
timeout 8 curl -v --max-time 5 https://www.google.com 2>&1 | head -10
echo ''

echo '5️⃣ 查看 IP:'
timeout 8 curl --max-time 5 https://api.ip.sb/ip 2>&1
echo ''

echo '✅ 检查完成'
