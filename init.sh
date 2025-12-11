#!/bin/sh
set -e

# --- 配置参数 ---
AUTO_YES=false

# 解析命令行参数
while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes) AUTO_YES=true ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
    shift
done

# --- 日志函数 ---
log() { echo "✓ $1"; }
err() { echo "✗ $1" >&2; exit 1; }

# --- 环境检测 ---
is_container() {
    [ -f /.dockerenv ] && return 0
    [ -f /proc/version ] && grep -qi "microsoft\|WSL\|docker" /proc/version && return 0
    [ -f /proc/1/cgroup ] && grep -q docker /proc/1/cgroup && return 0
    return 1
}

detect_arch() {
    case "$(uname -m)" in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) err "不支持的架构" ;;
    esac
}

# --- Linux 系统配置 ---
setup_linux() {
    log "开始配置 Linux 环境..."
    
    [ "$(id -u)" -ne 0 ] && err "需要 root 权限，请使用 sudo"
    
    export DEBIAN_FRONTEND=noninteractive
    
    # 安装基础工具
    log "安装基础工具..."
    apt-get update -qq
    apt-get install -y -qq curl wget git vim zsh npm openssh-server locales 2>/dev/null
    
    # 配置语言环境
    locale-gen zh_CN.UTF-8 en_US.UTF-8 >/dev/null 2>&1
    export LANG=zh_CN.UTF-8
    
    # 配置软件源
    if [ ! -f /tmp/chsrc ]; then
        curl -sL https://gitee.com/RubyMetric/chsrc/releases/download/pre/chsrc-x64-linux -o /tmp/chsrc
        chmod +x /tmp/chsrc
    fi
    /tmp/chsrc set ubuntu >/dev/null 2>&1
    /tmp/chsrc set npm >/dev/null 2>&1
    rm -f /tmp/chsrc
    
    # 启动 SSH
    mkdir -p /run/sshd
    if is_container; then
        sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config 2>/dev/null
        service ssh start 2>/dev/null || /usr/sbin/sshd
    else
        systemctl enable ssh 2>/dev/null
        systemctl start ssh 2>/dev/null
    fi
    
    # 安装 Docker（非容器环境）
    if ! is_container && ! command -v docker >/dev/null 2>&1; then
        log "安装 Docker..."
        curl -fsSL https://get.docker.com | sh >/dev/null 2>&1
    fi
    
    # 安装 Starship
    if ! command -v starship >/dev/null 2>&1; then
        log "安装 Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes >/dev/null 2>&1
    fi
    
    log "Linux 环境配置完成"
}

# --- macOS 系统配置 ---
setup_macos() {
    log "开始配置 macOS 环境..."
    
    # 安装 Homebrew
    if ! command -v brew >/dev/null 2>&1; then
        log "安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # 安装常用工具
    log "安装常用工具..."
    brew install wget git htop node zsh starship 2>/dev/null
    
    log "macOS 环境配置完成"
}

# --- Shell 配置 ---
setup_shell() {
    log "配置 Shell 环境..."
    
    # 安装 Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1
    fi
    
    # 安装插件
    ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ] && \
        git clone --quiet https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" 2>/dev/null
    [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ] && \
        git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" 2>/dev/null
    
    # 复制配置文件
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    [ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
    [ -f "${SCRIPT_DIR}/.zshrc" ] && cp "${SCRIPT_DIR}/.zshrc" "$HOME/.zshrc"
    
    mkdir -p "$HOME/.config"
    [ -f "$HOME/.config/starship.toml" ] && mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.$(date +%s)"
    [ -f "${SCRIPT_DIR}/starship.toml" ] && cp "${SCRIPT_DIR}/starship.toml" "$HOME/.config/starship.toml"
    
    # 安装全局 npm 包
    npm install -g vtop n live-server pm2 nodemon >/dev/null 2>&1 || true
    
    # 更改默认 Shell
    if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/bin/zsh" ]; then
        if ! is_container; then
            chsh -s "$(which zsh)" 2>/dev/null || log "请手动执行: chsh -s \$(which zsh)"
        fi
    fi
    
    log "Shell 配置完成"
}



# --- 主程序 ---
main() {
    OS="$(uname)"
    
    if [ "$OS" = "Linux" ]; then
        # Linux 环境
        if [ "$(id -u)" -eq 0 ]; then
            setup_linux
            
            # 如果是容器环境，直接配置 root 的 Shell
            if is_container; then
                setup_shell
            else
                # 物理机环境，提示创建普通用户
                if [ "$AUTO_YES" = false ]; then
                    echo ""
                    echo "检测到物理机环境，建议创建普通用户："
                    echo "  adduser <username>"
                    echo "  usermod -aG sudo <username>"
                    echo ""
                    echo "或继续为 root 配置 (10秒后继续，Ctrl+C 取消)..."
                    sleep 10 || exit 0
                fi
                setup_shell
            fi
            

        else
            # 普通用户
            setup_shell
        fi
        
    elif [ "$OS" = "Darwin" ]; then
        # macOS 环境
        setup_macos
        setup_shell
    else
        err "不支持的系统: $OS"
    fi
    
    echo ""
    log "所有配置完成！"
    echo "重启终端或执行: source ~/.zshrc"
}

main
