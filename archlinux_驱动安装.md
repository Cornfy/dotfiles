# Arch Linux 驱动安装

建议**优先参照 Arch Wiki 从[这里](https://wiki.archlinux.org/title/Xorg#Driver_installation)自行选择适用的驱动程序软件包**，其次再参考本教程。



## Intle 显卡驱动

摘抄自 [Arch Wiki - Intel_graphics](https://wiki.archlinux.org/title/Intel_graphics) ，建议自行阅读。



#### Intel 显卡驱动 - 安装

- **操作步骤**

```shell
# 编辑 `/etc/pacman.conf` 文件，启用 multilib 存储库
sudo vim /etc/pacman.conf
	# 取消以下两行的注释：
	[multilib]
	Include = /etc/pacman.d/mirrorlist


# 更新存储库
sudo pacman -Syy


# 安装 Intel 驱动程序
sudo pacman -S mesa lib32-mesa xorg-server vulkan-intel lib32-vulkan-intel
	# 适用于 4 代及以上
	# 其他型号建议参考后面的详细说明来确定软件包
```



- **提供用于 3D 加速的 DRI 驱动程序：**

```txt
对于 DRI 支持，安装以下软件包：

- mesa					Intel 第 3 代及以上
- lib32-mesa			32 位程序支持，需启用 multilib 存储库

- mesa-amber			Intel 第 2 ~ 11 代
- lib32-mesa-amber		32 位程序支持，需启用 multilib 存储库
# 优先考虑 mesa 包
```



- **Xorg 中提供 2D 加速的 DDX 驱动程序：**

```txt
对于 DDX 支持，安装以下软件包：

- xorg-server			Intel 第 4 代及以上
- xf86-video-intel		Intel 第 2 ~ 9 代
```



- **提供 Vulkan 支持:**

```txt
对于 Vulkan 支持，安装以下软件包：

- vulkan-intel
- lib32-vulkan-intel    32 位程序支持，需启用 multilib 存储库
```



#### Intel 显卡驱动 - 加载

- **1、Intel 内核模块会在系统引导时「自动加载」**

```shell
# 若未自动加载：
    # 由于 Intel 需要内核模式设置（KMS）工作，请确保您没有在内核参数中添加 nomodeset 。
    # 请同时确认您没有在 `/etc/modprobe.d/` 或 `/usr/lib/modprobe.d/` 中把 Intel 列入 modprobe 的黑名单导致禁用了 Intel 。



# 确认 Intel 显卡驱动模块是否已经被加载
lsmod | grep i915
	# 正确输出应该包含例如：
	i915                 323584  1

# 确认内核识别是否为 Intel 核显
lspci -k | grep -A 3 -E "VGA|3D"
	# 正确输出例如：
	00:02.0 VGA compatible controller: Intel Corporation Device 46a6 (rev 0c)
    	Subsystem: Lenovo Device 3802
    	Kernel driver in use: i915
    	Kernel modules: i915



# 如果为发现 Intel 显卡为启用，进一步检查原因

# 检查内核模式设置（KMS）中有没有 `nomodeset` ，「不应该有」
cat /proc/cmdline
	# 如果出现 `nomodeset` 则表示 KMS 被禁用
	BOOT_IMAGE=/boot/vmlinuz-linux root=UUID=xxxxxx rw nomodeset quiet
	# 需要删除它

# 检查 `/etc/default/grub`
sudo vim /etc/default/grub
	# 删除以下行中的 `nomodeset` 参数
	GRUB_CMDLINE_LINUX_DEFAULT="... nomodeset ..."
	GRUB_CMDLINE_LINUX="... nomodeset ..."
# 保证后更新 GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 检查 `/etc/mkinitcpio.conf`
sudo vim /etc/mkinitcpio.conf
	# 删除 `MODULES=()` 行的 () 中的 `nomodeset` 参数
	MODULES=(... nomodeset ...)

# 检查 `/etc/modprobe.d/` 和 `/usr/lib/modprobe.d/` 中是否设置了 Intel 模块的黑名单
grep -rnw '/etc/modprobe.d/' -e 'blacklist'
grep -rnw '/usr/lib/modprobe.d/' -e 'blacklist'
	# 如果看到类似以下内容，说明存在黑名单：
	/etc/modprobe.d/blacklist.conf:blacklist i915
	# 编辑对应文件
	sudo vim /etc/modprobe.d/blacklist.conf
		# 注释或删除以下内容
		blacklist i915

# 重新生成 initramfs
sudo mkinitcpio -P

# 重启系统
reboot
```



- **2、启用 GuC / HuC 固件加载（第 9 代以上）**

**⚠️ 注意：** 本章节的事实准确性存在争议；

**⚠️ 警告：** [即使您的显卡不支持相关功能](https://bugs.freedesktop.org/show_bug.cgi?id=111918)，手动启用 GuC/HuC 固件加载也可能会污染内核。此外，启用GuC/HuC固件加载可能会导致某些系统出现问题；如果您遇到冻结（例如，从休眠恢复后），请禁用它。

```shell
# 安装 `linux-firmware` 和 `intel-media-driver` 软件包，来启用硬件视频加速
sudo pacman -S linux-firmware intel-media-driver


# 编辑 `/etc/modprobe.d/i915.conf` ，配置 i915.enable_guc 内核参数
sudo vim /etc/modprobe.d/i915.conf
	# 文件在其中添加如下内容：
	options i915 enable_guc=3


# 重新生成 initramfs
sudo mkinitcpio -P
```



- **3、用查看是否启用**

```shell
# 执行 `dmesg` 命令
sudo dmesg | grep -E "GuC|HuC"
	# 看到类似这样的输出说明启用成功
	[30130.586970] i915 0000:00:02.0: [drm] GuC firmware i915/icl_guc_33.0.0.bin version 33.0 submission:disabled
	[30130.586973] i915 0000:00:02.0: [drm] HuC firmware i915/icl_huc_9.0.0.bin version 9.0 authenticated:yes
```





## AMD显卡驱动

摘抄自 [Arch Wiki - AMDGPU](https://wiki.archlinux.org/title/AMDGPU) ，建议自行阅读。



#### AMD 显卡驱动 - 安装

- **操作步骤**

```shell
# 编辑 `/etc/pacman.conf` 文件，启用 multilib 存储库
sudo vim /etc/pacman.conf
	# 取消以下两行的注释：
	[multilib]
	Include = /etc/pacman.d/mirrorlist


# 更新存储库
sudo pacman -Syy


# 安装 AMD 驱动程序
sudo pacman -S mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon
	# 建议参考后面的详细说明来确定软件包
```



- **提供用于 3D 加速的 DRI 驱动程序：**

```txt
对于 DRI 支持，安装以下软件包：

- mesa
- lib32-mesa			32 位程序支持，需启用 multilib 存储库
```



- **Xorg 中提供 2D 加速的 DDX 驱动程序：**

```txt
对于 DDX 支持，安装以下软件包：

- xf86-video-amdgpu
```



- **提供 Vulkan 支持:**

```txt
对于 Vulkan 支持，首先尝试「仅」安装以下软件包：
- vulkan-radeon
- lib32-vulkan-radeon	32 位程序支持，需启用 multilib 存储库


遇到问题才尝试「额外」安装以下软件包：
- amdvlk				
- lib32-amdvlk			32 位程序支持，需启用 multilib 存储库
```

⚠️ 注意：`(lib32-)amdvlk` 会将自己设置为默认的 Vulkan 驱动程序，如果需要与 `(lib32-)vulkan-radeon` 同时工作，请参阅 Arch Wiki 上的 [Vulkan#Selecting via environment variable](httpS://wiki.archlinux.org/title/Vulkan#Vulkan#Selecting_via_environment_variable) 条目



#### AMD 显卡驱动 - 加载

⚠️ 优先检查是否加载，如果 `amdgpu` **未使用**，按照后续的说明进行操作。

```shell
# 执行 `lspci` 命令查看 AMD 显卡是否启用
lspci -k -d ::03xx
	# 示例输出：
	01:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Curacao PRO [Radeon R7 370 / R9 270/370 OEM]
		Subsystem: Gigabyte Technology Co., Ltd Device 226c
		Kernel driver in use: amdgpu
		Kernel modules: radeon, amdgpu
```



- **启用 Southern Islands（SI）和 Sea Islands （CIK）支持**

  - ⚠️ 指定正确的模块顺序：
    确保 amdgpu 已设置为 [Mkinitcpio#MODULES](https://wiki.archlinux.org/title/Mkinitcpio#MODULES) 数组中的第一个模块，例如 `MODULES=(amdgpu radeon)` 。
  
  ```shell
  # 检查 `/etc/mkinitcpio.conf` 内核模块加载顺序
  sudo vim /etc/mkinitcpio.conf
  	# 确认 `MODULES=()` 的 () 中，`amdgpu` 是第一个模块
  	# 例如：
  	MODULES=(amdgpu radeon)
  
  
  # 等添加内核模块后，后再重新生成 initramfs
  ```
  
    
  
  - 添加内核模块并设备对应参数
  
  ```shell
  # 编辑 `/etc/modprobe.d/amdgpu.conf` 文件
  sudo vim /etc/modprobe.d/amdgpu.conf
  	# 添加如下内容：
  	options amdgpu si_support=1
  	options amdgpu cik_support=1
  
  
  # 编辑`/etc/modprobe.d/radeon.conf` 文件
  sudo vim /etc/modprobe.d/radeon.conf
  	# 添加如下内容：
  	options radeon si_support=0
  	options radeon cik_support=0
  
  
  # 等检查 `modconf` 后再重新生成 initramfs
  ```
  
  
  
  - 确保 `modconf` 在 `/etc/mkinitcpio.conf` 的  `HOOKS` 阵列中，并[重新生成 initramfs](https://wiki.archlinux.org/title/Regenerate_the_initramfs)。
  
  ```shell
  # 使用 vim 查看 `/etc/mkinitcpio.conf` 文化
  sudo vim /etc/mkinitcpio.conf
  	# 应该会看到未注释的 `HOOKS` 行有类似以下内容：
  	HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
  	# 如果没看到 `modconf` ，可手动添加
   
  
  # 重新生成 initramfs
  sudo mkinitcpio -P
  
  # 重启系统
  reboot
  ```





## NVIDIA 驱动

摘抄自 [Arch Wiki - NVIDIA](https://wiki.archlinux.org/title/NVIDIA) ，建议自行阅读。

**⚠️ 注意：** 如果您使用 Wayland ， 建议在安装和配置 NVIDIA 驱动前，[创建系统快照](https://wiki.archlinux.org/title/Timeshift)以便恢复（以免出现意外）。



- **NVIDIA 驱动 - 安装**

```shell
# 编辑 `/etc/pacman.conf` 文件，启用 multilib 存储库
sudo vim /etc/pacman.conf
	# 取消以下两行的注释：
	[multilib]
	Include = /etc/pacman.d/mirrorlist


# 更新存储库
sudo pacman -Syy


# NV160 及以上
sudo pacman -S nvidia-open-dkms nvidia-utils lib32-nvidia-utils
# NV160 具体指：
    # GeForce 16 系列
    # GeForce 20 系列


# NV110 ~ NV190
yay -S nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils
# NV110 具体指：
    # GeForce 700
    # GeForce 900
# NV190 具体指：
    # GeForce 40 系列


# 更旧的型号请自行查阅 Arch Wiki


# 如果以上驱动安装后都不能正常工作，您也许需要使用 nvidia-open-beta（AUR）以获得更新版本的驱动
yay -S nvidia-open-beta nvidia-utils lib32-nvidia-utils
```



**NVIDIA 驱动 - 加载**

- **⚠️ 注意：** 在安装了 [Intel CPU 11 代或更新版本的处理器](https://www.intel.com/content/www/us/en/newsroom/opinion/intel-cet-answers-call-protect-common-malware-threats.html)以及Linux 5.18 (或更高版本)的系统上可能无法正常工作，原因是与其与 [Indirect Branch Tracking](https://edc.intel.com/content/www/us/en/design/ipla/software-development-platforms/client/platforms/alder-lake-desktop/12th-generation-intel-core-processors-datasheet-volume-1-of-2/007/indirect-branch-tracking/) 这个安全功能不兼容。您可以在 [Arch_的启动流程](https://wiki.archlinuxcn.org/wiki/Arch_的启动流程)中设置 `ibt=off` [内核参数](https://wiki.archlinuxcn.org/wiki/内核参数)来禁用它。请注意，这项安全功能负责[缓解一些攻击技术的影响](https://lwn.net/Articles/889475/)。

```shell
# 如果你使用 GRUB ，可编辑 `/etc/default/grub` 文件
sudo vim /etc/default/grub


# 在 `GRUB_CMDLINE_LINUX_DEFAULT=""` 行中的引号内，添加 `ibt=off` 参数（无需是第一个参数）
	# 例如原本该行为：
	GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
	# 修改后为：
	GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet ibt=off"


# 然后重新生成 grub.cfg 文件
sudo grub-mkconfig -o /boot/grub/grub.cfg

	# 或安装 aur 仓库中的 `update-grub` 包
	yay -S update-grub
	sudo update-grub


# 如果你使用其它引导加载器，请自行阅读 Arch Wiki
```



- **⚠️ 注意：** 如果您使用 Wayland ，需启用 DRM
  
  - 由于 NVIDIA 不支持[自动 KMS 延迟加载](https://wiki.archlinux.org/title/Kernel_mode_setting#Late_KMS_start)，因此需要启用 DRM（[直接渲染管理器](https://en.wikipedia.org/wiki/Direct_Rendering_Manager)）[内核模式设置](https://wiki.archlinux.org/title/Kernel_mode_setting)才能使 Wayland 合成器正常运行，或者允许[Xorg#Rootless Xorg](https://wiki.archlinux.org/title/Xorg#Rootless_Xorg)。
  
  - 从[nvidia-utils](https://archlinux.org/packages/?name=nvidia-utils) 560.35.03-5 开始，DRM 默认处于启用状态。[[1\]](https://gitlab.archlinux.org/archlinux/packaging/packages/nvidia-utils/-/commit/1b02daa2ccca6a69fa4355fb5a369c2115ec3e22)对于较旧的驱动程序，请设置模块`nvidia_drm`的`modeset=1` [内核模块参数](https://wiki.archlinux.org/title/Kernel_module_parameter)。
  
  - 关于 Xwayland，请查看[Wayland#Xwayland](https://wiki.archlinux.org/title/Wayland#Xwayland)。要了解更多配置选项，请查看相应[合成器](https://wiki.archlinux.org/title/Wayland#Compositors)的 wiki 页面或文档。

```shell
# 启用 DRM 内核模块参数
sudo vim /etc/modprobe.d/nvidia.conf
	# 添加如下内容：
	options nvidia-drm modeset=1
# 重新生成 initramfs
sudo mkinitcpio -P
# 重启系统
reboot


# 要验证 DRM 是否真正启用
cat /sys/module/nvidia_drm/parameters/modeset
	# 如果启用应该返回 Y 而不是 N
```



- **⚠️ 注意：** 要在 GDM 中让 Wayland 与 NVIDIA 驱动程序一起使用，您必须满足以下三个条件：

  请参阅[GDM#Wayland 和专有 NVIDIA 驱动程序](https://wiki.archlinux.org/title/GDM#Wayland_and_the_proprietary_NVIDIA_driver)。

  

  - 启用[DRM KMS](https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting) （参考上一小节）
  
  
  
  - [配置 Wayland](https://wiki.archlinux.org/title/Wayland#Requirements) 
  
  ```shell
  # 确认是否已经使用 GBM 作为后端（一般会默认启用）
  journalctl -b 0 --grep "renderer for"
  
  
  # 若 `未启用` ，可添加以下环境变量来强制启用
  GBM_BACKEND=nvidia-drm
  __GLX_VENDOR_LIBRARY_NAME=nvidia
  ```
  
  
  
  - 按照[NVIDIA/提示和技巧#暂停后保留视频内存](https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Preserve_video_memory_after_suspend)
  
  ```shell
  # 检查 `nvidia` 的内核模块参数 `NVreg_PreserveVideoMemoryAllocations=1` 是否启用
  cat /proc/driver/nvidia/params | sort
  	# Arch Linux 一般为支持的设备默认启用，输出中应该包含以下内容：
  	PreserveVideoMemoryAllocations: 1
  	TemporaryFilePath: "/var/tmp"
  
  
  # 若未启用，可手动启用相应内核模块
  sudo vim /etc/modprobe.d/nvidia.conf
  	# 添加如下内容：
  	options nvidia NVreg_PreserveVideoMemoryAllocations=1
  # 重新生成 initramfs
  sudo mkinitcpio -P
  # 重启系统
  reboot
  ```
