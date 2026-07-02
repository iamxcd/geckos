#!/bin/bash

# Geckos Web OS 一键安装脚本
# 官方网站: https://www.geckosweb.cn

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
INSTALL_DIR="/opt/geckos"
CLOUD_HOST="https://www.geckosweb.cn"
SERVICE_NAME="geckos"
SERVER_PORT=""

# 打印信息
print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统
check_system() {
    print_info "检查系统环境..."

    # 检查操作系统
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "本脚本仅支持 Linux 系统"
        exit 1
    fi

    # 检查架构
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
        print_error "仅支持 x86_64 或 aarch64 架构"
        exit 1
    fi

    # 检查必要命令
    for cmd in wget unzip; do
        if ! command -v $cmd &> /dev/null; then
            print_error "缺少必要命令: $cmd"
            print_info "请使用以下命令安装:"
            echo "  Ubuntu/Debian: sudo apt-get install wget unzip"
            echo "  CentOS/RHEL:   sudo yum install wget unzip"
            exit 1
        fi
    done

    # 检查是否有权限创建安装目录
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 权限运行此脚本"
        print_info "请使用: curl -fsSL https://www.geckosweb.cn/install.sh | sudo bash"
        exit 1
    fi

    print_success "系统检查通过"
}

# 生成随机端口（10000-65535，至少5位）
generate_port() {
    while true; do
        PORT=$(( RANDOM % 55536 + 10000 ))
        # 确保端口未被占用
        if ! ss -tlnp 2>/dev/null | grep -q ":${PORT} " && ! netstat -tlnp 2>/dev/null | grep -q ":${PORT} "; then
            SERVER_PORT=$PORT
            break
        fi
    done
    print_success "随机分配端口: $SERVER_PORT"
}

