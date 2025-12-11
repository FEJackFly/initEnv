# Docker 容器中使用 sing-box

## ✅ 已完成安装

看起来你已经成功下载了 GeoIP 和 GeoSite 数据库！现在继续完成安装：

## 🚀 继续安装（在你的容器中运行）

```bash
# 重新运行安装脚本（会自动检测容器环境）
bash /initEnv/install-singbox.sh
```

脚本会：

-   ✅ 检测到容器环境
-   ✅ 跳过 systemd 服务创建
-   ✅ 创建启动/停止脚本
-   ✅ 自动启动 sing-box
-   ✅ 测试连接

## 📋 容器环境管理命令

### 启动 sing-box

```bash
start-singbox.sh
```

### 停止 sing-box

```bash
stop-singbox.sh
```

### 查看日志

```bash
# 实时查看
tail -f /var/log/sing-box.log

# 查看全部
cat /var/log/sing-box.log
```

### 检查进程

```bash
# 查看进程
ps aux | grep sing-box

# 查看 PID
cat /var/run/sing-box.pid
```

### 测试连接

```bash
# 测试 Google
curl -I https://www.google.com

# 查看当前 IP
curl https://api.ip.sb/ip

# 测试国内网站
curl -I https://www.baidu.com
```

## 🔧 容器启动时自动运行

如果你想在容器启动时自动启动 sing-box：

### 方法 1：在容器启动命令中添加

```bash
docker run -it --privileged --cap-add=NET_ADMIN \
  -v /path/to/initEnv:/initEnv \
  ubuntu:latest \
  bash -c "start-singbox.sh && bash"
```

### 方法 2：创建启动脚本

在容器中创建 `/root/startup.sh`：

```bash
#!/bin/bash

# 启动 sing-box
start-singbox.sh

# 启动 shell
exec bash
```

然后：

```bash
chmod +x /root/startup.sh
# 使用这个脚本作为容器入口点
```

### 方法 3：添加到 .zshrc

如果已经配置了 zsh，在 `~/.zshrc` 末尾添加：

```bash
# 自动启动 sing-box
if ! pgrep -f "sing-box run" >/dev/null 2>&1; then
    echo "正在启动 sing-box..."
    start-singbox.sh
fi
```

## 🐳 Docker Compose 示例

创建 `docker-compose.yml`：

```yaml
version: "3.8"

services:
    dev-environment:
        image: ubuntu:latest
        container_name: dev-env
        privileged: true
        cap_add:
            - NET_ADMIN
        volumes:
            - ./initEnv:/initEnv
        working_dir: /initEnv
        stdin_open: true
        tty: true
        command: >
            bash -c "
              if [ ! -f /etc/sing-box/config.json ]; then
                bash /initEnv/install-singbox.sh
              fi &&
              start-singbox.sh &&
              exec bash
            "
```

启动：

```bash
docker-compose up -d
docker-compose exec dev-environment bash
```

## ⚠️ 常见问题

### Q: 容器重启后代理失效？

**A:** 需要重新运行启动脚本：

```bash
start-singbox.sh
```

### Q: 如何查看 sing-box 是否在运行？

**A:** 检查进程：

```bash
ps aux | grep sing-box
# 或
pgrep -f "sing-box run"
```

### Q: 修改配置后如何生效？

**A:** 重启 sing-box：

```bash
stop-singbox.sh
start-singbox.sh
```

### Q: TUN 设备创建失败？

**A:** 确保容器有足够权限：

```bash
docker run --privileged --cap-add=NET_ADMIN ...
```

检查 TUN 模块：

```bash
modprobe tun
ls -l /dev/net/tun
```

## 📊 验证安装

运行以下命令验证一切正常：

```bash
# 1. 检查配置文件
ls -lh /etc/sing-box/

# 2. 检查进程
ps aux | grep sing-box

# 3. 查看日志
tail /var/log/sing-box.log

# 4. 测试连接
curl -I https://www.google.com

# 5. 查看 TUN 设备
ip addr show tun0
```

## 🎯 完整示例

```bash
# 在容器中完整的使用流程

# 1. 首次安装
cd /initEnv
bash install-singbox.sh

# 2. 启动服务（已自动启动，这里是手动示例）
start-singbox.sh

# 3. 测试
curl https://www.google.com

# 4. 查看日志
tail -f /var/log/sing-box.log

# 5. 如需停止
stop-singbox.sh

# 6. 如需重启
stop-singbox.sh && start-singbox.sh
```

## 📝 下次使用

容器重启后，只需运行：

```bash
start-singbox.sh
```

就可以恢复代理功能！
