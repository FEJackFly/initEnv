# sing-box 使用指南

本指南介绍如何在 Linux 环境（包括 Docker 容器）中使用 sing-box 作为全局透明代理（TUN 模式）。

## 🎯 环境检测与模式选择

安装脚本会**自动检测运行环境**并选择最佳配置：

| 环境              | 检测方式                               | 使用模式                     | 原因                                              |
| ----------------- | -------------------------------------- | ---------------------------- | ------------------------------------------------- |
| **Docker 容器**   | 检测 `/.dockerenv` 或 `/proc/1/cgroup` | HTTP/SOCKS5 代理（禁用 TUN） | 容器内开启 TUN 需要特权模式，使用 HTTP 代理更简单 |
| **物理机/虚拟机** | systemd 进程                           | TUN 模式（全局透明代理）     | 全局代理，无需为每个应用配置                      |

### 容器环境 (HTTP 代理模式)

-   ✅ 监听端口：`0.0.0.0:2080`（混合 HTTP/SOCKS5）
-   ✅ 使用方式：设置环境变量 `http_proxy` 和 `https_proxy`
-   ✅ 智能分流：国内直连，国外代理

### 物理机环境 (TUN 模式)

-   ✅ TUN 设备：`tun0`（虚拟网卡）
-   ✅ 全局透明代理：所有流量自动经过代理
-   ✅ 额外提供：`127.0.0.1:2080`（HTTP/SOCKS5）

## 📦 文件列表

-   **`singbox-config.json`** - sing-box 配置文件（物理机用，启用 TUN）
-   **`install-singbox.sh`** - 一键安装脚本（自动检测环境）
-   **`check-singbox.sh`** - 状态检查脚本
-   **`SINGBOX_GUIDE.md`** - 本文档

## 📋 配置文件说明

### 已配置节点信息

-   **协议**: VLESS
-   **服务器**: vpn.920601.xyz
-   **端口**: 27469
-   **UUID**: 11ddd3ac-2457-4f2b-a72e-721fd44c432a
-   **节点名称**: zj0ppfq6

## 🚀 快速部署

### 方法一：使用安装脚本（推荐）

```bash
# 在 initEnv 目录下
cd /path/to/initEnv

# 运行安装脚本（需要 root 权限）
sudo bash install-singbox.sh
```

脚本会自动完成：

-   ✅ 检测系统架构
-   ✅ 下载并安装 sing-box
-   ✅ 复制配置文件到 /etc/sing-box/
-   ✅ 下载 GeoIP 和 GeoSite 数据库
-   ✅ 创建 systemd 服务
-   ✅ 启动服务并测试连接

### 方法二：手动安装

```bash
# 1. 下载 sing-box
wget https://github.com/SagerNet/sing-box/releases/download/v1.8.0/sing-box-1.8.0-linux-amd64.tar.gz
tar -xzf sing-box-1.8.0-linux-amd64.tar.gz
sudo mv sing-box-1.8.0-linux-amd64/sing-box /usr/local/bin/
sudo chmod +x /usr/local/bin/sing-box

# 2. 创建配置目录
sudo mkdir -p /etc/sing-box

# 3. 复制配置文件
sudo cp singbox-config.json /etc/sing-box/config.json

# 4. 下载 GeoIP/GeoSite 数据库
cd /etc/sing-box
sudo wget https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db
sudo wget https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db

# 5. 运行测试
sudo sing-box run -c /etc/sing-box/config.json
```

## 🎛️ 功能说明

### TUN 模式（全局透明代理）

-   **TUN 设备**: tun0
-   **虚拟 IP**: 172.19.0.1/30
-   **自动路由**: 已启用
-   **DNS 劫持**: 已启用

所有系统流量会自动通过 TUN 设备处理，无需为每个应用配置代理。

### HTTP/SOCKS5 代理

-   **监听地址**: 127.0.0.1:2080
-   **协议**: Mixed (HTTP + SOCKS5)

如果某些应用不支持 TUN 模式，可以手动配置代理：

```bash
export http_proxy=http://127.0.0.1:2080
export https_proxy=http://127.0.0.1:2080
```

### 分流规则

| 目标          | 行为 | 说明                |
| ------------- | ---- | ------------------- |
| 国内网站 (CN) | 直连 | 基于 GeoSite 数据库 |
| 国内 IP (CN)  | 直连 | 基于 GeoIP 数据库   |
| 广告域名      | 拦截 | 基于广告过滤列表    |
| 其他          | 代理 | 通过 VLESS 节点     |

### DNS 配置

-   **国内域名**: 使用阿里 DNS (223.5.5.5)
-   **国外域名**: 使用 Google DoH (8.8.8.8)
-   **防污染**: 已启用 FakeIP

## 🔧 服务管理

### systemd 命令

```bash
# 启动服务
sudo systemctl start sing-box

# 停止服务
sudo systemctl stop sing-box

# 重启服务
sudo systemctl restart sing-box

# 查看状态
sudo systemctl status sing-box

# 开机自启
sudo systemctl enable sing-box

# 禁止自启
sudo systemctl disable sing-box
```

### 日志查看

```bash
# 查看实时日志
sudo journalctl -u sing-box -f

# 查看最近 100 行
sudo journalctl -u sing-box -n 100

# 查看今天的日志
sudo journalctl -u sing-box --since today
```

## 📝 配置文件修改

### 添加多个节点

编辑 `/etc/sing-box/config.json`，在 `outbounds` 数组中添加：

```json
{
    "outbounds": [
        {
            "type": "vless",
            "tag": "node1",
            "server": "server1.com",
            "server_port": 443,
            "uuid": "your-uuid"
        },
        {
            "type": "vless",
            "tag": "node2",
            "server": "server2.com",
            "server_port": 443,
            "uuid": "your-uuid"
        }
    ]
}
```

