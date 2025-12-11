#!/bin/sh

# 脚本出错时立即退出
set -e

# --- 函数定义 ---

# 打印普通信息
log_info() {
    echo "INFO: $1"
}

# 打印错误信息
log_error() {
    echo "ERROR: $1" >&2
}

# 检测是否在容器环境中运行
is_container() {
    # 方法1: 检查 /.dockerenv 文件
    [ -f /.dockerenv ] && return 0
    
    # 方法2: 检查 cgroup
    [ -f /proc/1/cgroup ] && grep -q docker /proc/1/cgroup && return 0
    
    # 方法3: 检查 PID 1 的进程名
    [ "$(cat /proc/1/comm 2>/dev/null)" != "systemd" ] && return 0
    
    return 1
}

# 为 Ubuntu/Linux 系统进行设置的函数
setup_ubuntu() {
    log_info "开始为 Linux (Ubuntu) 进行设置..."

    # 检测容器环境
    IN_CONTAINER=false
    if is_container; then
        IN_CONTAINER=true
        log_info "检测到容器环境，将跳过部分系统级配置"
    fi

    # 检查是否以 root 权限运行
    if [ "$(id -u)" -ne 0 ]; then
        log_error "在 Linux 上运行时需要 root 权限，请使用 sudo 执行此脚本。"
        exit 1
    fi

    # 0. 基础环境准备 (防止乱码和缺少基础工具)
    export DEBIAN_FRONTEND=noninteractive
    
    # 确保基础工具存在
    log_info "正在检查并安装基础工具..."
    if ! command -v curl >/dev/null 2>&1 || ! dpkg -s apt-utils >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y -qq curl apt-utils
    fi

    # 优先解决中文乱码问题
    if ! command -v locale-gen >/dev/null 2>&1; then
        apt-get install -y -qq locales
    fi
    
    log_info "正在配置语言环境..."
    # 生成必要的 locale
    locale-gen zh_CN.UTF-8 en_US.UTF-8 >/dev/null 2>&1
    
    # 立即在当前 shell 中应用
    export LANG=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
    export LANGUAGE=zh_CN.UTF-8
    
    update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 LANGUAGE=zh_CN.UTF-8 2>/dev/null || true
    log_info "语言环境配置完成。"

    # 1. 切换软件源 (chsrc)
    log_info "正在更新软件包源..."
    if [ ! -f /tmp/chsrc ]; then
        curl -L https://gitee.com/RubyMetric/chsrc/releases/download/pre/chsrc-x64-linux -o /tmp/chsrc
        chmod +x /tmp/chsrc
    fi
    /tmp/chsrc set ubuntu
    log_info "软件源切换完成。"

    # 2. 安装常用软件包
    log_info "正在安装系统更新和常用软件包 (可能需要较长时间)..."
    apt-get update -qq
    apt-get upgrade -y -qq
    apt-get install -y -qq wget iputils-ping htop git vim neofetch zsh npm language-pack-zh-hans
    log_info "常用软件包安装完成。"

    # 3. 安装并配置 SSH 服务
    log_info "正在安装 SSH 服务..."
    apt-get install -y -qq openssh-server
    
    # 确保 SSH 目录存在
    mkdir -p /run/sshd
    
    # 在容器中配置 SSH 允许 root 登录（可选）
    if [ "$IN_CONTAINER" = true ]; then
        log_info "配置 SSH 允许 root 登录（容器环境）..."
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
        sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    fi
    
    # 检测并启动 SSH 服务
    if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
        log_info "使用 systemd 启动 SSH..."
        systemctl enable ssh 2>/dev/null || true
        systemctl start ssh 2>/dev/null || true
    else
        log_info "使用 service 启动 SSH（容器环境）..."
        service ssh start 2>/dev/null || /usr/sbin/sshd
    fi
    
    # 验证 SSH 是否运行
    if pgrep -x sshd >/dev/null; then
        log_info "✓ SSH 服务已成功启动"
    else
        log_info "⚠ SSH 服务可能未启动，请手动检查"
    fi

    # 4. 安装 Docker（仅在非容器环境）
    if [ "$IN_CONTAINER" = false ]; then
        log_info "正在安装 Docker..."
        if command -v docker >/dev/null 2>&1; then
            log_info "Docker 已安装。"
        else
            curl -fsSL https://get.docker.com | sh
            log_info "Docker 安装完成。"
        fi
    else
        log_info "容器环境中跳过 Docker 安装"
    fi

    # 5. 设置镜像源
    log_info "正在设置 npm 镜像源..."
    /tmp/chsrc set npm
    
    # Docker 镜像加速（仅在非容器环境且 Docker 已安装）
    if [ "$IN_CONTAINER" = false ] && command -v docker >/dev/null 2>&1; then
        log_info "正在设置 Docker 镜像加速..."
        /tmp/chsrc set docker
        
        # 如果有 systemd，重启 Docker
        if command -v systemctl >/dev/null 2>&1; then
            log_info "重启 Docker 服务以应用镜像加速..."
            systemctl daemon-reload 2>/dev/null || true
            systemctl restart docker 2>/dev/null || true
        fi
    fi
    
    # 清理临时文件
    rm -f /tmp/chsrc
    log_info "镜像源设置完成。"

    # 6. 安装 Starship（跨 shell 提示符）
    log_info "正在安装 Starship..."
    if ! command -v starship >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        log_info "Starship 安装完成。"
    else
        log_info "Starship 已安装。"
    fi
    
    # 7. 询问是否安装 sing-box（TUN 模式代理）
    if [ "$IN_CONTAINER" = true ]; then
        log_info ""
        log_info "=========================================="
        log_info "检测到容器环境，是否安装 sing-box 代理？"
        log_info "sing-box 支持 TUN 模式全局透明代理"
        log_info "=========================================="
        
        # 在脚本中默认不安装，可以手动运行
        INSTALL_SINGBOX=false
        
        if [ "$INSTALL_SINGBOX" = true ]; then
            SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
            if [ -f "$SCRIPT_DIR/install-singbox.sh" ]; then
                log_info "开始安装 sing-box..."
                bash "$SCRIPT_DIR/install-singbox.sh"
            else
                log_info "提示: 可以稍后运行 'bash install-singbox.sh' 安装代理"
            fi
        else
            log_info "跳过 sing-box 安装"
            log_info "如需安装，请运行: bash install-singbox.sh"
        fi
    fi
    
    # 如果在容器中且是 root 用户，提示可以直接配置 shell
    if [ "$IN_CONTAINER" = true ] && [ "$(id -u)" -eq 0 ]; then
        log_info "================================"
        log_info "容器环境检测完成！"
        log_info "您可以继续运行此脚本配置 Shell 环境，或者："
        log_info "1. 设置 root 密码: passwd"
        log_info "2. 通过 SSH 连接: ssh root@<容器IP>"
        log_info "================================"
    fi
}

