# initEnv - 开发环境一键配置

> 🚀 Linux/macOS/WSL 环境自动化配置脚本

一个功能完整的开发环境配置脚本，自动安装和配置常用开发工具、美化终端、管理软件包。

---

## ✨ 主要特性

- 🎯 **跨平台支持** - Linux (Ubuntu/Debian)、macOS 全平台支持
- 🐳 **智能环境检测** - 自动识别 Docker 容器、WSL、物理机
- 🎨 **终端美化** - Oh My Zsh + Starship + Nerd Font 字体
- 📦 **自动化安装** - 开发工具、npm 包、macOS 应用一键部署
- 🔄 **Node.js 管理** - 自动升级到最新稳定版
- 📝 **详细日志** - 每一步都有清晰的进度提示

---

## 🚀 快速开始

```bash
# 克隆仓库
git clone <your-repo-url> ~/initEnv
cd ~/initEnv

# Linux 环境（需要 root 权限配置系统）
sudo bash init.sh -y

# macOS 环境（普通用户运行）
bash init.sh -y

# 交互式配置（手动确认每一步）
bash init.sh
```

**参数说明**:
- `-y` 或 `--yes`: 自动确认，无需手动输入（物理机环境仍会提示）

---

## 📦 安装内容

### 🐧 Linux 环境

#### 系统工具
- ✅ 基础工具包：`curl`, `wget`, `git`, `vim`, `zsh`, `npm`, `openssh-server`
- ✅ 语言环境：中文 (zh_CN.UTF-8) + 英文 (en_US.UTF-8)
- ✅ 软件源加速：自动切换国内镜像（使用 chsrc）
- ✅ SSH 服务：自动配置并启动
- ✅ Docker：自动安装（非容器环境）

#### 终端美化
- ✅ **Starship** - 跨 Shell 提示符
- ✅ **CaskaydiaCove Nerd Font** - 支持图标的等宽字体
- ✅ **Oh My Zsh** + 插件（zsh-autosuggestions, zsh-syntax-highlighting）

#### npm 全局包
- `vtop` - 可视化系统监控
- `n` - Node.js 版本管理
- `live-server` - 实时刷新的开发服务器
- `pm2` - 进程管理器
- `nodemon` - 自动重启工具
- `nrm` - npm 源管理

#### Node.js
- ✅ 自动升级到最新稳定版（使用 n 工具）
- ✅ 配置 N_PREFIX 避免权限问题

---

### 🍎 macOS 环境

#### 系统工具
- ✅ **Homebrew** - 自动安装（如未安装）
- ✅ 基础工具：`wget`, `git`, `htop`, `node`, `zsh`, `starship`, `neofetch`
- ✅ **CaskaydiaCove Nerd Font** - 通过 Homebrew Cask 安装

#### 终端美化
- ✅ 同 Linux 环境配置

#### 自动安装的应用 (setup_brew)
- 📱 **社交通讯**：微信 (WeChat)、飞书 (Feishu)
- 🎵 **娱乐影音**：网易云音乐、喜马拉雅
- 💻 **开发工具**：VS Code、Windsurf
- 🖥️ **终端工具**：Warp、OpenInTerminal
- 🌐 **浏览器**：Google Chrome
- 🧹 **系统工具**：腾讯柠檬清理

---

## 📁 项目结构

```
initEnv/
├── init.sh                  # 🔧 主安装脚本
├── .zshrc                   # 🐚 Zsh 配置文件
├── starship.toml            # ⭐ Starship 提示符配置
├── README.md                # 📖 本文档
└── wsl/                     # 🪟 WSL 专用配置
    ├── .wslconfig           # WSL 全局配置
    ├── wsl.conf             # WSL 发行版配置
    └── wsl.md               # WSL 完整使用指南
```

---

## 🎯 使用场景

### 场景 1: Linux 服务器/容器初始化

```bash
# 以 root 身份运行（会自动检测容器环境）
sudo bash init.sh -y
```

脚本会：
1. 安装系统工具和依赖
2. 配置 SSH 服务
3. 安装字体和终端美化
4. 安装 npm 包和升级 Node.js

### 场景 2: macOS 开发环境配置

```bash
# 普通用户运行
bash init.sh -y
```

脚本会：
1. 安装 Homebrew（如需要）
2. 安装开发工具
3. 安装 Nerd Font 字体
4. 配置终端美化
5. 批量安装常用应用

### 场景 3: WSL 环境配置

```bash
# 在 WSL 中以 sudo 运行
sudo bash init.sh -y
```

脚本会自动识别 WSL 环境并进行相应配置。

---

## 📝 配置文件说明

### .zshrc
- Oh My Zsh 配置
- 启用插件：git, zsh-autosuggestions, zsh-syntax-highlighting
- Starship 提示符集成
- 自定义别名和环境变量