然后修改路由规则中的 `final` 为你想用的节点标签。

### 修改分流规则

在 `route.rules` 中添加自定义规则：

```json
{
    "route": {
        "rules": [
            {
                "domain": ["example.com"],
                "outbound": "direct"
            },
            {
                "ip_cidr": ["192.168.0.0/16"],
                "outbound": "direct"
            }
        ]
    }
}
```

### 禁用 TUN 模式

如果只想用 HTTP/SOCKS5 代理，不需要 TUN：

1. 编辑配置文件，删除或注释 `inbounds` 中的 TUN 配置
2. 重启服务：`sudo systemctl restart sing-box`

## 🧪 测试连接

### 测试代理是否工作

```bash
# 测试 Google
curl -I https://www.google.com

# 测试百度
curl -I https://www.baidu.com

# 查看当前 IP
curl https://api.ip.sb/ip
curl https://ipinfo.io/ip
```

### 查看路由表

```bash
# 查看 TUN 设备
ip addr show tun0

# 查看路由规则
ip route show table all | grep tun0

# 测试 DNS 解析
nslookup google.com 127.0.0.1
```

## ⚠️ 故障排查

### 服务无法启动

```bash
# 检查配置文件语法
sing-box check -c /etc/sing-box/config.json

# 查看详细错误
sudo journalctl -u sing-box -n 50 --no-pager
```

### TUN 设备创建失败

```bash
# 检查内核模块
sudo modprobe tun

# 检查 /dev/net/tun
ls -l /dev/net/tun
```

### 无法访问网络

```bash
# 1. 检查服务状态
sudo systemctl status sing-box

# 2. 测试节点连通性
ping vpn.920601.xyz

# 3. 临时停止服务
sudo systemctl stop sing-box

# 4. 前台运行查看日志
sudo sing-box run -c /etc/sing-box/config.json
```

### DNS 解析问题

```bash
# 检查 DNS 配置
cat /etc/resolv.conf

# 手动测试 DNS
dig @127.0.0.1 google.com
```

### 容器环境问题

#### 问题：测试脚本卡住不动

**原因**：sing-box 进程未运行，但 TUN 路由规则仍在，流量被路由到不存在的后端。

**解决方案**：

```bash
# 1. 快速检查
bash /code/check-singbox.sh

# 2. 检查进程
ps aux | grep sing-box

# 3. 重启 sing-box
start-singbox.sh

# 4. 查看日志
tail -f /var/log/sing-box.log
```

#### 问题：容器重启后 sing-box 未运行

**解决方案**：

```bash
# 重新启动 sing-box
docker exec ubuntu start-singbox.sh
```

#### 问题：curl 使用代理环境变量测试时超时

**原因**：TUN 模式已经是全局代理，不需要额外设置 `http_proxy` 环境变量。

**解决方案**：

```bash
# ❌ 错误方式（会导致路由冲突）
export http_proxy=http://127.0.0.1:2080
curl https://www.google.com

# ✅ 正确方式（直接使用 TUN）
unset http_proxy https_proxy
curl https://www.google.com
```

#### 容器环境快速命令

```bash
# 启动 sing-box
docker exec ubuntu start-singbox.sh

# 停止 sing-box
docker exec ubuntu stop-singbox.sh

# 查看状态
docker exec ubuntu ps aux | grep sing-box

# 查看日志
docker exec ubuntu tail -20 /var/log/sing-box.log

# 快速测试
docker exec ubuntu bash /code/test-singbox-simple.sh
```

#### 容器环境快速参考

```bash
# 启动 sing-box
docker exec ubuntu start-singbox.sh

# 停止 sing-box
docker exec ubuntu stop-singbox.sh

# 检查状态
docker exec ubuntu bash /code/check-singbox.sh

# 查看日志
docker exec ubuntu tail -20 /var/log/sing-box.log

# 进入容器
docker exec -it ubuntu zsh
```

## 🔄 订阅转换

如果你有订阅链接，想转换成 sing-box 配置：

### 使用在线工具

1. 访问：https://acl4ssr-sub.github.io/
2. 粘贴订阅链接
3. 选择 "sing-box" 格式
4. 下载配置文件

### 使用命令行工具

```bash
# 安装 subconverter
git clone https://github.com/tindy2013/subconverter.git
cd subconverter

# 转换订阅
./subconverter --singbox "订阅链接" > /etc/sing-box/config.json
```

## 📚 进阶配置

### 添加广告拦截

配置文件中已包含 `category-ads-all` 规则，会自动拦截常见广告域名。

### 配置 IPv6

```json
{
    "inbounds": [
        {
            "type": "tun",
            "inet6_address": "fdfe:dcba:9876::1/126"
        }
    ],
    "dns": {
        "strategy": "prefer_ipv4" // 或 "ipv4_only", "ipv6_only"
    }
}
```

### 性能优化

```json
{
    "inbounds": [
        {
            "type": "tun",
            "mtu": 9000, // 增加 MTU
            "gso": true, // 启用 GSO
            "udp_timeout": 300
        }
    ]
}
```

## 🆘 获取帮助

-   官方文档：https://sing-box.sagernet.org/
-   GitHub Issues：https://github.com/SagerNet/sing-box/issues
-   Telegram 群组：@SagerNet

## 📌 快速命令参考

```bash
# 重启服务
sudo systemctl restart sing-box

# 查看日志
sudo journalctl -u sing-box -f

# 测试配置
sing-box check -c /etc/sing-box/config.json

# 查看版本
sing-box version

# 查看 TUN 设备
ip addr show tun0

# 测试连接
curl https://www.google.com
```