# 为 macOS 系统进行设置的函数
setup_macos() {
    log_info "开始为 macOS 进行设置..."

    # 如果 Homebrew 未安装，则进行安装
    if ! command -v brew >/dev/null 2>&1; then
        log_info "正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log_info "Homebrew 已安装。"
    fi

    # 使用 Homebrew 安装常用软件包
    log_info "正在安装常用软件包..."
    brew install wget git htop node zsh starship neofetch
    log_info "常用软件包安装完成。"

    # 安装 CaskaydiaCove Nerd Font Mono 字体
    log_info "正在检查并安装 CaskaydiaCove Nerd Font Mono 字体..."
    
    # 检查字体文件是否真正存在
    FONT_FILE="$HOME/Library/Fonts/CaskaydiaCoveNerdFontMono-Regular.ttf"
    
    if [ -f "$FONT_FILE" ]; then
        log_info "CaskaydiaCove Nerd Font Mono 字体已安装。"
    else
        log_info "字体文件不存在，正在安装..."
        
        # 如果 cask 已安装但文件不存在，先卸载
        if brew list --cask font-caskaydia-cove-nerd-font >/dev/null 2>&1; then
            log_info "发现已安装的 cask 但字体文件缺失，正在重新安装..."
            brew uninstall --cask font-caskaydia-cove-nerd-font
        fi
        
        # 重新安装字体
        brew install --cask font-caskaydia-cove-nerd-font
        
        # 验证安装结果
        if [ -f "$FONT_FILE" ]; then
            log_info "CaskaydiaCove Nerd Font Mono 字体安装完成。"
        else
            log_error "字体安装失败，请手动检查。"
        fi
    fi
}