### starship.toml
- 精心配置的提示符主题
- 显示 Git 状态、Node.js 版本等
- 支持 Nerd Font 图标

### 配置文件位置

| 配置           | 位置                                 | 备份位置                          |
| -------------- | ------------------------------------ | --------------------------------- |
| Zsh 配置       | `~/.zshrc`                           | `~/.zshrc.bak.<timestamp>`        |
| Starship 配置  | `~/.config/starship.toml`            | `~/.config/starship.toml.bak.*`   |
| WSL 全局配置   | `%UserProfile%\.wslconfig` (Windows) | -                                 |
| WSL 发行版配置 | `/etc/wsl.conf` (WSL 内)             | -                                 |
| 字体 (Linux)   | `~/.local/share/fonts/`              | -                                 |
| 字体 (macOS)   | `~/Library/Fonts/`                   | -                                 |

> 💡 脚本会自动备份现有配置文件，时间戳格式为 Unix 时间

---

## 🔍 详细功能说明

### 环境检测

脚本会自动检测：
- ✅ 操作系统（Linux / macOS）
- ✅ 运行环境（Docker 容器 / WSL / 物理机）
- ✅ CPU 架构（x86_64 / ARM64）
- ✅ 用户权限（root / 普通用户）

### 智能执行逻辑

**Linux 物理机 + root 用户**：
1. 配置系统环境
2. 提示创建普通用户（或 10 秒后继续）
3. 为 root 配置 Shell

**Linux 容器 + root 用户**：
1. 配置系统环境
2. 直接为 root 配置 Shell（容器场景常用）

**Linux 普通用户**：
1. 仅配置 Shell 环境（不需要系统级权限）

**macOS**：
1. 安装 Homebrew 和工具
2. 配置 Shell 环境
3. 批量安装应用

### npm 包安装

脚本会显示详细的安装进度：
```
✓ 正在安装全局 npm 包 (vtop, n, live-server, pm2, nodemon, nrm)...
✓ 这可能需要几分钟，请耐心等待...
[npm 安装输出...]
✓ npm 全局包安装完成
```

> ⚠️ 注意：可能会看到 `npm WARN deprecated` 警告，这是正常的依赖弃用提示，不影响功能使用。

### Node.js 升级

使用 `n` 工具自动升级到最新稳定版：
```
✓ 正在使用 n 更新 Node.js 到最新稳定版（可能需要几分钟）...
  installing : node-v24.12.0
✓ Node.js 更新成功: v24.12.0
```

---

## 🛠️ WSL 配置

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

---

## 🔧 故障排查

### 权限问题

**npm 全局包安装失败（EACCES）**：
```bash
# 使用 sudo 运行脚本（Linux）
sudo bash init.sh -y

# 或手动设置 npm 前缀
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
```

**字体安装失败**：
- Linux: 检查是否有 `~/.local/share/fonts/` 目录权限
- macOS: 检查 Homebrew 是否正常工作

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

# 查看日志
sudo journalctl -u ssh
```

### 脚本看起来卡住了

脚本已配置详细日志输出。如果看起来没有进度：
- npm 包安装可能需要几分钟（特别是首次安装）
- Node.js 下载可能较慢（取决于网络速度）
- 可以查看终端输出，通常会显示下载进度

---

## 📌 注意事项

1. **备份重要配置**：虽然脚本会自动备份，建议手动备份重要配置
2. **网络要求**：需要稳定的网络连接下载软件包
3. **权限要求**：
   - Linux 系统配置需要 root 权限（sudo）
   - macOS 仅需普通用户权限
4. **执行时间**：完整安装可能需要 5-15 分钟，取决于网络速度
5. **macOS 应用**：`setup_brew()` 会强制重装所有应用到最新版

---

## 🔄 更新日志

### [2025-12-15] - 功能合并与增强

**新增功能**:
- ✅ Linux 环境添加 Nerd Font 字体安装
- ✅ 恢复 Node.js 自动升级功能（使用 n 工具）
- ✅ 恢复 macOS 应用批量安装（setup_brew）
- ✅ 添加 `nrm` npm 包
- ✅ 大幅增强日志输出，每一步都有详细提示

**改进**:
- ✅ 更好的错误处理和用户提示
- ✅ 智能检测已安装内容，避免重复安装
- ✅ 配置文件自动备份带时间戳
- ✅ 字体安装失败不会中断脚本执行

### [2025-12-11] - 移除代理功能

**代码清理**:
- ✅ 专注于系统环境配置
- ✅ 简化参数处理

**文档整合**:
- ✅ 清理所有代理相关文档
- ✅ 更新 README.md

---

## 📄 许可证

MIT License

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**Happy Coding! 🎉**
