# 🚀 sing-box 快速开始

一键部署 sing-box 透明代理，**自动检测环境**，选择最佳配置：

-   **Docker 容器**：HTTP/SOCKS5 代理模式（无需特权）
-   **物理机/虚拟机**：TUN 透明代理模式（全局代理）

## 🎯 环境自动检测

安装脚本会自动识别运行环境：

| 环境          | 使用模式            | 说明                           |
| ------------- | ------------------- | ------------------------------ |
| Docker 容器   | HTTP 代理 (`:2080`) | 无需特权模式，通过环境变量使用 |
| 物理机/虚拟机 | TUN 全局代理        | 所有流量自动代理，无需配置     |

## 📦 文件说明

| 文件                  | 说明                          |
| --------------------- | ----------------------------- |
| `singbox-config.json` | 配置文件（已配置 VLESS 节点） |
| `install-singbox.sh`  | 一键安装脚本                  |
| `check-singbox.sh`    | 状态检查脚本                  |
| `SINGBOX_GUIDE.md`    | 完整使用指南                  |

## ⚡ 快速开始

### Docker 容器环境

```bash
# 1. 安装（仅首次）
docker exec ubuntu bash /code/install-singbox.sh

# 2. 启动
docker exec ubuntu start-singbox.sh

# 3. 设置代理环境变量（容器内使用）
docker exec ubuntu zsh -c "
  export http_proxy=http://127.0.0.1:2080
  export https_proxy=http://127.0.0.1:2080
  curl https://www.google.com
"

# 或者在容器的 .zshrc 中添加：
# export http_proxy=http://127.0.0.1:2080
# export https_proxy=http://127.0.0.1:2080

# 4. 检查状态
docker exec ubuntu bash /code/check-singbox.sh
```

**容器环境说明**：

-   使用 HTTP/SOCKS5 代理模式（端口 2080）
-   需要为每个命令设置 `http_proxy` 环境变量
-   或者在 shell 配置文件中永久设置

### 物理机 / 虚拟机

```bash
# 1. 安装
sudo bash install-singbox.sh

# 2. 管理服务
sudo systemctl start sing-box   # 启动
sudo systemctl status sing-box  # 查看状态
sudo systemctl stop sing-box    # 停止

# 3. 测试
curl https://www.google.com
```

## 🎯 核心特性

-   ✅ **TUN 透明代理** - 全局生效，无需为每个应用配置
-   ✅ **智能分流** - 国内直连，国外代理
-   ✅ **广告拦截** - 自动过滤广告域名
-   ✅ **DNS 优化** - DoH 加密 DNS，防污染

## 📝 详细文档

查看 `SINGBOX_GUIDE.md` 获取完整使用指南。

## 🆘 常见问题

### 测试时卡住？

```bash
# 重启 sing-box
docker exec ubuntu start-singbox.sh  # 容器
sudo systemctl restart sing-box      # 物理机
```

### 容器重启后失效？

```bash
# 重新启动 sing-box
docker exec ubuntu start-singbox.sh
```

### 查看日志

```bash
# 容器
docker exec ubuntu tail -f /var/log/sing-box.log

# 物理机
sudo journalctl -u sing-box -f
```