# 设置 Zsh, Oh My Zsh, 插件和配置文件的函数
setup_shell() {
    log_info "开始设置 Shell (Zsh, Oh My Zsh, Starship)..."

    # 检测容器环境
    IN_CONTAINER=false
    if is_container; then
        IN_CONTAINER=true
    fi

    # 如果是 root 用户，给出提示但继续执行
    if [ "$(id -u)" -eq 0 ]; then
        log_info "检测到当前为 root 用户，正在为 root 用户配置 Shell 环境..."
    fi

    # 安装 Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "正在安装 Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_info "Oh My Zsh 已安装。"
    fi

    # 定义 Zsh 自定义插件目录
    ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

    # 安装 zsh 插件
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
        log_info "正在安装 zsh-autosuggestions 插件..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
        log_info "正在安装 zsh-syntax-highlighting 插件..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    fi

    # 备份并导入配置文件
    log_info "正在备份并导入配置文件..."
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

    # 获取脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

    # 备份并复制 .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        log_info "备份已存在的 .zshrc 文件..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak.${TIMESTAMP}"
    fi
    
    if [ -f "${SCRIPT_DIR}/.zshrc" ]; then
        cp "${SCRIPT_DIR}/.zshrc" "$HOME/.zshrc"
        log_info ".zshrc 配置文件导入完成。"
    else
        log_info "⚠ 未找到 .zshrc 配置文件，使用默认配置"
    fi

    # 备份并复制 starship.toml
    mkdir -p "$HOME/.config"
    if [ -f "$HOME/.config/starship.toml" ]; then
        log_info "备份已存在的 starship.toml 文件..."
        mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.${TIMESTAMP}"
    fi
    
    if [ -f "${SCRIPT_DIR}/starship.toml" ]; then
        cp "${SCRIPT_DIR}/starship.toml" "$HOME/.config/starship.toml"
        log_info "starship.toml 配置文件导入完成。"
    else
        log_info "⚠ 未找到 starship.toml 配置文件，使用默认配置"
    fi

    # 安装全局 npm 包
    log_info "正在安装全局 npm 包..."
    npm install -g vtop n live-server pm2 nodemon nrm

    # 设置 n 工具的安装目录为用户目录，避免权限问题
    export N_PREFIX="$HOME/.n"
    export PATH="$N_PREFIX/bin:$PATH"
    
    # 使用 n 工具更新 Node.js 到最新的稳定版本
    log_info "正在更新 Node.js 到最新稳定版..."
    log_info "设置 N_PREFIX=$N_PREFIX 以避免权限问题..."
    n stable

    # 更改默认 shell 为 Zsh（在容器中可能失败，跳过）
    if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/bin/zsh" ]; then
        if [ "$IN_CONTAINER" = false ]; then
            log_info "正在更改默认 shell 为 Zsh，可能需要您输入密码。"
            chsh -s "$(which zsh)" 2>/dev/null || {
                log_info "⚠ 无法自动更改默认 shell，请手动执行: chsh -s \$(which zsh)"
            }
        else
            log_info "容器环境中跳过 chsh 操作"
            log_info "提示：在容器中启动 zsh 可直接执行: zsh"
        fi
    else
        log_info "默认 shell 已是 Zsh。"
    fi
}