# 获取最新版本
get_latest_version() {
    print_info "获取最新版本信息..."
    
    # 从云端获取最新版本
    UPGRADE_URL="${CLOUD_HOST}/upgrade.json"
    VERSION_INFO=$(wget -qO- "$UPGRADE_URL" 2>/dev/null || echo "")
    
    if [ -z "$VERSION_INFO" ]; then
        print_error "无法获取版本信息，请检查网络连接"
        exit 1
    fi
    
    # 解析版本号
    LATEST_VERSION=$(echo "$VERSION_INFO" | grep -o '"version": *"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$LATEST_VERSION" ]; then
        print_error "无法解析版本信息"
        exit 1
    fi
    
    print_success "最新版本: $LATEST_VERSION"
}

# 下载安装包
download_package() {
    print_info "下载安装包..."
    
    DOWNLOAD_URL="${CLOUD_HOST}/geckos/${LATEST_VERSION}/geckos.zip"
    TEMP_DIR=$(mktemp -d)
    ZIP_FILE="${TEMP_DIR}/geckos.zip"
    
    print_info "下载地址: $DOWNLOAD_URL"
    
    if ! wget -q --show-progress -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -O "$ZIP_FILE" "$DOWNLOAD_URL"; then
        print_error "下载失败"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    print_success "下载完成"
}

# 安装程序
install_program() {
    print_info "安装程序..."

    # 备份旧主程序（仅备份二进制和配置，不移动运行时数据）
    if [ -f "${INSTALL_DIR}/geckos" ]; then
        BACKUP_BIN="${INSTALL_DIR}/geckos.bak"
        mv "${INSTALL_DIR}/geckos" "$BACKUP_BIN"
        print_info "已备份旧程序: $BACKUP_BIN"
    fi

    mkdir -p "$INSTALL_DIR"

    # 解压到临时目录
    EXTRACT_DIR="${TEMP_DIR}/extract"
    mkdir -p "$EXTRACT_DIR"
    if ! unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR"; then
        print_error "解压失败"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 移动主程序到 /opt/geckos/
    if [ -f "${EXTRACT_DIR}/geckos" ]; then
        mv "${EXTRACT_DIR}/geckos" "${INSTALL_DIR}/geckos"
        chmod +x "${INSTALL_DIR}/geckos"
    else
        print_error "安装包中未找到可执行文件"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 添加到环境变量
    setup_path

    print_success "主程序安装完成"
}

# 添加主程序到环境变量
setup_path() {
    print_info "配置环境变量..."
    
    # 创建符号链接到 /usr/local/bin
    SYMLINK="/usr/local/bin/geckos"
    
    if [ -L "$SYMLINK" ] || [ -f "$SYMLINK" ]; then
        rm -f "$SYMLINK"
    fi
    
    ln -s "${INSTALL_DIR}/geckos" "$SYMLINK"
    
    # 确保当前 shell 也生效
    export PATH="$PATH:/usr/local/bin"
    
    print_success "已添加 geckos 到 PATH，可在任意目录执行 geckos 命令"
}

# 设置配置文件（从解压目录移动到程序同目录）
setup_config() {
    print_info "设置配置文件..."

    SRC_CONFIG="${TEMP_DIR}/extract/config.yaml"
    DST_CONFIG="${INSTALL_DIR}/config.yaml"

    if [ ! -f "$SRC_CONFIG" ]; then
        print_error "安装包中未找到配置文件"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 写入随机端口
    if [ -n "$SERVER_PORT" ]; then
        print_info "写入监听端口: $SERVER_PORT"
        sed -i "s/^\(\s*port:\s*\).*$/\1${SERVER_PORT}/" "$SRC_CONFIG"
    fi

    # 移动配置到程序同目录
    if [ -f "$DST_CONFIG" ]; then
        BACKUP_CONFIG="${DST_CONFIG}.bak"
        mv "$DST_CONFIG" "$BACKUP_CONFIG"
        print_info "配置文件已存在，备份到: $BACKUP_CONFIG"
        mv "$SRC_CONFIG" "$DST_CONFIG"
        print_success "配置文件已更新: $DST_CONFIG"
    else
        mv "$SRC_CONFIG" "$DST_CONFIG"
        print_success "配置文件已设置: $DST_CONFIG"
    fi

    # 清理临时文件
    rm -rf "$TEMP_DIR"
}

# 创建 systemd 服务
create_service() {
    print_info "创建系统服务..."
    
    SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
    
    sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Geckos Web OS
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/geckos serve
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # 重载 systemd
    sudo systemctl daemon-reload
    
    # 设置开机自启
    sudo systemctl enable "$SERVICE_NAME"
    
    print_success "系统服务创建完成"
}

# 启动服务
start_service() {
    print_info "启动服务..."
    
    sudo systemctl start "$SERVICE_NAME"
    
    # 等待服务启动
    sleep 2
    
    # 检查服务状态
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "服务启动成功"
    else
        print_error "服务启动失败，请检查日志: sudo journalctl -u $SERVICE_NAME -f"
        exit 1
    fi
}

# 创建根分区数据目录
# 当用户硬盘全部挂载在 / 下时，文件管理功能使用 /geckosdata 存储数据
setup_data_dir() {
    print_info "设置数据目录..."

    DATA_DIR="/geckosdata"

    if [ ! -d "$DATA_DIR" ]; then
        mkdir -p "$DATA_DIR"
        chmod 755 "$DATA_DIR"
        print_success "数据目录已创建: $DATA_DIR"
    else
        print_info "数据目录已存在: $DATA_DIR"
    fi
}

# 显示安装信息
show_info() {
    IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "========================================"
    print_success "Geckos Web OS 安装完成！"
    echo "========================================"
    echo ""
    echo "访问地址:"
    echo "  - 本机: http://127.0.0.1:${SERVER_PORT}"
    echo "  - 局域网: http://${IP}:${SERVER_PORT}"
    echo ""
    echo "默认账号:"
    echo "  用户名: admin"
    echo "  密码: 123456"
    echo ""
    echo "⚠️  首次登录请立即修改默认密码！"
    echo ""
    echo "常用命令:"
    echo "  geckos version           # 查看版本"
    echo "  geckos status            # 查看配置与服务状态"
    echo "  启动服务: sudo systemctl start $SERVICE_NAME"
    echo "  停止服务: sudo systemctl stop $SERVICE_NAME"
    echo "  查看状态: sudo systemctl status $SERVICE_NAME"
    echo "  查看日志: sudo journalctl -u $SERVICE_NAME -f"
    echo ""
    echo "配置文件: ${INSTALL_DIR}/config.yaml"
    echo "文件管理数据: /geckosdata"
    echo "数据目录: ${INSTALL_DIR}"
    echo "========================================"
}

# 主函数
main() {
    echo "========================================"
    echo "  Geckos Web OS 安装程序"
    echo "========================================"
    echo ""
    
    check_system
    generate_port
    get_latest_version
    download_package
    install_program
    setup_data_dir
    setup_config
    create_service
    start_service
    show_info
}

# 运行主函数
main
