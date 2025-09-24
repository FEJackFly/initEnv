<!--
 * @Author: luofei 501177081@qq.com
 * @Date: 2023-12-18 16:29:20
 * @LastEditors: luofei 501177081@qq.com
 * @LastEditTime: 2023-12-19 14:03:03
 * @FilePath: /initEnv/README.md
 * @Description:
 *
-->

# initEnv 初始化脚本

`init.sh` 用于在全新或重装后的机器上快速完成常用开发环境配置，兼容 macOS 与 Ubuntu (基于 Debian 的 Linux)。脚本会根据系统类型自动调用不同的安装流程。

## 支持平台

- macOS (Intel/Apple Silicon)
- Ubuntu 20.04 及以上版本

## 快速开始

1. 确保网络可用，并具备 `curl`/`git` 等基本工具。
2. 克隆仓库或下载脚本：
   ```bash
   git clone https://github.com/yourname/initEnv.git
   cd initEnv
   ```
3. 赋予脚本执行权限：
   ```bash
   chmod +x init.sh
   ```

### macOS 执行方式

- **直接运行**（请勿使用 `sudo`）：
  ```bash
  ./init.sh
  ```
- 脚本会在执行过程中请求安装 Homebrew、应用及字体，可能需要输入密码。
- 运行结束后建议重新打开终端以加载新的 shell 配置。

### Ubuntu 执行方式

Ubuntu 的初始化需要分两次执行：

1. **以 root 或使用 `sudo` 运行**（用于系统级配置）
   ```bash
   sudo ./init.sh
   ```
   完成后脚本会提示再次以普通用户运行。
2. **切换到普通用户再次运行**（完成 shell 与 Node.js 配置）
   ```bash
   ./init.sh
   ```

## 功能概览

### Ubuntu (`setup_ubuntu`)

- 校验是否具有 root 权限。
- 下载并使用 `chsrc` 工具切换 apt 与 npm 软件源（基于 Gitee 镜像）。
- 安装中文语言包并更新系统区域设置。
- 安装常用命令行工具：`curl`、`wget`、`ping`、`htop`、`git`、`vim`、`neofetch`、`zsh`、`npm`。
- 安装 Starship 跨 shell 提示符。

> 运行结束后需再次以普通用户执行脚本，以便完成 shell 配置。

### macOS (`setup_macos`)

- 检查并安装 Homebrew。
- 通过 Homebrew 安装常用命令行工具：`wget`、`git`、`htop`、`node`、`zsh`、`starship`、`neofetch`。
- 检查 `CaskaydiaCove Nerd Font Mono` 字体是否真正安装；如缺失将卸载后重新安装，确保字体文件存在于 `~/Library/Fonts/`。

### Shell 配置 (`setup_shell`)

- 仅允许普通用户运行，避免 root 覆盖用户配置。
- 安装 Oh My Zsh（未安装时）。
- 安装 Zsh 插件：`zsh-autosuggestions` 与 `zsh-syntax-highlighting`。
- 备份现有 `~/.zshrc` 与 `~/.config/starship.toml`，并将仓库中的 `.zshrc`、`starship.toml` 拷贝到对应目录。
- 安装全局 npm 包：`vtop`、`n`、`live-server`、`pm2`、`nodemon`、`nrm`。
- 设置 `N_PREFIX=$HOME/.n`，使用 `n` 将 Node.js 更新至最新稳定版，避免系统级权限问题。
- 将默认登录 shell 切换为 Zsh（若当前不是 Zsh）。

> 请确保在仓库根目录运行脚本，以便正确复制 `.zshrc` 与 `starship.toml`。

### macOS 应用安装 (`setup_brew`)

使用 Homebrew Cask 强制安装/更新以下桌面应用（均使用 `--force`，已安装也会覆盖更新）：

- WeChat
- 飞书 (Feishu)
- 网易云音乐
- 喜马拉雅
- Warp
- OpenInTerminal
- 腾讯柠檬清理
- Windsurf
- Visual Studio Code
- Google Chrome

## 注意事项

- **权限要求**：Ubuntu 部分需以 root 执行；macOS 整体需以普通用户运行，脚本内部会在需要时请求管理员密码。
- **网络依赖**：脚本大量使用 `curl`、`git clone` 与 Homebrew，需保持稳定的网络连接。
- **备份策略**：原有的 `~/.zshrc` 和 `~/.config/starship.toml` 会自动备份为带时间戳的 `*.bak.<timestamp>` 文件。
- **重复执行**：脚本具备幂等性，但 Homebrew Cask 安装使用 `--force`，可能强制覆盖已有应用版本。
- **字体验证**：macOS 会验证 `CaskaydiaCove` 字体文件是否存在，不存在时重新安装。

## 故障排查

- 遇到网络下载失败，可重试执行脚本或先手动配置网络代理。
- 如果 `n stable` 执行失败，请确认 `~/.n` 目录权限是否正确，并检查 `npm` 是否可用。
- 若默认 shell 未切换，可手动执行 `chsh -s $(which zsh)` 后重新登录。

## 许可证

依据项目实际情况补充（如需）。
