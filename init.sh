#!/usr/bin/env bash

# 脚本出错时立即退出
set -e

# 获取脚本所在绝对目录，避免相对路径拷贝失败
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# --- 函数定义 ---

# 打印普通信息
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

# 打印警告信息
log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1" >&2
}

# 打印错误信息
log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

# 为 Ubuntu/Linux 系统进行设置的函数 (需 root 权限)
setup_ubuntu() {
    log_info "开始为 Linux (Ubuntu/Debian) 进行系统级设置..."

    # 检查是否以 root 权限运行
    if [ "$(id -u)" -ne 0 ]; then
        log_error "系统级设置需要 root 权限，请使用 sudo 执行此脚本。"
        exit 1
    fi

    # 确保基础工具可用 (避免最小系统没有 curl)
    if ! command -v curl >/dev/null 2>&1; then
        log_info "正在安装基础依赖 curl..."
        apt-get update -y && apt-get install -y curl
    fi

    # 自动识别系统架构以适配镜像换源工具
    ARCH="$(uname -m)"
    CHSRC_BIN=""
    case "$ARCH" in
        x86_64)
            CHSRC_BIN="chsrc-x64-linux"
            ;;
        aarch64|arm64)
            CHSRC_BIN="chsrc-aarch64-linux"
            ;;
        *)
            log_warn "未识别的 CPU 架构: $ARCH，跳过自动换源。"
            ;;
    esac

    if [ -n "$CHSRC_BIN" ]; then
        log_info "正在配置软件源加速 (架构: $ARCH)..."
        if curl -fsSL "https://gitee.com/RubyMetric/chsrc/releases/download/pre/${CHSRC_BIN}" -o /tmp/chsrc 2>/dev/null; then
            chmod +x /tmp/chsrc
            /tmp/chsrc set ubuntu || log_warn "chsrc 切换 Ubuntu 源失败，将保持系统默认源。"
            rm -f /tmp/chsrc
            log_info "软件源配置完成。"
        else
            log_warn "下载换源工具失败，保持默认源继续更新。"
        fi
    fi

    # 安装中文语言包与常用区域设置
    log_info "正在安装语言包与生成区域设置..."
    apt-get update -y && apt-get install -y language-pack-zh-hans locales
    locale-gen zh_CN.UTF-8 en_US.UTF-8 || true
    update-locale LANG=en_US.UTF-8 LC_ALL=zh_CN.UTF-8 || true
    log_info "语言包与区域设置完成。"

    # 安装常用系统工具
    log_info "正在安装常用系统软件包..."
    apt-get install -y curl wget iputils-ping htop git vim zsh
    log_info "常用软件包安装完成。"

    # 安装 Starship (跨 shell 提示符)
    if ! command -v starship >/dev/null 2>&1; then
        log_info "正在安装 Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        log_info "Starship 安装完成。"
    else
        log_info "Starship 已安装。"
    fi
}

# 为 macOS 系统进行设置的函数 (普通用户运行)
setup_macos() {
    log_info "开始为 macOS 进行基础工具设置..."

    # 如果 Homebrew 未安装，则进行安装
    if ! command -v brew >/dev/null 2>&1; then
        log_info "正在安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log_info "Homebrew 已安装。"
    fi

    # 使用 Homebrew 安装常用软件包
    log_info "正在安装/检查 CLI 常用软件包..."
    brew install wget git htop node zsh starship
    log_info "CLI 常用软件包安装完成。"

    # 安装 CaskaydiaCove Nerd Font Mono 字体
    log_info "正在检查并安装 CaskaydiaCove Nerd Font Mono 字体..."
    FONT_FILE="$HOME/Library/Fonts/CaskaydiaCoveNerdFontMono-Regular.ttf"
    if [ -f "$FONT_FILE" ]; then
        log_info "CaskaydiaCove Nerd Font Mono 字体已安装。"
    else
        log_info "字体文件不存在，正在通过 Homebrew 安装..."
        if brew list --cask font-caskaydia-cove-nerd-font >/dev/null 2>&1; then
            brew reinstall --cask font-caskaydia-cove-nerd-font
        else
            brew install --cask font-caskaydia-cove-nerd-font
        fi

        if [ -f "$FONT_FILE" ]; then
            log_info "CaskaydiaCove Nerd Font Mono 字体安装完成。"
        else
            log_warn "字体安装可能未到位，请手动确认 ~/Library/Fonts/。"
        fi
    fi
}

