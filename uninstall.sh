#!/bin/bash

# Geckos Web OS 卸载脚本
# 官方网站: https://www.geckosweb.cn

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
INSTALL_DIR="/opt/geckos"
SERVICE_NAME="geckos"

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

# 检查权限
check_permission() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 权限运行此脚本"
        print_info "请使用: sudo bash uninstall.sh"
        exit 1
    fi
}

# 停止服务
stop_service() {
    print_info "停止 Geckos 服务..."
    
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl stop "$SERVICE_NAME"
        print_success "服务已停止"
    else
        print_info "服务未运行"
    fi
}

# 禁用服务
disable_service() {
    print_info "禁用 Geckos 服务..."
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl disable "$SERVICE_NAME"
        print_success "服务已禁用"
    fi
    
    # 删除服务文件
    if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
        rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
        systemctl daemon-reload
        print_success "服务文件已删除"
    fi
}

# 备份数据
backup_data() {
    if [ -d "$INSTALL_DIR" ]; then
        print_info "是否备份数据？"
        echo "  数据目录: ${INSTALL_DIR}/data"
        echo "  配置文件: ${INSTALL_DIR}/config.yaml"
        read -p "请输入 [y/N]: " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
            mkdir -p "$BACKUP_DIR"
            
            # 备份数据
            if [ -d "${INSTALL_DIR}/data" ]; then
                cp -r "${INSTALL_DIR}/data" "$BACKUP_DIR/"
            fi
            
            # 备份配置
            if [ -f "${INSTALL_DIR}/config.yaml" ]; then
                cp "${INSTALL_DIR}/config.yaml" "$BACKUP_DIR/"
            fi
            
            print_success "数据已备份到: $BACKUP_DIR"
        fi
    fi
}

# 删除安装目录
remove_installation() {
    print_info "删除安装目录..."
    
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        print_success "安装目录已删除: $INSTALL_DIR"
    else
        print_info "安装目录不存在"
    fi
}

# 清理环境变量符号链接
remove_path() {
    print_info "清理环境变量..."
    
    SYMLINK="/usr/local/bin/geckos"
    if [ -L "$SYMLINK" ] || [ -f "$SYMLINK" ]; then
        rm -f "$SYMLINK"
        print_success "已移除 geckos 命令链接"
    fi
}

# 清理完成
cleanup() {
    print_success "卸载完成！"
    echo ""
    echo "Geckos Web OS 已从系统中移除"
    echo ""
    echo "如需重新安装，请访问: https://www.geckosweb.cn"
}

# 主函数
main() {
    echo "========================================"
    echo "  Geckos Web OS 卸载程序"
    echo "========================================"
    echo ""

    # 检查是否是通过管道执行（非交互式）
    if [ ! -t 0 ]; then
        print_info "检测到非交互式执行，将自动卸载（不备份数据）"
        AUTO_UNINSTALL=true
    else
        # 确认卸载
        echo "⚠️  此操作将卸载 Geckos Web OS"
        echo ""
        read -p "确定要继续吗？ [y/N]: " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "已取消卸载"
            exit 0
        fi
    fi

    check_permission
    stop_service
    disable_service

    # 交互模式下询问是否备份，非交互模式跳过备份
    if [ "$AUTO_UNINSTALL" != "true" ]; then
        backup_data
    fi

    remove_installation
    remove_path
    cleanup
}

# 运行主函数
main
