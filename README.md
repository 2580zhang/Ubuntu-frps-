# FRPS 一键安装脚本

这是一个用于快速搭建 FRPS (Fast Reverse Proxy Server) 服务器的一键安装脚本，支持自动检测公网IP、配置文件生成、后台管理和面板工具。

## 功能特点

- ✅ 自动检测公网IP
- ✅ 自动下载最新版本的FRPS
- ✅ 交互式配置frps.toml
- ✅ 自动创建systemd服务
- ✅ 自动配置防火墙
- ✅ 提供frpstool管理面板
- ✅ 支持开机自启

## 系统要求

- Ubuntu/Debian 系统
- 网络连接正常
- 具有root权限

## 安装步骤

### 方法1：直接运行脚本

```bash
wget -O frps_onekey.sh https://raw.githubusercontent.com/yourusername/frps-onekey/main/frps_onekey.sh
chmod +x frps_onekey.sh
./frps_onekey.sh
```

### 方法2：克隆仓库后运行

```bash
git clone https://github.com/yourusername/frps-onekey.git
cd frps-onekey
chmod +x frps_onekey.sh
./frps_onekey.sh
```

## 使用方法

### 安装过程

1. 脚本会自动检测公网IP，您可以选择使用检测到的IP或手动输入
2. 输入frps绑定端口（默认7000）
3. 输入仪表盘端口（默认7500）
4. 设置连接密码
5. 设置仪表盘用户名和密码

### 管理工具

安装完成后，您可以通过以下命令打开管理面板：

```bash
frpstool
```

管理面板功能包括：
- 查看frps状态
- 启动/停止/重启frps服务
- 查看和修改配置文件
- 查看服务日志
- 查看公网IP

## 配置信息

安装完成后，您将获得以下配置信息：
- 公网IP
- 绑定端口
- 仪表盘地址
- 仪表盘用户名和密码
- 连接密码

## 客户端配置

在frpc客户端配置文件中使用以下信息：

```ini
[common]
server_addr = 公网IP
server_port = 绑定端口
token = 连接密码
```

## 防火墙设置

脚本会自动开放以下端口：
- 绑定端口（默认7000）
- 仪表盘端口（默认7500）
- UDP端口7001

## 目录结构

```
/root/frp/          # FRPS安装目录
├── frps            # FRPS可执行文件
└── frps.toml       # 配置文件

/etc/systemd/system/frps.service  # systemd服务文件

/usr/local/bin/frpstool           # 管理工具
```

## 常见问题

### 1. 无法自动检测公网IP

如果脚本无法自动检测公网IP，会提示您手动输入。

### 2. 端口被占用

如果指定的端口被占用，脚本会继续执行，但可能会导致服务启动失败。请确保指定的端口未被其他服务占用。

### 3. 服务启动失败

检查服务状态：

```bash
systemctl status frps
```

查看日志：

```bash
journalctl -u frps -f
```

## 许可证

MIT License

## 更新日志

### v1.0.0
- 初始版本
- 支持自动检测公网IP
- 支持交互式配置
- 提供frpstool管理面板