# 设置 Zsh, Oh My Zsh, 插件和配置文件的函数 (普通用户运行)
setup_shell() {
    log_info "开始设置用户级 Shell (Zsh, Oh My Zsh, Node.js 环境)..."

    # 检查是否以 root 身份运行
    if [ "$(id -u)" -eq 0 ]; then
        log_error "Shell 设置部分不应以 root 身份运行，请以普通用户身份执行此部分。"
        exit 1
    fi

    # 安装 Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "正在安装 Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_info "Oh My Zsh 已安装。"
    fi

    # 定义 Zsh 自定义插件目录
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "${ZSH_CUSTOM}/plugins"

    # 安装 zsh 插件 (使用 shallow clone 加快速度)
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
        log_info "正在安装 zsh-autosuggestions 插件..."
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
        log_info "正在安装 zsh-syntax-highlighting 插件..."
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    fi

    # 备份并导入配置文件
    log_info "正在备份并导入配置文件..."
    TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"

    # 备份并复制 .zshrc
    if [ -f "$SCRIPT_DIR/.zshrc" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            log_info "备份已存在的 .zshrc 文件至 $HOME/.zshrc.bak.${TIMESTAMP}..."
            mv "$HOME/.zshrc" "$HOME/.zshrc.bak.${TIMESTAMP}"
        fi
        cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
        log_info ".zshrc 配置文件导入完成。"
    else
        log_warn "未找到 $SCRIPT_DIR/.zshrc，跳过复制。"
    fi

    # 备份并复制 starship.toml
    mkdir -p "$HOME/.config"
    if [ -f "$SCRIPT_DIR/starship.toml" ]; then
        if [ -f "$HOME/.config/starship.toml" ]; then
            log_info "备份已存在的 starship.toml 文件至 $HOME/.config/starship.toml.bak.${TIMESTAMP}..."
            mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.${TIMESTAMP}"
        fi
        cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
        log_info "starship.toml 配置文件导入完成。"
    else
        log_warn "未找到 $SCRIPT_DIR/starship.toml，跳过复制。"
    fi

    # 配置 Node.js (使用 n 管理版本，安装到当前用户目录避免权限问题)
    export N_PREFIX="$HOME/.n"
    export PATH="$N_PREFIX/bin:$PATH"
    mkdir -p "$N_PREFIX"

    if ! command -v n >/dev/null 2>&1; then
        log_info "正在安装 n (Node.js 版本管理工具)..."
        if curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o /tmp/n-install 2>/dev/null; then
            bash /tmp/n-install stable
            rm -f /tmp/n-install
        else
            log_warn "通过 curl 安装 n 失败，若系统已有 npm 将尝试全局安装..."
            if command -v npm >/dev/null 2>&1; then
                npm install -g n && n stable || true
            fi
        fi
    else
        log_info "正在通过 n 更新 Node.js 至最新稳定版..."
        n stable || log_warn "n stable 执行遇到问题，请检查网络。"
    fi

    # 安装全局 npm 包 (此时使用用户目录下的 npm，完全具备写权限)
    if command -v npm >/dev/null 2>&1; then
        log_info "正在安装常用全局 npm 工具..."
        npm install -g vtop live-server pm2 nodemon nrm || log_warn "部分 npm 包安装失败，后续可手动运行 npm install -g 安装。"
    fi

    # 更改默认 shell 为 Zsh
    CURRENT_SHELL="$(basename "${SHELL:-sh}")"
    if [ "$CURRENT_SHELL" != "zsh" ]; then
        ZSH_BIN="$(command -v zsh 2>/dev/null || true)"
        if [ -n "$ZSH_BIN" ]; then
            log_info "正在将默认 Shell 更改为 Zsh (可能需要输入密码)..."
            chsh -s "$ZSH_BIN" || log_warn "自动切换 shell 失败，请稍后手动运行: chsh -s $ZSH_BIN"
        fi
    else
        log_info "当前默认 shell 已是 Zsh。"
    fi
}

# 使用 Homebrew 安装 macOS 常用桌面软件
setup_brew() {
    log_info "开始检查并安装常用 macOS 桌面应用..."

    CASKS=(
        wechat
        neteasemusic
        openinterminal
        tencent-lemon
        visual-studio-code
        google-chrome
    )

    for cask in "${CASKS[@]}"; do
        if brew list --cask "$cask" >/dev/null 2>&1; then
            log_info "应用 $cask 已安装，跳过。"
        else
            log_info "正在安装应用 $cask..."
            brew install --cask "$cask" || log_warn "安装 $cask 失败，可稍后手动重试。"
        fi
    done

    log_info "macOS 桌面软件安装检查完成！"
}

# --- 主程序执行 ---

main() {
    OS="$(uname)"
    if [ "$OS" = "Linux" ]; then
        if [ "$(id -u)" -eq 0 ]; then
            setup_ubuntu
            echo ""
            log_info "=========================================================="
            log_info "Linux 系统级配置已完成！"
            log_info "接下来请以普通用户身份（不要使用 sudo）运行此脚本完成 Shell 配置："
            log_info "    $0"
            log_info "=========================================================="
        else
            setup_shell
            echo ""
            log_info "=========================================================="
            log_info "Linux 用户级 Shell 与开发环境配置完成！"
            log_info "请重新登录或重启终端以使配置生效。"
            log_info "=========================================================="
        fi
    elif [ "$OS" = "Darwin" ]; then
        if [ "$(id -u)" -eq 0 ]; then
            log_error "在 macOS 上请勿使用 sudo 执行此脚本，直接运行 ./init.sh 即可。"
            exit 1
        fi
        setup_macos
        setup_shell
        setup_brew
        echo ""
        log_info "=========================================================="
        log_info "macOS 环境初始化全部完成！请重启终端生效。"
        log_info "=========================================================="
    else
        log_error "不支持的操作系统: $OS"
        exit 1
    fi
}

# 执行主函数
main "$@"
