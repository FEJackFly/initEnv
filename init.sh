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

# 为 Ubuntu/Linux 系统进行设置的函数
setup_ubuntu() {
    log_info "开始为 Linux (Ubuntu) 进行设置..."

    # 检查是否以 root 权限运行
    if [ "$(id -u)" -ne 0 ]; then
        log_error "在 Linux 上运行时需要 root 权限，请使用 sudo 执行此脚本。"
        exit 1
    fi

    # 切换软件源以加快下载速度
    log_info "正在更新软件包源..."
    curl -L https://gitee.com/RubyMetric/chsrc/releases/download/pre/chsrc-x64-linux -o /tmp/chsrc
    chmod +x /tmp/chsrc
    /tmp/chsrc set ubuntu
    log_info "软件源切换完成。"

    # 安装中文语言包
    log_info "正在安装中文语言包..."
    apt-get update && apt-get install -y language-pack-zh-hans
    update-locale LANG=en_US.UTF-8 LC_ALL=zh_CN.UTF-8
    log_info "中文语言包安装完成。"

    # 安装常用软件包
    log_info "正在安装常用软件包..."
    apt-get install -y curl wget iputils-ping htop git vim neofetch zsh npm
    log_info "常用软件包安装完成。"

    # 设置 npm 镜像源
    log_info "正在设置 npm 镜像源..."
    /tmp/chsrc set npm
    rm /tmp/chsrc # 清理下载的工具
    log_info "npm 镜像源设置完成。"

    # 安装 Starship (跨 shell 提示符)
    log_info "正在安装 Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    log_info "Starship 安装完成。"
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
# 注意：此函数应以普通用户身份运行，而不是 root
setup_shell() {
    log_info "开始设置 Shell (Zsh, Oh My Zsh, Starship)..."

    # 检查是否以 root 身份运行，因为主目录的配置应属于用户
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

    # 备份并复制 .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        log_info "备份已存在的 .zshrc 文件..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak.${TIMESTAMP}"
    fi
    cp .zshrc "$HOME/.zshrc"
    log_info ".zshrc 配置文件导入完成。"

    # 备份并复制 starship.toml
    mkdir -p "$HOME/.config"
    if [ -f "$HOME/.config/starship.toml" ]; then
        log_info "备份已存在的 starship.toml 文件..."
        mv "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.${TIMESTAMP}"
    fi
    cp starship.toml "$HOME/.config/starship.toml"
    log_info "starship.toml 配置文件导入完成。"

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

    # 更改默认 shell 为 Zsh
    if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/bin/zsh" ]; then
        log_info "正在更改默认 shell 为 Zsh，可能需要您输入密码。"
        chsh -s "$(which zsh)"
        log_info "默认 shell 已更改。请重启终端以生效。"
    else
        log_info "默认 shell 已是 Zsh。"
    fi
}

# --- 主程序执行 ---

main() {
    OS="$(uname)"
    if [ "$OS" = "Linux" ]; then
        setup_ubuntu
        log_info "Linux 系统设置完成。现在，请以普通用户身份（不要使用 sudo）再次运行此脚本来完成 shell 的配置。"
    elif [ "$OS" = "Darwin" ]; then
        setup_macos
        setup_shell
        log_info "macOS 系统设置完成！"
        log_info "请重启终端以使所有更改生效。"
    else
        log_error "不支持的操作系统: $OS"
        exit 1
    fi
}

# 执行主函数
main
