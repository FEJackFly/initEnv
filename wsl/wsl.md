# WSL 使用攻略

## 📋 目录

-   [基础命令](#基础命令)
-   [配置文件](#配置文件)
-   [常用技巧](#常用技巧)
-   [故障排查](#故障排查)

---

## 🚀 基础命令

### 查看和安装

```bash
# 查看可安装的发行版
wsl --list --online
wsl -l -o

# 安装指定发行版
wsl --install -d Ubuntu
wsl --install -d Debian

# 查看已安装的发行版
wsl --list --verbose
wsl -l -v

# 查看正在运行的发行版
wsl --list --running
```

### 启动和停止

```bash
# 启动默认发行版
wsl

# 启动指定发行版
wsl -d Ubuntu

# 关闭所有发行版（重启 WSL 2 VM）
wsl --shutdown

# 终止指定发行版
wsl --terminate Ubuntu
wsl -t Ubuntu
```

### 版本管理

```bash
# 查看 WSL 版本
wsl --version

# 检查发行版运行的 WSL 版本
wsl -l -v

# 设置默认 WSL 版本（1 或 2）
wsl --set-default-version 2

# 转换发行版的 WSL 版本
wsl --set-version Ubuntu 2
```

### 导入导出

```bash
# 导出发行版为 tar 文件
wsl --export Ubuntu D:\backup\ubuntu.tar

# 导入发行版
wsl --import MyUbuntu D:\WSL\Ubuntu D:\backup\ubuntu.tar

# 卸载/注销发行版
wsl --unregister Ubuntu
```

### 用户管理

```bash
# 以特定用户身份运行
wsl -u root
wsl --user root

# 设置默认用户（在 wsl.conf 中配置）
[user]
default=yourUsername
```

---

## ⚙️ 配置文件

WSL 有两个配置文件，作用域不同：

| 配置文件         | 位置                                          | 作用范围                    | 适用版本      |
| ---------------- | --------------------------------------------- | --------------------------- | ------------- |
| **`.wslconfig`** | `%UserProfile%\.wslconfig` (Windows 用户目录) | 所有 WSL 2 发行版的全局设置 | WSL 2         |
| **`wsl.conf`**   | `/etc/wsl.conf` (WSL 发行版内部)              | 单个发行版的特定设置        | WSL 1 & WSL 2 |

### 📄 `.wslconfig` - 全局配置

**位置**：`C:\Users\<YourUsername>\.wslconfig`

**说明**：配置所有 WSL 2 发行版的虚拟机资源、网络、内核等全局设置。

**示例配置**：参见同目录下的 [`.wslconfig`](./.wslconfig) 文件。

**主要配置项**：

#### `[wsl2]` - 主要 WSL 设置

| 配置项                 | 默认值       | 说明                                                 |
| ---------------------- | ------------ | ---------------------------------------------------- |
| `memory`               | 50% 系统内存 | 虚拟机内存限制（如 `4GB`）                           |
| `processors`           | 所有处理器   | 虚拟处理器数量                                       |
| `swap`                 | 25% 内存     | 交换空间大小                                         |
| `localhostForwarding`  | `true`       | 允许通过 localhost 访问 WSL 服务                     |
| `networkingMode`       | `NAT`        | 网络模式（`NAT`/`bridged`/`mirrored`/`virtioproxy`） |
| `kernelCommandLine`    | -            | 额外的内核参数                                       |
| `nestedVirtualization` | `true`       | 嵌套虚拟化支持                                       |
| `debugConsole`         | `false`      | 调试控制台（显示 dmesg）                             |

#### `[experimental]` - 实验性功能

| 配置项              | 默认值     | 说明                                  |
| ------------------- | ---------- | ------------------------------------- |
| `sparseVhd`         | `false`    | 稀疏 VHD，自动回收未使用空间          |
| `autoMemoryReclaim` | `disabled` | 自动内存回收（`dropCache`/`gradual`） |
| `dnsTunneling`      | `false`    | DNS 隧道（改善 DNS 解析）             |
| `autoProxy`         | `false`    | 自动检测并使用 Windows 代理设置       |

---

### 📄 `wsl.conf` - 发行版配置

**位置**：`/etc/wsl.conf`（在 WSL 发行版内部）

**说明**：配置单个发行版的挂载、网络、启动等设置。

**示例配置**：参见同目录下的 [`wsl.conf`](./wsl.conf) 文件。

**主要配置项**：

#### `[boot]` - 启动设置

| 配置项    | 默认值  | 说明                             |
| --------- | ------- | -------------------------------- |
| `systemd` | `false` | 启用 systemd（需要 WSL 0.67.6+） |
| `command` | -       | WSL 启动时运行的命令             |

```ini
[boot]
systemd=true
command="service docker start"
```

#### `[automount]` - 自动挂载

| 配置项       | 默认值  | 说明                        |
| ------------ | ------- | --------------------------- |
| `enabled`    | `true`  | 是否自动挂载 Windows 驱动器 |
| `root`       | `/mnt/` | 挂载点根目录                |
| `options`    | -       | DrvFs 挂载选项              |
| `mountFsTab` | `true`  | 是否处理 `/etc/fstab`       |

```ini
[automount]
enabled=true
root=/
options="metadata,uid=1000,gid=1000,umask=022"
```

**挂载选项说明**：

-   `metadata`：启用元数据支持（文件权限）
-   `uid/gid`：设置文件所有者（默认 1000）
-   `umask`：目录权限掩码（如 `022` = `755`）
-   `fmask`：文件权限掩码
-   `case=off/dir/force`：大小写敏感设置

#### `[network]` - 网络设置

| 配置项               | 默认值         | 说明                        |
| -------------------- | -------------- | --------------------------- |
| `hostname`           | Windows 主机名 | WSL 主机名                  |
| `generateHosts`      | `true`         | 自动生成 `/etc/hosts`       |
| `generateResolvConf` | `true`         | 自动生成 `/etc/resolv.conf` |

```ini
[network]
hostname=wsl-dev
generateHosts=false
generateResolvConf=false
```

#### `[interop]` - 互操作

| 配置项              | 默认值 | 说明                         |
| ------------------- | ------ | ---------------------------- |
| `enabled`           | `true` | 允许启动 Windows 进程        |
| `appendWindowsPath` | `true` | 将 Windows PATH 添加到 $PATH |

```ini
[interop]
enabled=true
appendWindowsPath=false
```

#### `[user]` - 用户设置

| 配置项    | 默认值           | 说明         |
| --------- | ---------------- | ------------ |
| `default` | 安装时创建的用户 | 默认登录用户 |

```ini
[user]
default=yourUsername
```

---

## ⚡ 配置更改的 8 秒规则

⚠️ **重要**：修改配置文件后，需要等待 WSL 子系统完全停止（约 8 秒）才会生效。

### 应用配置更改

```bash
# 方法 1：关闭所有发行版（推荐）
wsl --shutdown

# 方法 2：终止特定发行版
wsl --terminate Ubuntu

# 验证是否已停止
wsl --list --running
# 输出 "没有正在运行的分发版" 表示已停止

# 重新启动
wsl
```

---

## 🔧 常用技巧

### 1. 启用 systemd

编辑 `/etc/wsl.conf`：

```bash
sudo nano /etc/wsl.conf
```

添加：

```ini
[boot]
systemd=true
```

重启 WSL：

```bash
# 在 PowerShell 中执行
wsl --shutdown

# 重新进入 WSL
wsl
```

验证：

```bash
systemctl list-unit-files --type=service
```

### 2. 访问 Windows 文件

```bash
# Windows C 盘位于（默认挂载点）
cd /mnt/c

# 如果修改了 automount.root=/
cd /c
```

### 3. 在 Windows 中访问 WSL 文件

```bash
# Windows 文件资源管理器访问
\\wsl$\Ubuntu\home\username

# 或直接在 WSL 中打开
explorer.exe .
```

### 4. 网络端口转发

WSL 2 默认通过 NAT 网络，可以通过 Windows 的 localhost 访问 WSL 服务：

```bash
# 在 WSL 中启动服务（如 Node.js）
npm run dev  # 监听 localhost:3000

# 在 Windows 中访问
http://localhost:3000
```

如需从外部网络访问，需要配置端口转发：

```powershell
# PowerShell（管理员）
netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=<WSL_IP>

# 获取 WSL IP
wsl hostname -I
```

### 5. 自定义 DNS

禁用自动生成的 DNS 配置：

```bash
# /etc/wsl.conf
[network]
generateResolvConf=false
```

手动配置 DNS：

```bash
sudo rm /etc/resolv.conf
sudo nano /etc/resolv.conf
```

添加（例如使用 Cloudflare DNS）：

```
nameserver 1.1.1.1
nameserver 8.8.8.8
```

### 6. 限制 WSL 资源使用

创建 `.wslconfig`（`%UserProfile%\.wslconfig`）：

```ini
[wsl2]
# 限制内存
memory=4GB

# 限制 CPU
processors=2

# 禁用 swap
swap=0
```

---

## 🆘 故障排查

### 问题 1：WSL 启动慢或卡死

**解决方案**：

```bash
# 完全关闭 WSL
wsl --shutdown

# 重启 WSL 服务（PowerShell 管理员）
Restart-Service LxssManager
```

### 问题 2：网络无法连接

**解决方案**：

```bash
# 重置网络配置
wsl --shutdown

# 删除自动生成的 resolv.conf
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
```

### 问题 3：内存占用过高

**解决方案**：

在 `.wslconfig` 中限制内存：

```ini
[wsl2]
memory=4GB

[experimental]
autoMemoryReclaim=gradual  # 自动回收内存
```

### 问题 4：磁盘空间未释放

**解决方案**：

启用稀疏 VHD：

```ini
# .wslconfig
[experimental]
sparseVhd=true
```

手动压缩 VHD：

```powershell
# PowerShell（管理员）
wsl --shutdown
diskpart

# 在 diskpart 中
select vdisk file="C:\Users\<YourUsername>\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu_*\LocalState\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

### 问题 5：systemd 未启动

**检查**：

```bash
# 检查 WSL 版本（需要 0.67.6+）
wsl --version

# 更新 WSL
wsl --update

# 检查配置
cat /etc/wsl.conf
```

---

## 📚 参考资源

-   [官方文档：WSL 配置](https://learn.microsoft.com/zh-cn/windows/wsl/wsl-config)
-   [官方文档：WSL 基础命令](https://learn.microsoft.com/zh-cn/windows/wsl/basic-commands)
-   [官方文档：WSL 网络](https://learn.microsoft.com/zh-cn/windows/wsl/networking)
-   [GitHub：WSL](https://github.com/microsoft/WSL)

---

## 💡 最佳实践

1. **启用 systemd**：让 WSL 更接近原生 Linux 体验
2. **限制资源**：避免 WSL 占用过多系统资源
3. **自定义挂载点**：使用 `root=/` 简化路径
4. **启用稀疏 VHD**：自动回收磁盘空间
5. **禁用不需要的服务**：如不需要 Windows 互操作，可禁用 `interop`
