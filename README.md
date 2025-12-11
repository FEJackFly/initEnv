# initEnv - 环境快速配置工具

一键配置 Linux/macOS 开发环境，支持 Docker 容器，集成 sing-box 全局代理（TUN 模式）。

## 📦 项目文件

```
initEnv/
├── init.sh                  # 主安装脚本（系统环境配置）
├── install-singbox.sh       # sing-box 自动安装脚本
├── singbox-config.json      # sing-box 配置文件（已配置 VLESS 节点）
├── SINGBOX_GUIDE.md         # sing-box 详细使用指南
├── starship.toml            # Starship 提示符配置
├── .zshrc                   # Zsh 配置文件
└── README.md                # 本文件
```

## 🚀 快速开始

### 场景 1：在 Docker 容器中使用

```bash
# 1. 启动容器并挂载项目
docker run -it --privileged --cap-add=NET_ADMIN \
  -v /path/to/initEnv:/initEnv \
  ubuntu:latest

# 2. 进入项目目录
cd /initEnv

# 3. 运行主脚本（配置系统环境）
sh init.sh

# 4. 安装 sing-box 代理（可选）
bash install-singbox.sh
```

### 场景 2：在 Linux 服务器上使用

```bash
# 克隆项目
git clone https://github.com/YourUsername/initEnv.git
cd initEnv

# 运行主脚本（需要 sudo）
sudo sh init.sh

# 安装代理（可选）
sudo bash install-singbox.sh
```

### 场景 3：在 macOS 上使用

```bash
# 克隆项目
git clone https://github.com/YourUsername/initEnv.git
cd initEnv

# 运行主脚本
sh init.sh
```

## 📋 功能特性

### init.sh - 系统环境配置

✅ **自动检测环境**

-   Docker 容器检测
-   系统架构识别
-   Root/普通用户判断

✅ **Linux 环境配置**

-   软件源切换（国内镜像加速）
-   中文语言支持
-   常用工具安装（git, vim, zsh, npm 等）
-   SSH 服务配置
-   Docker 安装（非容器环境）

✅ **Shell 环境美化**

-   Oh My Zsh + 插件
-   Starship 提示符
-   自动补全和语法高亮

✅ **macOS 专属**

-   Homebrew 自动安装
-   常用软件批量安装
-   Nerd Font 字体安装

### install-singbox.sh - 代理配置

✅ **全自动安装**

-   架构自动检测（amd64/arm64/armv7）
-   最新版本下载
-   systemd 服务配置
-   自动测试连接

✅ **TUN 模式透明代理**

-   全局系统级代理
-   无需为每个应用配置
-   智能分流（国内直连，国外代理）
-   DNS 防污染

✅ **已配置节点**

-   协议：VLESS
-   服务器：vpn.920601.xyz:27469
-   开箱即用

## 🎯 核心优势

### 1. 容器友好设计

```bash
# 传统脚本的问题：
❌ systemd 不可用导致服务启动失败
❌ root 用户配置 shell 需要多次运行
❌ Docker-in-Docker 冲突

# 本项目的解决方案：
✅ 智能检测容器环境
✅ 自动使用 service 或直接启动服务
✅ root 用户一次完成所有配置
✅ 跳过不兼容的操作
```

### 2. 开箱即用的代理

```bash
# 只需两条命令：
sh init.sh                    # 配置系统
bash install-singbox.sh       # 安装代理

# 即可实现：
✅ 全局透明代理（TUN 模式）
✅ 国内直连，国外加速
✅ 广告拦截
✅ DNS 防污染
```

### 3. 完整的文档支持

-   📖 [SINGBOX_GUIDE.md](./SINGBOX_GUIDE.md) - 详细使用指南
-   🛠️ 故障排查步骤
-   💡 进阶配置示例
-   📝 快速命令参考

## 🔧 配置说明

### 修改代理节点

编辑 `singbox-config.json`，替换为你的节点：

```json
{
    "outbounds": [
        {
            "type": "vless",
            "tag": "your-node",
            "server": "your-server.com",
            "server_port": 443,
            "uuid": "your-uuid"
        }
    ]
}
```

### 添加多个节点

```json
{
  "outbounds": [
    {"tag": "node1", "server": "server1.com", ...},
    {"tag": "node2", "server": "server2.com", ...}
  ],
  "route": {
    "final": "node1"  // 默认使用节点1
  }
}
```

### 自定义分流规则

```json
{
    "route": {
        "rules": [
            { "domain": ["github.com"], "outbound": "proxy" },
            { "geoip": "cn", "outbound": "direct" }
        ]
    }
}
```

## 📊 使用流程图

```
┌─────────────────┐
│  运行 init.sh   │
└────────┬────────┘
         │
         ├─ 检测环境（容器/物理机）
         ├─ 安装基础工具
         ├─ 配置软件源
         ├─ 安装 SSH
         ├─ 配置 Shell (Zsh + Starship)
         └─ 提示安装代理
                │
                ↓
      ┌─────────────────────┐
      │ bash install-singbox.sh │
      └──────────┬──────────┘
                 │
                 ├─ 下载 sing-box
                 ├─ 配置 TUN 模式
                 ├─ 创建 systemd 服务
                 ├─ 启动并测试
                 └─ ✓ 完成
```

## 🧪 验证安装

### 检查系统环境

```bash
# 查看 shell
echo $SHELL

# 查看 starship
starship --version

# 查看 Node.js
node -v
npm -v
```

### 检查代理

```bash
# 查看服务状态
systemctl status sing-box

# 测试 Google
curl -I https://www.google.com

# 查看当前 IP
curl https://api.ip.sb/ip

# 查看 TUN 设备
ip addr show tun0
```

## ⚠️ 注意事项

### Docker 容器要求

使用 sing-box TUN 模式需要特权：

```bash
docker run -it \
  --privileged \              # 特权模式
  --cap-add=NET_ADMIN \       # 网络管理权限
  -v $(pwd):/initEnv \
  ubuntu:latest
```

### 权限要求

-   init.sh：需要 root 权限（Linux）
-   install-singbox.sh：需要 root 权限
-   TUN 模式：需要 NET_ADMIN 权限

### 网络要求

首次安装需要访问：

-   GitHub (下载工具和配置)
-   各镜像站（软件包安装）
-   npm registry（Node.js 包）

## 🐛 故障排查

### SSH 无法启动（容器环境）

```bash
# 手动启动
/usr/sbin/sshd

# 查看进程
ps aux | grep sshd
```

### sing-box 服务失败

```bash
# 检查配置
sing-box check -c /etc/sing-box/config.json

# 查看日志
journalctl -u sing-box -n 50

# 前台运行
sing-box run -c /etc/sing-box/config.json
```

### TUN 设备创建失败

```bash
# 加载内核模块
modprobe tun

# 检查设备
ls -l /dev/net/tun
```

## 📚 相关文档

-   [sing-box 官方文档](https://sing-box.sagernet.org/)
-   [Oh My Zsh 文档](https://ohmyz.sh/)
-   [Starship 文档](https://starship.rs/)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

---

**快速链接：**

-   📖 [sing-box 详细指南](./SINGBOX_GUIDE.md)
-   🔧 [配置文件](./singbox-config.json)
-   🚀 [安装脚本](./install-singbox.sh)
