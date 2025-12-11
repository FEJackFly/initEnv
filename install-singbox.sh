#!/bin/bash

# sing-box 安装和管理脚本
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 检测系统架构
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) log_error "不支持的架构: $ARCH"; exit 1 ;;
    esac
}

# 安装 sing-box
install_singbox() {
    log_info "开始安装 sing-box..."
    
    # 检查是否已安装
    if command -v sing-box >/dev/null 2>&1; then
        log_warn "sing-box 已安装，版本: $(sing-box version)"
        read -p "是否重新安装? (y/n): " reinstall
        [[ "$reinstall" != "y" ]] && return 0
    fi
    
    ARCH=$(detect_arch)
    VERSION="1.8.0"
    
    log_info "系统架构: $ARCH"
    log_info "安装版本: $VERSION"
    
    # 下载
    DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/v${VERSION}/sing-box-${VERSION}-linux-${ARCH}.tar.gz"
    log_info "下载地址: $DOWNLOAD_URL"
    
    wget -O /tmp/sing-box.tar.gz "$DOWNLOAD_URL" || {
        log_error "下载失败，请检查网络连接"
        exit 1
    }
    
    # 解压安装
    tar -xzf /tmp/sing-box.tar.gz -C /tmp/
    mv /tmp/sing-box-${VERSION}-linux-${ARCH}/sing-box /usr/local/bin/
    chmod +x /usr/local/bin/sing-box
    
    # 清理
    rm -rf /tmp/sing-box.tar.gz /tmp/sing-box-${VERSION}-linux-${ARCH}
    
    log_info "✓ sing-box 安装完成: $(sing-box version)"
}

# 创建配置目录
setup_config() {
    log_info "设置配置目录..."
    
    mkdir -p /etc/sing-box
    
    # 复制配置文件
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    
    if [ -f "$SCRIPT_DIR/singbox-config.json" ]; then
        cp "$SCRIPT_DIR/singbox-config.json" /etc/sing-box/config.json
        log_info "✓ 配置文件已复制到 /etc/sing-box/config.json"
    else
        log_error "找不到配置文件: $SCRIPT_DIR/singbox-config.json"
        exit 1
    fi
    
    # 下载 GeoIP 和 GeoSite 数据库
    log_info "下载 GeoIP 和 GeoSite 数据库..."
    
    wget -O /etc/sing-box/geoip.db https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db
    wget -O /etc/sing-box/geosite.db https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db
    
    log_info "✓ 数据库下载完成"
}

# 创建 systemd 服务
create_service() {
    log_info "创建 systemd 服务..."
    
    cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    log_info "✓ systemd 服务已创建"
}

# 启动服务
start_service() {
    log_info "启动 sing-box 服务..."
    
    systemctl enable sing-box
    systemctl start sing-box
    
    sleep 2
    
    if systemctl is-active --quiet sing-box; then
        log_info "✓ sing-box 服务已启动"
        systemctl status sing-box --no-pager
    else
        log_error "sing-box 启动失败，查看日志:"
        journalctl -u sing-box -n 50 --no-pager
        exit 1
    fi
}

# 测试连接
test_connection() {
    log_info "测试代理连接..."
    
    # 等待 TUN 设备就绪
    sleep 3
    
    # 测试 Google
    if curl -I --max-time 10 https://www.google.com >/dev/null 2>&1; then
        log_info "✓ Google 连接成功"
    else
        log_warn "⚠ Google 连接失败"
    fi
    
    # 测试国内网站
    if curl -I --max-time 10 https://www.baidu.com >/dev/null 2>&1; then
        log_info "✓ 百度连接成功"
    else
        log_warn "⚠ 百度连接失败"
    fi
    
    # 显示 IP
    log_info "当前 IP 地址:"
    curl -s https://api.ip.sb/ip || curl -s https://ipinfo.io/ip
}

# 显示使用说明
show_usage() {
    cat <<EOF

${GREEN}========================================${NC}
${GREEN}  sing-box 安装完成！${NC}
${GREEN}========================================${NC}

✓ 配置文件: /etc/sing-box/config.json
✓ 服务管理:
  - 启动: systemctl start sing-box
  - 停止: systemctl stop sing-box
  - 重启: systemctl restart sing-box
  - 状态: systemctl status sing-box
  - 日志: journalctl -u sing-box -f

✓ TUN 模式已启用（全局代理）
✓ HTTP/SOCKS5 代理端口: 127.0.0.1:2080

✓ 分流规则:
  - 国内网站/IP → 直连
  - 国外网站 → 代理
  - 广告域名 → 拦截

${YELLOW}提示:${NC}
- 如需修改配置，编辑 /etc/sing-box/config.json
- 修改后重启服务: systemctl restart sing-box
- 查看实时日志: journalctl -u sing-box -f

${GREEN}========================================${NC}

EOF
}

# 主函数
main() {
    # 检查 root 权限
    if [ "$(id -u)" -ne 0 ]; then
        log_error "需要 root 权限运行此脚本"
        exit 1
    fi
    
    log_info "开始部署 sing-box..."
    
    install_singbox
    setup_config
    create_service
    start_service
    test_connection
    show_usage
    
    log_info "✓ 所有步骤完成！"
}

# 执行主函数
main
