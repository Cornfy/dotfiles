分区结构

```txt
硬盘1 /dev/sda
---------------------------------------------------------------------------------------
|   EFI (Fat32)  |            archlinux (btrfs，包含 @、@home、@var_log 等子卷)          |
---------------------------------------------------------------------------------------
```

```txt
硬盘2 /dev/sdb
----------------------------------------------------------------
|   EFI (Fat32)  |     win11 C盘 (NTFS)     |     D盘 (NTFS)    |
----------------------------------------------------------------
```

```txt
archlinux 的子卷结构
├── @                 --> /                        archlinux根分区
├── 硬盘1的EFI         --> /boot/efi                挂载 archlinux 启动引导分区
├── 硬盘2的EFI         --> /boot/efi_windows        挂载 Windows 启动引导分区
│												   （便于grub启动双系统，而无需切换硬盘启动顺序）
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
mkfs.fat -F32 /dev/sda1
mkfs.btrfs -f -L "archlinux" /dev/sda2		# -L 是参数设置该卷的标签


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
mount -o noauto,nofail，x-systemd.automount /dev/sda1 /mnt/boot/efi
mount -o noauto,nofail，x-systemd.automount /dev/sdb1 /mnt/boot/efi_windows


# 挂载 @home 子卷
mount -o noatime,compress=zstd:3,ssd,space_cache=v2,subvol=@home /dev/sda2 /mnt/home


# 挂载其他子卷，并停用压缩、写时复制（CoW）
mount -o noatime,nodatacow,compress=no,ssd,space_cache=v2,subvol=@var_log /dev/sda2 /mnt/var/log
mount -o noatime,nodatacow,compress=no,ssd,space_cache=v2,subvol=@var_cache /dev/sda2 /mnt/var/cache
mount -o noatime,nodatacow,compress=no,ssd,space_cache=v2,subvol=@var_lib_docker /dev/sda2 /mnt/var/lib/docker
mount -o noatime,nodatacow,compress=no,ssd,space_cache=v2,subvol=@swap /dev/sda2 /mnt/swap


# 创建 swapfile
btrfs filesystem mkswapfile --size 8G --uuid clear /mnt/swap/swapfile
	# 如需休眠功能，一般建议 swap 的大小 >= 物理内存大小
	# 内存大小可用 free -h 查看
	# btrfs 中的 swapfile 必须禁用加密和写时复制
	# （我们挂载 @swap 子卷时已经禁用了，这里用 btrfs 内部命令创建 swapfile 也会自动禁用）
	# 正常创建 swap 分区是使用 mkswap 命令


# （可选）挂载 Windows 分区
mkdir -p /mnt/mnt/{Windows_C,Windows_D}
mount /dev/sdb2 /mnt/mnt/Windows_C
mount /dev/sdb3 /mnt/mnt/Windows_D
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
  - `sudo` 是提权工具
  - `fish` 是一个默认自带输入预测的 shell ，你也可以安装其他 shell
    - Arch Linux 的默认 shell 是 `bash`
    - Arch ISO 中的 shell 是 `zsh`
  - `ntfs-3g` 提供挂载 Windows 的 NTFS 分区的能力

```shell
# 更新镜像源
pacman -Sy archlinux-keyring pacman-mirrorlist
reflector --country China --protocol https --save /etc/pacman.d/mirrorlist
    # 可用 vim 查看
    vim /etc/pacman.d/mirrorlist
        # 按 i 进入编辑
        # 确认无误后可按 :wq 保存退出
        # 若修改错误，可按 esc 回常规模式，再按 u 撤销
        # 也可按 esc 后，按 :q! 不保存强制退出。


# 安装 archlinux 系统
pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode archinstall grub efibootmgr os-prober dhcpcd iwd networkmanager vim sudo fish ntfs-3g
    # 使用 pacstrap 命令，向挂载在 /mnt 的 archlinux 的根分区 /dev/sda2 (的 @ 子卷) 中装入软件包


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
    - Windows_C 、Windows_D 设置了 nofail 参数，即使挂载失败也不影响 Arch Linux 启动；
    - 除了 @ 、@home 外，使用 nodatacow,compress=no 参数，禁用压缩话写时复制； 

