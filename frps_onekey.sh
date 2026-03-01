#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}      FRPS 一键安装脚本${NC}"
echo -e "${GREEN}=====================================${NC}"

# 检查系统架构
ARCH=$(uname -m)
case $ARCH in
    x86_64) FRP_ARCH="amd64" ;;
    aarch64) FRP_ARCH="arm64" ;;
    *) echo -e "${RED}不支持的系统架构${NC}"; exit 1 ;;
esac

# 自动检测公网IP
echo -e "${YELLOW}正在检测公网IP...${NC}"
PUBLIC_IP=$(curl -s ipinfo.io/ip || curl -s ifconfig.me || curl -s icanhazip.com)

if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}无法自动检测公网IP，请手动输入${NC}"
    read -p "请输入公网IP: " PUBLIC_IP
    while [ -z "$PUBLIC_IP" ]; do
        read -p "公网IP不能为空，请重新输入: " PUBLIC_IP
    done
else
    echo -e "${GREEN}检测到公网IP: ${PUBLIC_IP}${NC}"
    read -p "是否使用此IP？(y/n): " CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        read -p "请输入正确的公网IP: " NEW_IP
        if [ ! -z "$NEW_IP" ]; then
            PUBLIC_IP=$NEW_IP
        fi
    fi
fi

# 检查frp目录
FRP_DIR="/root/frp"
if [ ! -d "$FRP_DIR" ]; then
    mkdir -p "$FRP_DIR"
fi

# 下载最新版本的frps
echo -e "${YELLOW}正在下载最新版本的frps...${NC}"
LATEST_VERSION=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d'"' -f4 | sed 's/v//')
FRP_URL="https://github.com/fatedier/frp/releases/download/v${LATEST_VERSION}/frp_${LATEST_VERSION}_linux_${FRP_ARCH}.tar.gz"

wget -q -O /tmp/frp.tar.gz "$FRP_URL"

if [ $? -ne 0 ]; then
    echo -e "${RED}下载失败，请检查网络连接${NC}"
    exit 1
fi

# 解压并安装
echo -e "${YELLOW}正在安装frps...${NC}"
tar -xzf /tmp/frp.tar.gz -C /tmp
FRP_TMP_DIR=$(ls -d /tmp/frp_*)
cp "$FRP_TMP_DIR/frps" "$FRP_DIR/"
cp "$FRP_TMP_DIR/frps.toml" "$FRP_DIR/"
chmod +x "$FRP_DIR/frps"

# 清理临时文件
rm -rf /tmp/frp.tar.gz "$FRP_TMP_DIR"

# 配置frps.toml
echo -e "${YELLOW}正在配置frps.toml...${NC}"

# 默认配置
DEFAULT_BIND_PORT=7000
DEFAULT_DASHBOARD_PORT=7500

read -p "请输入frps绑定端口 [默认: $DEFAULT_BIND_PORT]: " BIND_PORT
BIND_PORT=${BIND_PORT:-$DEFAULT_BIND_PORT}

read -p "请输入仪表盘端口 [默认: $DEFAULT_DASHBOARD_PORT]: " DASHBOARD_PORT
DASHBOARD_PORT=${DASHBOARD_PORT:-$DEFAULT_DASHBOARD_PORT}

read -p "请设置连接密码: " TOKEN
while [ -z "$TOKEN" ]; do
    read -p "密码不能为空，请重新输入: " TOKEN
done

read -p "请设置仪表盘用户名 [默认: admin]: " DASHBOARD_USER
DASHBOARD_USER=${DASHBOARD_USER:-admin}

read -p "请设置仪表盘密码 [默认: admin]: " DASHBOARD_PASS
DASHBOARD_PASS=${DASHBOARD_PASS:-admin}

# 生成配置文件
cat > "$FRP_DIR/frps.toml" << EOF
[common]
bind_port = $BIND_PORT
token = "$TOKEN"

# 仪表盘配置
dashboard_port = $DASHBOARD_PORT
dashboard_user = "$DASHBOARD_USER"
dashboard_pwd = "$DASHBOARD_PASS"

bind_udp_port = 7001
EOF

# 创建systemd服务
echo -e "${YELLOW}正在创建systemd服务...${NC}"

