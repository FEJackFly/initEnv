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
    
    # 安装 CaskaydiaCove Nerd Font 字体
    log "正在检查并安装 CaskaydiaCove Nerd Font Mono 字体..."
    FONT_DIR="$HOME/.local/share/fonts"
    FONT_FILE="$FONT_DIR/CaskaydiaCoveNerdFontMono-Regular.ttf"
    
    if [ -f "$FONT_FILE" ]; then
        log "CaskaydiaCove Nerd Font Mono 字体已安装"
    else
        log "字体文件不存在，正在下载安装..."
        mkdir -p "$FONT_DIR"
        
        # 下载 Nerd Font
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
        TEMP_ZIP="/tmp/CascadiaCode.zip"
        
        if curl -sL "$FONT_URL" -o "$TEMP_ZIP" 2>/dev/null; then
            # 解压字体文件
            apt-get install -y -qq unzip 2>/dev/null || true
            unzip -q -o "$TEMP_ZIP" "*.ttf" -d "$FONT_DIR" 2>/dev/null || true
            rm -f "$TEMP_ZIP"
            
            # 更新字体缓存
            if command -v fc-cache >/dev/null 2>&1; then
                fc-cache -f "$FONT_DIR" >/dev/null 2>&1
            fi
            
            if [ -f "$FONT_FILE" ]; then
                log "CaskaydiaCove Nerd Font Mono 字体安装完成"
            else
                log "字体安装失败，请手动检查（非致命错误，继续执行）"
            fi
        else
            log "字体下载失败，跳过（非致命错误，继续执行）"
        fi
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
    brew install wget git htop node zsh starship neofetch 2>/dev/null
    
    # 安装 CaskaydiaCove Nerd Font Mono 字体
    log "正在检查并安装 CaskaydiaCove Nerd Font Mono 字体..."
    FONT_FILE="$HOME/Library/Fonts/CaskaydiaCoveNerdFontMono-Regular.ttf"
    
    if [ -f "$FONT_FILE" ]; then
        log "CaskaydiaCove Nerd Font Mono 字体已安装"
    else
        log "字体文件不存在，正在安装..."
        
        # 如果 cask 已安装但文件不存在，先卸载
        if brew list --cask font-caskaydia-cove-nerd-font >/dev/null 2>&1; then
            log "发现已安装的 cask 但字体文件缺失，正在重新安装..."
            brew uninstall --cask font-caskaydia-cove-nerd-font
        fi
        
        # 重新安装字体
        brew install --cask font-caskaydia-cove-nerd-font
        
        # 验证安装结果
        if [ -f "$FONT_FILE" ]; then
            log "CaskaydiaCove Nerd Font Mono 字体安装完成"
        else
            log "字体安装失败，请手动检查（非致命错误，继续执行）"
        fi
    fi
    
    log "macOS 环境配置完成"
}

# --- Shell 配置 ---
setup_shell() {
    log "配置 Shell 环境..."
    
    # 安装 Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "正在安装 Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1
        log "Oh My Zsh 安装完成"
    else
        log "Oh My Zsh 已安装，跳过"
    fi
    
    # 安装插件
    ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
        log "正在安装 zsh-autosuggestions 插件..."
        git clone --quiet https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" 2>/dev/null
        log "zsh-autosuggestions 插件安装完成"
    else
        log "zsh-autosuggestions 插件已安装，跳过"
    fi
    
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
        log "正在安装 zsh-syntax-highlighting 插件..."
        git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" 2>/dev/null
        log "zsh-syntax-highlighting 插件安装完成"
    else
        log "zsh-syntax-highlighting 插件已安装，跳过"
    fi
    
    # 复制配置文件
    log "正在复制配置文件..."
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    
    if [ -f "$HOME/.zshrc" ]; then
        log "备份现有 .zshrc 文件"
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
    fi
    
    if [ -f "${SCRIPT_DIR}/.zshrc" ]; then
        log "复制 .zshrc 配置文件"
        cp "${SCRIPT_DIR}/.zshrc" "$HOME/.zshrc"
    else
        log "警告: 未找到 .zshrc 模板文件"
    fi
    
    mkdir -p "$HOME/.config"
    
    if [ -f "$HOME/.config/starship.toml" ]; then
        log "备份现有 starship.toml 文件"
        mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.$(date +%s)"
    fi
    
    if [ -f "${SCRIPT_DIR}/starship.toml" ]; then
        log "复制 starship.toml 配置文件"
        cp "${SCRIPT_DIR}/starship.toml" "$HOME/.config/starship.toml"
    else
        log "警告: 未找到 starship.toml 模板文件"
    fi
    
    # 安装全局 npm 包
    log "正在安装全局 npm 包 (vtop, n, live-server, pm2, nodemon, nrm)..."
    log "这可能需要几分钟，请耐心等待..."
    npm install -g vtop n live-server pm2 nodemon nrm || log "部分 npm 包安装失败，继续执行"
    log "npm 全局包安装完成"
    
    # 设置 n 工具的安装目录为用户目录，避免权限问题
    log "配置 Node.js 版本管理器 (n)..."
    export N_PREFIX="$HOME/.n"
    export PATH="$N_PREFIX/bin:$PATH"
    log "N_PREFIX 已设置为: $N_PREFIX"
    
    # 使用 n 工具更新 Node.js 到最新的稳定版本
    if command -v n >/dev/null 2>&1; then
        log "正在使用 n 更新 Node.js 到最新稳定版（可能需要几分钟）..."
        if n stable; then
            log "Node.js 更新成功: $(node --version)"
        else
            log "Node.js 更新失败，保持当前版本: $(node --version)"
        fi
    else
        log "警告: n 工具未正确安装，跳过 Node.js 更新"
    fi
    
    # 更改默认 Shell
    if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/bin/zsh" ]; then
        if ! is_container; then
            chsh -s "$(which zsh)" 2>/dev/null || log "请手动执行: chsh -s \$(which zsh)"
        fi
    fi
    
    log "Shell 配置完成"
}

# --- brew 安装软件 ---
setup_brew() {
    log "开始安装 brew 软件..."
    log "注意：如果软件已安装，将强制重新安装最新版本"
    
    # 微信
    log "正在安装/更新 微信..."
    brew install --cask --force wechat
    
    # 飞书      
    log "正在安装/更新 飞书..."
    brew install --cask --force feishu
    
    # 网易云音乐
    log "正在安装/更新 网易云音乐..."
    brew install --cask --force neteasemusic
    
    # 喜马拉雅
    log "正在安装/更新 喜马拉雅..."
    brew install --cask --force ximalaya
    
    # Warp
    log "正在安装/更新 Warp..."
    brew install --cask --force warp
    
    # openinterminal
    log "正在安装/更新 OpenInTerminal..."
    brew install --cask --force openinterminal
    
    # tencent-lemon
    log "正在安装/更新 腾讯柠檬清理..."
    brew install --cask --force tencent-lemon
    
    # Windsurf
    log "正在安装/更新 Windsurf..."
    brew install --cask --force windsurf
    
    # visual-studio-code  
    log "正在安装/更新 Visual Studio Code..."
    brew install --cask --force visual-studio-code

    # google-chrome  
    log "正在安装/更新 Google Chrome..."
    brew install --cask --force google-chrome
    
    log "所有 brew 软件安装/更新完成！"
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
        setup_brew
    else
        err "不支持的系统: $OS"
    fi
    
    echo ""
    log "所有配置完成！"
    echo "重启终端或执行: source ~/.zshrc"
}

main
