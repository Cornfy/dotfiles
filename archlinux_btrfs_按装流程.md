分区结构

```txt
硬盘1 /dev/sda
-----------------------------------------------------------------------------------------
|    /dev/sda1   |                              /dev/sda2                               |
-----------------------------------------------------------------------------------------
|   EFI (Fat32)  |            archlinux (btrfs，包含 @、@home、@var_log 等子卷)          |
-----------------------------------------------------------------------------------------
```

```txt
硬盘2 /dev/sdb （假设 Windows 已经装好）
-------------------------------------------------------------------
|    /dev/sda1   |          /dev/sdb2         |     /dev/sdb3     |
-------------------------------------------------------------------
|   EFI (Fat32)  |     Windows C盘 (NTFS)     |     D盘 (NTFS)    |
-------------------------------------------------------------------
```

```txt
archlinux 的子卷结构
├── @                 --> /                        archlinux根分区
│
├── 硬盘1的EFI         --> /boot/efi                挂载 archlinux 启动引导分区
├── 硬盘2的EFI         --> /boot/efi_windows        挂载 Windows 启动引导分区（便于grub启动双系统，而无需切换硬盘启动顺序）
│
├── @home             --> /home                    挂载 /home 用户文件夹
├── @var_log          --> /var/log                 挂载 archlinux 系统日志文件夹
├── @var_cache        --> /var/cache               挂载 archlinux 系统缓存文件夹
├── @var_lib_docker   --> /var/lib/docker          挂载 archlinux 上的 docker 文件夹
│
└── @swap             --> /swap                    挂载 archlinux 上的 swap 分区
    └── swapfile      --> /swap/swapfile           在 @swap 上创建 swapfile 虚拟内存文件
```





#### 开始安装 archlinux

- 检查是否为 EFI 模式启动

```shell
# 验证启动模式是否为UEFI
cat /sys/firmware/efi/fw_platform_size
    # 返回值为 64 或 32 ，表示是64/32位UEFI启动
    # 未找到文件，说明是BIOS启动（或未经配置或的虚拟机）

# 设置最大字体
setfont ter-132b
    # 也可以执行 setfont -d 设置双倍字体大小
```



- 联网

```shell
# 联网
iwctl
    device list                 	# 一般会找到 wlan0 网卡
    station wlan0 scan          	# 扫描
    station wlan0 get-networks  	# 列出可用WiFi
    station wlan0 connect SSID  	# SSID替换为实际WiFi名
        # 输入WiFi密码
    	# ctrl+d 退出 iwctl


# 更新 ArchISO 的系统时间
timedatectl set-timezone Asia/Shanghai
    #也可简单执行 timedatectl


# 测试网络
ping archlinux.org
    # ctrl+c 中断
```



- 准备分区

