# 现代 Linux 网络配置指南 (iwd + networkd + resolved)

## 1. 无线网卡层 (iwd)

iwd 负责 Wi-Fi 扫描、认证和链路建立。我们将 DHCP 和 IP 寻址交给 networkd 以实现统一管理。

```bash
#───────────────────────────────────────────────────────────────────────────────────
# File: /etc/iwd/main.conf
#───────────────────────────────────────────────────────────────────────────────────
[General]
# 开启网络随机化（隐私增强）
AddressRandomization=network

# 禁用 iwd 内置的 DHCP 客户端，改用 systemd-networkd
EnableNetworkConfiguration=false
#───────────────────────────────────────────────────────────────────────────────────
```

## 2. 网络管理层 (systemd-networkd)

负责管理网卡状态、获取 IP 地址以及处理多网卡共存逻辑。

### 有线网卡：
```bash
#──────────────────────────────────────────────────────────────────────────────────
# File: /etc/systemd/network/20-wired.network
#──────────────────────────────────────────────────────────────────────────────────
[Match]
Name=en*

[Link]
# 系统启动时不强制等待有线网接通
RequiredForOnline=no

[Network]
# 动态获取 IP 地址
DHCP=yes

# 设置静态 IP 地址和网关
# Address=192.168.1.100/24
# Gateway=192.168.1.1

# 调整优先级（值越小越优先）
# RouteMetric=100
#──────────────────────────────────────────────────────────────────────────────────
```

### 无线网卡：
```bash
#──────────────────────────────────────────────────────────────────────────────────
# File: /etc/systemd/network/25-wireless.network
#──────────────────────────────────────────────────────────────────────────────────
[Match]
Name=wl*

[Link]
# 只要无线网可路由，即视为网络在线
RequiredForOnline=routable

[Network]
# 动态获取 IP 地址
DHCP=yes

# 设置静态 IP 地址和网关
# Address=192.168.1.101/24
# Gateway=192.168.1.1

# 允许 WiFi 短暂断开（如漫游或干扰）而不立即撤销 IP
IgnoreCarrierLoss=3s
#─────────────────────────────────────────────────────────────────────────────────
```

### 启动等待优化：
```
#───────────────────────────────────────────────────────────────────────────────────
# File: /etc/systemd/system/systemd-networkd-wait-online.service.d/any.conf
#───────────────────────────────────────────────────────────────────────────────────
[Service]
# 清空默认的 ExecStart
ExecStart=

# 只要有任意一个接口（有线或无线）上线，系统即认为网络就绪
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any
#───────────────────────────────────────────────────────────────────────────────────
```

## 3. 域名解析层 (systemd-resolved)

通过 Drop-in 配置实现特定域名（如 Tailscale）的定向解析，并避免与本地 mDNS 服务冲突。

### 第一步：创建系统符号链接

必须确保 /etc/resolv.conf 指向 resolved 的 Stub 文件，否则本地应用无法识别配置。
```bash
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### 第二步：特定域解析配置（搜索域补全）
```bash
#──────────────────────────────────────────────────────────────────────────────────
# File: /etc/systemd/resolved.conf.d/magicdns.conf
#──────────────────────────────────────────────────────────────────────────────────
[Resolve]
# Tailscale DNS 节点
DNS=100.100.100.100

# 仅针对该后缀使用上述 DNS 服务器
Domains=example.ts.net

# 显式关闭 resolved 的 mDNS 响应器，交给 Avahi 专门处理
MulticastDNS=no

# 禁用本地多播域名解析
LLMNR=no
#──────────────────────────────────────────────────────────────────────────────────
```

## 4. 本地发现与名称切换 (Avahi & NSS)

为了让系统能够正确解析 .local 域名和 resolved 管理的域名，需要调整系统名称解析顺序。
/etc/nsswitch.conf

修改 hosts: 行，在 `resolve` 之前，插入 `mdns_minimal` 和 `[NOTFOUND=return]` 。
```bash
#────────────────────────────────────────────────────────────────────────────────────────────────────
# File: /etc/nsswitch.conf
#────────────────────────────────────────────────────────────────────────────────────────────────────
hosts: mymachines **mdns_minimal** **[NOTFOUND=return]** resolve [!UNAVAIL=return] files myhostname dns
#────────────────────────────────────────────────────────────────────────────────────────────────────

## 5. 服务激活清单

完成配置后，请确保所有核心组件均已启动：
```bash
# 停止并禁用传统网络管理工具（如果存在）
sudo systemctl disable --now NetworkManager wpa_supplicant

# 启用并启动当前架构组件
sudo systemctl enable --now iwd systemd-networkd systemd-resolved avahi-daemon
```

验证状态
- 检查物理链路： `iwctl device list`
- 检查 IP 获取： `networkctl status`
- 检查 DNS 路由： `resolvectl status`