cat > /root/frps.service << EOF
[Unit]
Description=frps service
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
ExecStart=$FRP_DIR/frps -c $FRP_DIR/frps.toml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# 启动并启用服务
systemctl daemon-reload
if [ -f /etc/systemd/system/frps.service ]; then
    systemctl stop frps || true
    rm -f /etc/systemd/system/frps.service
fi
cp /root/frps.service /etc/systemd/system/
systemctl daemon-reload
systemctl start frps
systemctl enable frps

# 创建frpstool面板工具
echo -e "${YELLOW}正在创建frpstool面板工具...${NC}"

cat > /root/frpstool << 'EOF'
#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_menu() {
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}         FRPS 管理工具${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${YELLOW}1.${NC} 查看frps状态"
    echo -e "${YELLOW}2.${NC} 启动frps"
    echo -e "${YELLOW}3.${NC} 停止frps"
    echo -e "${YELLOW}4.${NC} 重启frps"
    echo -e "${YELLOW}5.${NC} 查看配置文件"
    echo -e "${YELLOW}6.${NC} 修改配置文件"
    echo -e "${YELLOW}7.${NC} 查看日志"
    echo -e "${YELLOW}8.${NC} 查看公网IP"
    echo -e "${YELLOW}9.${NC} 退出"
    echo -e "${GREEN}=====================================${NC}"
}

while true; do
    show_menu
    read -p "请选择操作: " CHOICE
    
    case $CHOICE in
        1)
            echo -e "${YELLOW}frps状态:${NC}"
            systemctl status frps
            ;;
        2)
            echo -e "${YELLOW}启动frps...${NC}"
            systemctl start frps
            echo -e "${GREEN}frps已启动${NC}"
            ;;
        3)
            echo -e "${YELLOW}停止frps...${NC}"
            systemctl stop frps
            echo -e "${GREEN}frps已停止${NC}"
            ;;
        4)
            echo -e "${YELLOW}重启frps...${NC}"
            systemctl restart frps
            echo -e "${GREEN}frps已重启${NC}"
            ;;
        5)
            echo -e "${YELLOW}配置文件内容:${NC}"
            cat /root/frp/frps.toml
            ;;
        6)
            echo -e "${YELLOW}正在编辑配置文件...${NC}"
            nano /root/frp/frps.toml
            echo -e "${YELLOW}配置文件已修改，是否重启frps? (y/n):${NC}"
            read RESTART
            if [ "$RESTART" = "y" ]; then
                systemctl restart frps
                echo -e "${GREEN}frps已重启${NC}"
            fi
            ;;
        7)
            echo -e "${YELLOW}查看frps日志:${NC}"
            journalctl -u frps -f
            ;;
        8)
            echo -e "${YELLOW}公网IP:${NC}"
            curl -s ipinfo.io/ip || curl -s ifconfig.me || curl -s icanhazip.com
            ;;
        9)
            echo -e "${GREEN}退出工具${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入${NC}"
            ;;
    esac
    
    echo -e "${YELLOW}按任意键返回菜单...${NC}"
    read -n 1 -s
    clear
done
EOF

chmod +x /root/frpstool

# 创建软链接到bin目录
if [ ! -f /usr/local/bin/frpstool ]; then
    ln -s /root/frpstool /usr/local/bin/
fi

# 开放防火墙端口
echo -e "${YELLOW}正在配置防火墙...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow $BIND_PORT/tcp
    ufw allow $DASHBOARD_PORT/tcp
    ufw allow 7001/udp
    ufw reload
fi

# 显示安装结果
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}FRPS 安装完成！${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "${YELLOW}公网IP:${NC} $PUBLIC_IP"
echo -e "${YELLOW}绑定端口:${NC} $BIND_PORT"
echo -e "${YELLOW}仪表盘地址:${NC} http://$PUBLIC_IP:$DASHBOARD_PORT"
echo -e "${YELLOW}仪表盘用户名:${NC} $DASHBOARD_USER"
echo -e "${YELLOW}仪表盘密码:${NC} $DASHBOARD_PASS"
echo -e "${YELLOW}连接密码:${NC} $TOKEN"
echo -e "${GREEN}=====================================${NC}"
echo -e "${YELLOW}使用方法:${NC}"
echo -e "  1. 在终端输入 'frpstool' 打开管理面板"
echo -e "  2. 配置frpc客户端连接到 $PUBLIC_IP:$BIND_PORT"
echo -e "  3. 使用token: $TOKEN"
echo -e "${GREEN}=====================================${NC}"