```shell
# 查看当前分区结构
lsblk


# 如需调整分区结构，可使用fdisk、cfdisk、gdisk等工具
# 例如
cfdisk /dev/sda
    # cfdisk 自带 tui 类图形界面
    # cfdisk 后面的参数要跟硬盘（如 /dev/sda）而不是分区（如 /dev/sda1）


# 格式化分区（以 /dev/sda2 作为archlinux根目录 / 为例）
mkfs.fat -F32 /dev/sda1                     # EFI 分区应该是 Fat32 文化系统
mkfs.btrfs -f -L "archlinux" /dev/sda2      # -L 是参数设置该卷的标签


# 由于 Arch ISO 是只读的（修改会在重启后清空），
# 所以需要把硬盘挂载到 Arch ISO 的 /mnt 目录下操作，才能将修改保留在硬盘中


# 临时挂载和创建根子卷
mount /dev/sda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_cache
btrfs subvolume create /mnt/@var_lib_docker
btrfs subvolume create /mnt/@swap
umount /mnt


# 挂载根子卷
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@ /dev/sda2 /mnt


# 在根子卷中创建挂载点
mkdir -p /mnt/{boot/efi,boot/efi_windows,home,var/log,var/cache,var/lib/docker,swap}


# 挂载 EFI 启动分区
mount -o noauto,nofail,x-systemd.automount /dev/sda1 /mnt/boot/efi
mount -o noauto,nofail,x-systemd.automount /dev/sdb1 /mnt/boot/efi_windows


# 挂载 @home 子卷
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@home /dev/sda2 /mnt/home


# 挂载其他子卷
#################################################################################################
# 根据 btrfs man - MOUNT_OPTIONS：
# "在单个文件系统中，无法将某些子卷挂载为 nodatacow ，而将其他子卷挂载为 datacow 。
# 第一个已挂载的子卷的挂载选项适用于任何其他子卷。”
#
# - 有透明压缩，我们实际上不用担心/var/{log,cache} 目录中，由于碎片整理带来的额外写放大。
# - 而对于 /var/lib/docker 目录，也不建议直接禁用对应子卷的 CoW ，而是建议对大型数据库项目，
#   单独指定数据库存放到外部路径，并手动对该路径执行 chattr +C（禁用 CoW ）
#
# 总之：
# 1. 不要信任 nodatacow 挂载参数；
# 2. 你可以全盘开启透明压缩（zstd）和写时复制（CoW），利大于弊；
# 3. 对大型数据库，手动执行 chattr + C 即可。
###################################################################################################
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@var_log /dev/sda2 /mnt/var/log
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@var_cache /dev/sda2 /mnt/var/cache
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@var_lib_docker /dev/sda2 /mnt/var/lib/docker
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@swap /dev/sda2 /mnt/swap


# 创建 swapfile
btrfs filesystem mkswapfile --size 8G --uuid clear /mnt/swap/swapfile
	# 如需休眠功能，一般建议 swap 的大小 >= 物理内存大小
	# 内存大小可用 free -h 查看
	# btrfs 中的 swapfile 必须禁用加密和写时复制（这里用 btrfs 内部命令创建 swapfile 会自动禁用）
	# 正常创建 swap 分区是使用 mkswap 命令

# 启用 swapfile
swapon /mnt/swap/swapfile


# （可选）挂载 Windows 分区
mkdir -p /mnt/mnt/{Windows_C,Windows_D}
mount -t ntfs3 /dev/sdb2 /mnt/mnt/Windows_C
mount -t ntfs3 /dev/sdb3 /mnt/mnt/Windows_D
	# 在较新的 Linux 内核中，已经内置了 ntfs3 来支持 NTFS 文件系统
	# Arch ISO 中保留了 ntfs-3g 包作为兜底
	# 由于 ntfs3 的性能更好，我们显示指定使用 ntfs3 来挂载，避免使用默认的 ntfs-3g
```



- 安装 Arch Linux 基础系统
  - 最基本的安装只需要 `base linux linux-firmware` 三个包
  - `base` —— Arch Linux 的基础包组
  - `linux` —— Linux 系统内核
    - 也可安装其他内核，如 `linux-zen`
  - `linux-firmware` —— Linux 系统固件
  - `intel-ucode` —— Intel 微码
    - 如果你是 AMD CPU ，应该安装 `amd-ucode` 
  - `archinstall` —— Arch Linux 安装脚本，它提供了很多方便的工具（如 arch-chroot 、 genfstab 等）
  - `grub` 、 `efibootmgr` —— 提供 EFI 系统引导
  - `os-prober` —— 用来自动检测其他系统引导（如 Windows Boot Manager）
  - `dhcpcd` —— 用来动态分配 IP 地址
  - `iwd` 、 `networkmanager` —— 两个联网工具
    - `iwd` 提供了 Arch ISO 中的 iwctl 命令
    - `networkmanager` 提供了 nmtui 命令（一个终端下的 “图形化” 联网工具）
  - `vim` —— 文本编辑器
    - 你也可以安装 `nano` 、 `micro` 等文本编辑器
  - `sudo`—— 提权工具
  - `fish` 一个默认自带输入预测的 shell ，你也可以安装其他 shell
    - Arch Linux 的默认 shell 是 `bash`
    - Arch ISO 中的 shell 是 `zsh`
  - `ntfs-3g` —— 提供挂载 Windows 的 NTFS 分区的能力
    - 在较新的 Linux 内核中内置了 ntfs3 ，且性能更好，因此可以不装 ntfs-3g
    - 但若安装 archinstall ，则 ntfs-3g 会作为 archinstall 的依赖被安装