```txt
# Static information about the filesystems.
# See fstab(5) for details.

# <file system> <dir> <type> <options> <dump> <pass>
# /dev/sda2 LABEL=archlinux_rootfs
UUID=d71ff479-f8c4-4bd1-9c4b-a5ff0c07614a	/         	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@	0 0

# /dev/sda1 LABEL=efi
UUID=CEE3-84FE      	/boot/efi 	vfat      	rw,relatime,fmask=0077,dmask=0077,noauto,nofail,x-systemd-automount	0 0

# /dev/nvme0n1p1 LABEL=efi_windows
UUID=6F85-B74E      	/boot/efi_windows	vfat      	ro,relatime,fmask=0077,dmask=0077,noauto,nofail,x-systemd-automount	0 0

# /dev/sda2 LABEL=home
UUID=d71ff479-f8c4-4bd1-9c4b-a5ff0c07614a	/home     	btrfs     	rw,noatime,nodatacow,compress=no,ssd,discard=async,space_cache=v2,subvol=/@home	0 0

# /dev/sda2 LABEL=var_log
UUID=d71ff479-f8c4-4bd1-9c4b-a5ff0c07614a	/var/log  	btrfs     	rw,noatime,nodatacow,compress=no,ssd,discard=async,space_cache=v2,subvol=/@var_log	0 0

# /dev/sda2 LABEL=var_cache
UUID=d71ff479-f8c4-4bd1-9c4b-a5ff0c07614a	/var/cache	btrfs     	rw,noatime,nodatacow,compress=no,ssd,discard=async,space_cache=v2,subvol=/@var_cache	0 0

# /dev/sda2 LABEL=var_lib_docker
UUID=d71ff479-f8c4-4bd1-9c4b-a5ff0c07614a	/var/lib/docker	btrfs     	rw,noatime,nodatacow,compress=no,ssd,discard=async,space_cache=v2,subvol=/@var_lib_docker	0 0

# UUID=5A0A2394DEE85411 LABEL=Windows
/dev/nvme0n1p2      	/mnt/Windows_C	ntfs      	rw,nosuid,nodev,fmask=0022,dmask=0022,nofail,uid=1000,gid=1000,allow_other,blksize=4096	0 0

# UUID=BB4329F6136D7AB7 LABEL=Data
/dev/nvme0n1p3      	/mnt/Windows_D	ntfs      	rw,nosuid,nodev,fmask=0022,dmask=0022,nofail,uid=1000,gid=1000,allow_other,blksize=4096	0 0

# /dev/sda2 LABEL=swap
UUID=d71ff479-f8c4-4bd1-9c4b-a5ff0c07614a	/swap     	btrfs     	rw,noatime,nodatacow,compress=no,ssd,discard=async,space_cache=v2,subvol=/@swap	0 0

/swap/swapfile      	none      	swap      	defaults  	0 0

```



#### 初始化系统

- 基本配置

```shell
# 进入到新装好的archlinux
arch-chroot /mnt

# 设置时期
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 同步时间
timedatectl
    # 之后正常启动可使用NTP同步时间，以确保时间准确
    timedatectl set-ntp true		# 非root帐号需要sudo

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
  - 设置 `localhost`（域名） 指向 `127.0.0.1`（IPv4 地址）
  - 设置 `localhost`（域名） 指向 `::1`（IPv6 地址）

```shell
# 设置网络配置
vim /etc/hosts
```

```txt
# 添加如下内容（可用tab对齐）
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

# 安装grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

# 生成grub配置
grub-mkconfig -o /boot/grub/grub.cfg

# 如需多系统引导，请修改 /etc/default/grub 文件，并重新生成grub配置
vim /etc/default/grub
    # 取消 GRUB_DISABLE_OS_PROBER=FALSE 的注释
    # 保存退出
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

# 安装 Gnome 桌面
sudo pacman -S gnome-shell gnome-desktop

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
# 修改 pacman 配置，启用颜色、多线程下载和吃豆人
sudo vim /etc/pacman.conf
    # 按 /Color 搜索，回车确定
    # 取消 Color 的注释
    # 取消 ParallelDownloads = 5 的注释
    # 按 i 编辑，在下方空行写入 ILoveCandy
    # 按 :wq 保存退出

# 由于之前已经将 Windows 的 C盘 挂载到 /mnt/mnt/Windows_C ，因此可以直接用 Windows 字体
# 将 Windows 字体复制到 archlinux 中
sudo cp -rp /mnt/Windows_C/Windows/Fonts /usr/share/fonts/WindowsFonts

# 更新字体缓存
fc-cache -fv
```