# brew安装软件
setup_brew() {
    log_info "开始安装 brew 软件..."
    log_info "注意：如果软件已安装，将强制重新安装最新版本"
    
    # 微信
    log_info "正在安装/更新 微信..."
    brew install --cask --force wechat
    
    # 飞书      
    log_info "正在安装/更新 飞书..."
    brew install --cask --force feishu
    
    # 网易云音乐
    log_info "正在安装/更新 网易云音乐..."
    brew install --cask --force neteasemusic
    
    # 喜马拉雅
    log_info "正在安装/更新 喜马拉雅..."
    brew install --cask --force ximalaya
    
    # Warp
    log_info "正在安装/更新 Warp..."
    brew install --cask --force warp
    
    # openinterminal
    log_info "正在安装/更新 OpenInTerminal..."
    brew install --cask --force openinterminal
    
    # tencent-lemon
    log_info "正在安装/更新 腾讯柠檬清理..."
    brew install --cask --force tencent-lemon
    
    # Windsurf
    log_info "正在安装/更新 Windsurf..."
    brew install --cask --force windsurf
    
    # visual-studio-code  
    log_info "正在安装/更新 Visual Studio Code..."
    brew install --cask --force visual-studio-code

    # google-chrome  
    log_info "正在安装/更新 Google Chrome..."
    brew install --cask --force google-chrome

    
    log_info "所有 brew 软件安装/更新完成！"
}


# --- 主程序执行 ---

main() {
    OS="$(uname)"
    
    if [ "$OS" = "Linux" ]; then
        # 检测是否在容器中运行
        IN_CONTAINER=false
        if is_container; then
            IN_CONTAINER=true
        fi
        
        # 如果是 root 用户运行
        if [ "$(id -u)" -eq 0 ]; then
            setup_ubuntu
            
            log_info ""
            log_info "=========================================="
            log_info "系统设置完成！"
            log_info ""
            
            # 检查环境并给出相应提示
            if [ "$IN_CONTAINER" = true ]; then
                log_info "检测到容器环境，在容器中通常使用 root 用户"
                log_info "正在为 root 用户配置 Shell 环境..."
            else
                log_info "⚠️ 检测到物理机/虚拟机环境"
                log_info ""
                log_info "建议："
                log_info "  1. 创建普通用户: adduser <username>"
                log_info "  2. 添加 sudo 权限: usermod -aG sudo <username>"
                log_info "  3. 切换用户并运行: su - <username> && bash init.sh"
                log_info ""
                log_info "或者："
                log_info "  继续为 root 用户配置（通常不推荐）"
                log_info ""
                log_info "正在为 root 用户配置 Shell（10秒后继续，Ctrl+C 取消）..."
                
                # 给用户 10 秒考虑时间
                sleep 10 || {
                    log_info "配置已取消。"
                    log_info "提示：以普通用户身份运行脚本: bash init.sh"
                    exit 0
                }
            fi
            
            log_info "=========================================="
            log_info ""
            
            setup_shell
            log_info ""
            log_info "✓ 所有配置完成！"
            log_info "现在可以执行: source ~/.zshrc 或重新进入 shell"
        else
            # 普通用户运行，直接配置 shell
            log_info "检测到普通用户，开始配置 Shell 环境..."
            setup_shell
            log_info "Shell 配置完成！请重启终端以使所有更改生效。"
        fi
        
    elif [ "$OS" = "Darwin" ]; then
        setup_macos
        setup_shell
        setup_brew
        log_info "macOS 系统设置完成！"
        log_info "请重启终端以使所有更改生效。"
    else
        log_error "不支持的操作系统: $OS"
        exit 1
    fi
}

# 执行主函数
main