```shell
# 更新 Arch ISO 中的软件源（切换为国内镜像源）
reflector --country China --protocol https --save /etc/pacman.d/mirrorlist
    # 可用 vim 查看
    vim /etc/pacman.d/mirrorlist
        # 按 i 进入编辑
        # 确认无误后可按 :wq 保存退出
        # 若修改错误，可按 esc 回常规模式，再按 u 撤销
        # 也可按 esc 后，按 :q! 不保存强制退出。


# 仅更新 Arch ISO 中的 archlinux 密钥环
pacman -Sy archlinux-keyring


# 安装 archlinux 系统
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode archinstall grub efibootmgr os-prober dhcpcd iwd networkmanager vim sudo fish
    # 使用 pacstrap 命令，向挂载在 /mnt 的 archlinux 的根分区 /dev/sda2 (的 @ 子卷) 中装入软件包
    # pacstrap 会自动将 Arch ISO 中的软件源（ /etc/pacman.d/mirrorlist ）复制到新安装的 archlinux 中


# 使用 archinstall 中自带的工具将 Arch ISO 中的挂载信息，
# 写入新装好的 archlinux 系统的 /etc/fstab 文件中
genfstab -U /mnt >> /mnt/etc/fstab
    # >> 代表将全面命令的输出信息（一般是输出到终端上），重定向到后面的文件中
    	# > 表示清空其后面的文件，并写入前面命令的输出
    	# >> 表示不清空其后面的文件，直接在该文件末尾（下一行）追加前面命令的输出


# 核对 fstab 文件（该文件影响 archlinux 装好后，启动时的分区挂载），
# 修改成自己希望挂载参数（参考上面的挂载参数）
vim /mnt/etc/fstab
    # 按 i 进入编辑
    # 确认无误后可按 :wq 保存退出
    # 若修改错误，可按 esc 回常规模式，再按 u 撤销
    # 也可按 esc 后，按 :q! 不保存强制退出。
```



  - fstab 文件的示例
    - efi_windows 设置了 ro 参数（只读），防止意外修改 Windows 引导；
    - Windows_C 、Windows_D 使用 ntfs3 来挂载，并设置了 nofail 参数，即使挂载失败也不影响 Arch Linux 启动；
    - 除了 @ 、@home 外，使用 nodatacow,compress=no 参数，禁用压缩话写时复制； 

```txt
# Static information about the filesystems.
# See fstab(5) for details.

# <file system> <dir> <type> <options> <dump> <pass>
# /dev/sda2 LABEL=archlinux_rootfs
UUID=xxxx-xxxx	/         	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@	0 0

# /dev/sda1 LABEL=efi
UUID=xxxx-xxxx      	/boot/efi 	vfat      	rw,relatime,fmask=0077,dmask=0077,noauto,nofail,x-systemd-automount	0 0

# /dev/nvme0n1p1 LABEL=efi_windows
UUID=xxxx-xxxx      	/boot/efi_windows	vfat      	ro,relatime,fmask=0077,dmask=0077,noauto,nofail,x-systemd-automount	0 0

# /dev/sda2 LABEL=home
UUID=xxxx-xxxx	/home     	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@home	0 0

# /dev/sda2 LABEL=var_log
UUID=xxxx-xxxx	/var/log  	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@var_log	0 0

# /dev/sda2 LABEL=var_cache
UUID=xxxx-xxxx	/var/cache	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@var_cache	0 0

# /dev/sda2 LABEL=var_lib_docker
UUID=xxxx-xxxx	/var/lib/docker	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@var_lib_docker	0 0

# /dev/nvme0n1p2 LABEL=windows_c
UUID=xxxx-xxxx      	/mnt/Windows_C	ntfs3      	rw,relatime,fmask=0022,dmask=0022,nofail,uid=1000,gid=1000,iocharset=utf8	0 0

# /dev/nvme0n1p3 LABEL=windows_d
UUID=xxxx-xxxx      	/mnt/Windows_D	ntfs3      	rw,relatime,fmask=0022,dmask=0022,nofail,uid=1000,gid=1000,iocharset=utf8	0 0

# /dev/sda2 LABEL=swap
UUID=xxxx-xxxx	/swap     	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@swap	0 0

/swap/swapfile      	none      	swap      	defaults  	0 0

```



