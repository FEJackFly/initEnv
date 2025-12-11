# initEnv - 开发环境一键配置

> 🚀 Linux/macOS/WSL 环境自动化配置

---

## 快速开始

```bash
# 一键配置
bash init.sh -y

# 或交互式配置
bash init.sh
```

**参数说明**:

-   `-y` 或 `--yes`: 自动确认，无需手动输入

---

## 项目文件

```
initEnv/
├── init.sh                  # 统一安装脚本
├── starship.toml            # Starship 提示符配置
├── .zshrc                   # Zsh 配置文件
└── wsl/                     # WSL 专用配置
    ├── .wslconfig           # WSL 全局配置
    ├── wsl.conf             # WSL 发行版配置
    └── wsl.md               # WSL 完整使用指南
```

---

## 功能特性

### 🔧 系统配置

**自动检测环境**:

-   ✅ WSL / Docker 容器 / 物理机
-   ✅ Linux (Ubuntu/Debian) / macOS
-   ✅ x86_64 / ARM64 架构

**Linux 环境**:

-   ✅ 常用工具安装（git, vim, curl, wget, zsh, npm）
-   ✅ 软件源切换（国内镜像加速）
-   ✅ SSH 服务配置
-   ✅ Docker 安装（非容器环境）
-   ✅ 中文语言支持

**macOS 环境**:

-   ✅ Homebrew 自动安装
-   ✅ 常用工具安装

**Shell 美化**:

-   ✅ Oh My Zsh + 插件（autosuggestions, syntax-highlighting）
-   ✅ Starship 跨 Shell 提示符
-   ✅ 自动补全和语法高亮

---

## 使用指南

### 基础使用

```bash
# 最简单的方式（推荐）
bash init.sh -y

# 交互式配置（手动确认）
bash init.sh
```

---

## WSL 配置

> 详细文档: [wsl/wsl.md](./wsl/wsl.md)

### 常用命令

```bash
wsl -l -v                    # 查看已安装的发行版
wsl --shutdown               # 关闭所有 WSL
wsl -u root                  # 以 root 运行
```

### 启用 systemd

```bash
# 编辑 /etc/wsl.conf
sudo nano /etc/wsl.conf

# 添加
[boot]
systemd=true

# 重启 WSL (在 PowerShell 中)
wsl --shutdown
wsl
```

### 配置文件

**`.wslconfig`** (Windows: `%UserProfile%\.wslconfig`):

```ini
[wsl2]
memory=4GB                    # 内存限制
processors=2                  # CPU 核心
swap=0                        # 禁用交换

[experimental]
sparseVhd=true                # 自动回收磁盘
autoMemoryReclaim=gradual     # 自动内存回收
```

**`wsl.conf`** (WSL 内: `/etc/wsl.conf`):

```ini
[boot]
systemd=true

[automount]
root=/                        # 挂载到 /c 而非 /mnt/c
options="metadata,uid=1000,gid=1000,umask=022"

[network]
generateResolvConf=false      # 手动管理 DNS
```

---

## 故障排查

### WSL 网络问题

```bash
# 重置网络
wsl --shutdown

# 重建 DNS
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
```

### SSH 无法启动（容器）

```bash
# 手动启动
/usr/sbin/sshd

# 检查进程
ps aux | grep sshd
```

---

## 快速命令参考

### 安装

```bash
# 完整安装（推荐）
bash init.sh -y

# 交互式安装
bash init.sh
```

---

## 配置文件位置

| 配置           | 位置                                 |
| -------------- | ------------------------------------ |
| Zsh 配置       | `~/.zshrc`                           |
| Starship 配置  | `~/.config/starship.toml`            |
| WSL 全局配置   | `%UserProfile%\.wslconfig` (Windows) |
| WSL 发行版配置 | `/etc/wsl.conf` (WSL 内)             |

---

## 更新日志

### [2025-12-11] - 移除代理功能

**代码清理**:

-   ✅ 专注于系统环境配置
-   ✅ 简化参数处理

**文档整合**:

-   ✅ 清理所有代理相关文档
-   ✅ 更新 README.md

---

## 许可证

MIT License
