# Arch Linux 驱动安装

建议**「优先」**参照 Arch Wiki 从[这里](https://wiki.archlinux.org/title/Xorg#Driver_installation)自行选择适用的驱动程序软件包，**「其次」**再参考本教程。



## Intle 显卡驱动

摘抄自 [Arch Wiki - Intel_graphics](https://wiki.archlinux.org/title/Intel_graphics) ，建议自行阅读。



#### Intel 显卡驱动 - 安装

- **操作步骤**

```shell
编辑 `/etc/pacman.conf` 文件，启用 multilib 存储库
sudo vim /etc/pacman.conf
	# 取消以下两行的注释：
	[multilib]
	Include = /etc/pacman.d/mirrorlist


更新存储库
sudo pacman -Syy


安装 Intel 驱动程序
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

解释：
    直接渲染基础架构（ DRI ）是现代 Linux 图形堆栈的组成框架，允许非特权用户空间程序向图形硬件发出命令，而不会与其他程序冲突。DRI 的主要用途是为 OpenGL 的 Mesa 实现提供硬件加速。DRI 还被改编为在未运行显示服务器的情况下在帧缓冲控制台上提供 OpenGL 加速。
```



- **Xorg 中提供 2D 加速的 DDX 驱动程序：**

```txt
对于 DDX 支持，安装以下软件包：

- xorg-server			Intel 第 4 代及以上
- xf86-video-intel		Intel 第 2 ~ 9 代

解释：
    设备相关 X（DDX） 是 x-server 与硬件交互的部分。在 X.Org Server 源代码中，“hw” 下的每个目录都对应一个 DDX 。硬件包括显卡以及鼠标和键盘。每个驱动程序都是特定于硬件的，并作为单独的可加载模块实现。
```



- **提供 Vulkan 支持:**

```txt
对于 Vulkan 支持，安装以下软件包：

- vulkan-intel
- lib32-vulkan-intel    32 位程序支持，需启用 multilib 存储库

解释：
    Vulkan 是一个低开销、跨平台的二维、三维图形与计算的应用程序接口（API），最早由科纳斯组织在2015年游戏开发者大会（GDC）上发表。与 OpenGL 类似，Vulkan 针对全平台即时 3D 图形程序（如电子游戏和交互媒体）而设计，并提供高性能与更均衡的 CPU 与 GPU 占用，这也是 Direct3D 12 和 AMD 的 Mantle 的目标。与 Direct3D（12 版之前）和 OpenGL 的其他主要区别是，Vulkan 是一个底层 API ，而且能执行并行任务。除此之外，Vulkan 还能更好地分配多个 CPU 核心的使用。
```



#### Intel 显卡驱动 - 加载

- **1、Intel 内核模块会在系统引导时「自动加载」**

```txt
若未自动加载：

    由于 Intel 需要内核模式设置，确保您没有在内核参数中添加 nomodeset 。
    请同时确认您没有在 /etc/modprobe.d/ 或 /usr/lib/modprobe.d/ 中把 Intel 列入 modprobe 的黑名单导致禁用了 Intel 。
```



- **2、启用 GuC / HuC 固件加载（第 9 代以上）**

```shell
安装 `linux-firmware` 和 `intel-media-driver` 软件包，来启用硬件视频加速
sudo pacman -S linux-firmware intel-media-driver


编辑 `/etc/modprobe.d/i915.conf` ，配置 i915.enable_guc 内核参数
sudo vim /etc/modprobe.d/i915.conf
	# 文件在其中添加如下内容：
	options i915 enable_guc=3


重新生成 initramfs
sudo mkinitcpio -P
```



- **3、用查看是否启用**

```shell
执行 `dmesg` 命令
dmesg
	# 看到类似这样的输出说明启用成功
	[30130.586970] i915 0000:00:02.0: [drm] GuC firmware i915/icl_guc_33.0.0.bin version 33.0 submission:disabled
	[30130.586973] i915 0000:00:02.0: [drm] HuC firmware i915/icl_huc_9.0.0.bin version 9.0 authenticated:yes

或者直接查看相应文件
cat /sys/kernel/debug/dri/0/gt/uc/guc_info
cat /sys/kernel/debug/dri/0/gt/uc/huc_info
```





## AMD显卡驱动

摘抄自 [Arch Wiki - AMDGPU](https://wiki.archlinux.org/title/AMDGPU) ，建议自行阅读。



#### AMD 显卡驱动 - 安装

- **操作步骤**

```shell
编辑 `/etc/pacman.conf` 文件，启用 multilib 存储库
sudo vim /etc/pacman.conf
	# 取消以下两行的注释：
	[multilib]
	Include = /etc/pacman.d/mirrorlist


更新存储库
sudo pacman -Syy


安装 Intel 驱动程序
sudo pacman -S mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon
	# 建议参考后面的详细说明来确定软件包
```



- **提供用于 3D 加速的 DRI 驱动程序：**

```txt
对于 DRI 支持，安装以下软件包：

- mesa
- lib32-mesa			32 位程序支持，需启用 multilib 存储库

解释：
    直接渲染基础架构（ DRI ）是现代 Linux 图形堆栈的组成框架，允许非特权用户空间程序向图形硬件发出命令，而不会与其他程序冲突。DRI 的主要用途是为 OpenGL 的 Mesa 实现提供硬件加速。DRI 还被改编为在未运行显示服务器的情况下在帧缓冲控制台上提供 OpenGL 加速。
```



- **Xorg 中提供 2D 加速的 DDX 驱动程序：**

```txt
对于 DDX 支持，安装以下软件包：

- xf86-video-amdgpu

解释：
    设备相关 X（DDX） 是 x-server 与硬件交互的部分。在 X.Org Server 源代码中，“hw” 下的每个目录都对应一个 DDX 。硬件包括显卡以及鼠标和键盘。每个驱动程序都是特定于硬件的，并作为单独的可加载模块实现。
```



- **提供 Vulkan 支持:**

```txt
对于 Vulkan 支持，首先尝试「仅」安装以下软件包：
- vulkan-radeon
- lib32-vulkan-radeon	32 位程序支持，需启用 multilib 存储库


遇到问题才尝试「额外」安装以下软件包：
- amdvlk				
- lib32-amdvlk			32 位程序支持，需启用 multilib 存储库


解释：
    Vulkan 是一个低开销、跨平台的二维、三维图形与计算的应用程序接口（API），最早由科纳斯组织在2015年游戏开发者大会（GDC）上发表。与 OpenGL 类似，Vulkan 针对全平台即时 3D 图形程序（如电子游戏和交互媒体）而设计，并提供高性能与更均衡的 CPU 与 GPU 占用，这也是 Direct3D 12 和 AMD 的 Mantle 的目标。与 Direct3D（12 版之前）和 OpenGL 的其他主要区别是，Vulkan 是一个底层 API ，而且能执行并行任务。除此之外，Vulkan 还能更好地分配多个 CPU 核心的使用。
```

⚠️注意：`(lib32-)amdvlk` 会将自己设置为默认的 Vulkan 驱动程序，如果需要与 `(lib32-)vulkan-radeon` 同时工作，请参阅 Arch Wiki 上的 [Vulkan#Selecting via environment variable](httpS://wiki.archlinux.org/title/Vulkan#Vulkan#Selecting_via_environment_variable) 条目



#### AMD 显卡驱动 - 加载

⚠️ 优先检查是否加载，如果 `amdgpu` **未使用**，按照后续的说明进行操作。

```shell
执行 `lspci` 命令查看 AMD 显卡是否启用
lspci -k -d ::03xx

01:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Curacao PRO [Radeon R7 370 / R9 270/370 OEM]
	Subsystem: Gigabyte Technology Co., Ltd Device 226c
	Kernel driver in use: amdgpu
	Kernel modules: radeon, amdgpu
```



- **启用 Southern Islands（SI）和 Sea Islands （CIK）支持**

  - ⚠️ 指定正确的模块顺序：
    确保 amdgpu 已设置为 [Mkinitcpio#MODULES](https://wiki.archlinux.org/title/Mkinitcpio#MODULES) 数组中的第一个模块，例如 `MODULES=(amdgpu radeon)` 。
  - 置模块参数

  ```shell
  编辑 `/etc/modprobe.d/amdgpu.conf` 文件
  sudo vim /etc/modprobe.d/amdgpu.conf
  	# 添加如下内容：
  	options amdgpu si_support=1
  	options amdgpu si_support=1
  
  编辑`/etc/modprobe.d/radeon.conf` 文件
  sudo vim /etc/modprobe.d/radeon.conf
  	# 添加如下内容：
  	options radeon si_support=0
  	options radeon si_support=0
  ```

  - 确保 `modconf` 在 `/etc/mkinitcpio.conf` 的  `HOOKS` 阵列中，并[重新生成 initramfs](https://wiki.archlinux.org/title/Regenerate_the_initramfs)。

  ```shell
  重新生成 initramfs
  sudo mkinitcpio -P
  ```





## NVIDIA 驱动

摘抄自 [Arch Wiki - NVIDIA](https://wiki.archlinux.org/title/NVIDIA) ，建议自行阅读。

**⚠️ 注意：**如果您适用 Wayland ， 建议在安装和配置 NVIDIA 驱动前，重建系统快照以便恢复。



- **NVIDIA 驱动 - 安装**

```shell
# NV160（RTX 2060）及以上
sudo pacman -S nvidia-open-dkms nvidia-utils lib32-nvidia-utils

# NV110（GTX 900） ~ NV190（RTX 3080）
# 即：
	# GTX 900
	# GTX 10 系列
	# RTX 20 系列
	# RTX 30 系列
sudo pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils

# 更旧的型号请自行查阅 Arch Wiki

# 如果以上驱动安装后都不能正常工作，您也许需要使用 nvidia-open-beta（AUR）以获得更新版本的驱动
yay -S nvidia-open-beta nvidia-utils lib32-nvidia-utils
```



**NVIDIA 驱动 - 加载**

- **⚠️ 注意：**在安装了 [Intel CPU 11 代或更新版本的处理器](https://www.intel.com/content/www/us/en/newsroom/opinion/intel-cet-answers-call-protect-common-malware-threats.html)以及Linux 5.18 (或更高版本)的系统上可能无法正常工作，原因是与其与 [Indirect Branch Tracking](https://edc.intel.com/content/www/us/en/design/ipla/software-development-platforms/client/platforms/alder-lake-desktop/12th-generation-intel-core-processors-datasheet-volume-1-of-2/007/indirect-branch-tracking/) 这个安全功能不兼容。您可以在 [Arch_的启动流程](https://wiki.archlinuxcn.org/wiki/Arch_的启动流程)中设置 `ibt=off` [内核参数](https://wiki.archlinuxcn.org/wiki/内核参数)来禁用它。请注意，这项安全功能负责[缓解一些攻击技术的影响](https://lwn.net/Articles/889475/)。



- **⚠️ 注意：** DRM 内核模式设置
  - 由于 NVIDIA 不支持[自动 KMS 延迟加载](https://wiki.archlinux.org/title/Kernel_mode_setting#Late_KMS_start)，因此需要启用 DRM（[直接渲染管理器](https://en.wikipedia.org/wiki/Direct_Rendering_Manager)）[内核模式设置](https://wiki.archlinux.org/title/Kernel_mode_setting)才能使 Wayland 合成器正常运行，或者允许[Xorg#Rootless Xorg](https://wiki.archlinux.org/title/Xorg#Rootless_Xorg)。
  - 从[nvidia-utils](https://archlinux.org/packages/?name=nvidia-utils) 560.35.03-5 开始，DRM 默认处于启用状态。[[1\]](https://gitlab.archlinux.org/archlinux/packaging/packages/nvidia-utils/-/commit/1b02daa2ccca6a69fa4355fb5a369c2115ec3e22)对于较旧的驱动程序，请设置模块`nvidia_drm`的`modeset=1` [内核模块参数](https://wiki.archlinux.org/title/Kernel_module_parameter)。
  - 关于 Xwayland，请查看[Wayland#Xwayland](https://wiki.archlinux.org/title/Wayland#Xwayland)。要了解更多配置选项，请查看相应[合成器](https://wiki.archlinux.org/title/Wayland#Compositors)的 wiki 页面或文档。
  - 如果您使用 GDM，还请参阅[GDM#Wayland 和专有 NVIDIA 驱动程序](https://wiki.archlinux.org/title/GDM#Wayland_and_the_proprietary_NVIDIA_driver)。

```shell
# 启用 DRM
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