#### 初始化系统

- 基本配置

```shell
# 进入到新装好的archlinux
arch-chroot /mnt

# 设置时期
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 用 NTP 同步时间
timedatectl set-ntp true

# 生成 /etc/adjtime
hwclock --systohc
    # 这个命令假定已设置硬件时间为 UTC 时间。

# 修改区域和本地化设置
vim /etc/locale.gen
    # 输入 /en_US 搜索，回车确认
    # 方向键找到 en_US.UTF-8 UTF-8 行
    # 按 home键 去到行首
    # 按 x 或 del键 去掉 # 号注释
    # 按 :wq 保存退出

# 生成本地化设置
locale-gen
    # 之后安装了图形界面和中文字体后
    # 可启用 /etc/locale.gen 中的 zh_CN.UTF-8 行
    # 并重新执行 locale-gen 命令（非root需要sudo）

# 修改系统语言（全局设置）
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
    # 这个文件应该是空的
    # 我偷懒使用 echo 了，你也可以使用 vim 编辑它
    # 一般不建议直接将它设为中文
    # （毕竟tty下中文是方块，而全局设置对root用户也生效）

# 设置主机名
echo "archlinux" >> /etc/hostname
    # 这个文件应该是空的
    # 我偷懒使用 echo 了，你也可以使用 vim 编辑它
    # 引号内是你可以自定义修改的「主机名」
```



- 设置 host （影响域名解析）

```shell
# 设置网络配置
vim /etc/hosts
```

- 添加如下内容（可用tab对齐）
  - `127.0.0.1` 为 IPv4 地址
  - `::1` 为 IPv6 地址

```txt
127.0.0.1	localhost
::1			localhost
127.0.1.1	archlinux.localdomain	archlinux
```



- 安装系统引导
```shell
# 创建 initramfs
mkinitcpio -P
    # 通常不需要自己创建新的 initramfs
    # 因为在执行 pacstrap 时已经安装 linux（包），这时已经运行过 mkinitcpio 了。


# 安装 Grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

    # 如果是使用 BIOS 方式引导，那么安装 Grub 的命令应该是：
    grub-install --target=i386-pc --bootloader-id=GRUB /dev/sda
        # 注意，BIOS 方式应该安装到硬盘（如：/dev/sda ），而不是分区（如：/dev/sda1）

    # 如果你的平台不是 x86_64 ，请参考 Arch Wiki

# 生成 Grub 配置
grub-mkconfig -o /boot/grub/grub.cfg


# 如需多系统引导，请修改 /etc/default/grub 文件，并重新生成grub配置
vim /etc/default/grub
    # 取消 GRUB_DISABLE_OS_PROBER=FALSE 的注释

    # （可选）对于高分辨率屏幕，可调整 GRUB 的屏幕分辨率来方法界面
    	# 将 GRUB_GFXMODE=auto 行中的 auto 改成 1024x768 
        # 注意，是英文字母 x 而不是 “乘以” 符号

    # 保存退出

# 需要更新 Grub 配置文件
grub-mkconfig -o /boot/grub/grub.cfg

    # 后续可安装 aur 仓库中的 `update-grub` 包，来完成 grub 更新操作，以后直接执行 `sudo update-grub` 即可
```



- 设置 root 密码、添加普通用户

```shell
# 设置 root 用户的密码
passwd
    # 输入 root 用户的新密码

# （可选）授予 wheel 组执行 sudo 的权限
ln -s /usr/bin/vim /usr/bin/vi      #单纯我懒得装 vi
visudo
    # 按 /wheel 搜索，回车确认
    # 方向键找到 # %wheel ALL=(ALL:ALL) ALL 行
    # 按 home键 去行首
    # 按 x 或 del键 去掉 # 号注释
    # 按 :wq 保存退出

# （可选）创建普通用户，以用户名 elysia 为例
useradd -m -G wheel -s /bin/fish elysia
passwd elysia
    # 输入 elysia 的密码

# 注意，后续添加其他用户时：
    # 如果不希望其拥有 sudo 的权限，不要添加 -G wheel 参数
    # 如果使用其他 shell，请使用 -s 指定，如 -s /bin/bash 或 -s /bin/zsh
    # 之前已经装过 fish ，新的 archlinux 默认使用的是 bash
```



#### 可以重启了

- 首次重启后联网

```shell
# 需先启用 dhcpcd
# 然后启用 NetworkManager 或 iwd 服务（最好二选一）
# NetworkManager 自带一个 tui 图形界面，使用 nmtui 命令启动
sudo systemctl enable --now dhcpcd
sudo systemctl enable --now NetworkManager
nmtui
    # 根据提示连接 WiFi

# 测试网络并更新系统
ping archlinux.org
    # ctrl+c 中断
sudo pacman -Syyu
```



#### 至此 archlinux 已装好，可以愉快地玩耍啦！

- （可选）安装图形界面，以 Gnome 桌面为例
  - 如需图形界面，可安装 `wayland` 、 `xorg-xwayland` 、 `xorg-server` 、 `xorg-xinit` 等包
  - 再安装 `i3` 、 `sway` 、 `hyprland` 等窗口管理器
  - 或安装 `plasma-desktop` 、 `gnome-desktop` 等桌面环境

```shell
# 安装显示管理器 wayland 和 xorg
sudo pacman -S wayland xorg-xwayland xorg-server xorg-xinit

# 安装 Gnome 桌面和 Gnome 终端模拟器
sudo pacman -S gnome-shell gnome-desktop gnome-console

# 在 tty 里可直接启动 gnome（wayland） 桌面
gnome-shell --wayland

# 也可以安装登录管理器，以 gdm 为例
sudo pacman -S gdm
sudo systemctl enable --now gdm
	# enable 仅仅设置了开机启动，本次不生效，重启后生效
	# 添加 --now 参数立即生效

# 控制 systemd 服务的命令为：
# systemctl <参数> <服务名>
	# 常用参数：
		# enable	设置服务的开机启动
		# disable	取消服务的开机启动
		# start		立即启动服务
		# stop		立即停止服务
		# restart	立即重启服务
		# status	查看服务状态
```



#### 一些骚操作 ####

```shell
# 编辑 pacman 配置文件
sudo vim /etc/pacman.conf
	# 启用颜色：
    # 按 /Color 搜索，方向键导航到行首，（按 x 删除 # 号）取消 Color 行的注释

    # 启用多线程下载：
    # 方向键导航到 ParallelDownloads = 5 行的行首，（按 x 删除 # 号）取消注释

    # 启用吃豆人小彩蛋：
    # 按 i 进入编辑
    # 在 # Misc options 板块中增加一个新的空行，在空行中写入 ILoveCandy
    # 按 :wq 保存退出



# 启用 archlinuxcn 软件源
# ⚠️ 注意：这不是官方软件源!!!

# 编辑 pacman 配置文件
sudo vim /etc/pacman.conf

	# 按 shift + g 导航到尾行
	# 按 o 增加空行并编辑（可回车再增加一个空行）
	# 添加以下内容并保存退出：
	[archlinuxcn]
	Include = /etc/pacman.d/mirrorlist-archlinuxcn

# 然后编辑 /etc/pacman.d/mirrorlist-archlinuxcn 文件
sudo vim /etc/pacman.d/mirrorlist-archlinuxcn

	# 添加你想使用的 CN 源，例如：
	Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
	Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
	Server = https://mirrors.aliyun.com/archlinuxcn/$arch
	# 更多 CN 源码请参考网址：https://github.com/archlinuxcn/mirrorlist-repo
	# 保存退出

# 更新 archlinuxcn 密钥环
sudo pacman -Sy archlinuxcn-keyring



# 由于之前已经将 Windows 的 C盘 挂载到 /mnt/mnt/Windows_C ，因此可以直接用 Windows 字体
# 将 Windows 字体复制到 archlinux 中
sudo cp -rp /mnt/Windows_C/Windows/Fonts /usr/share/fonts/WindowsFonts

# 更新字体缓存
fc-cache -fv
```

