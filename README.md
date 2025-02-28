# dotfiles
- 该项目用于备份我的 Arch Linux 的常用配置文件。
- 主要用于 Wayland 环境。

#### .profile 文件
- 该文件为环境变量，可将该文件放在 `$HOME` 目录下。

#### .config 文件夹
- 此文件夹对应 `$HOME/.config` 文件夹，内含各软件的配置文件。

#### .local 文件夹
- 此文件夹对应 `$HOME/.local` 文件夹，内含我自定义的 `.desktop` 文件。

#### 一点 pacman 小技巧
- 如果一个包已经被作为依赖安装，你可以用以下命令将其转为手动安装
```shell
sudo pacman -D --asexplicit <package_name>
```

- 如果一个包被手动安装，你可以用以下命令将其视为作为依赖安装
```shell
sudo pacman -D --asdeps <package_name>
```

#### 个人的 hyprland 配置所需的依赖包

```txt
# 基础包
base				# Arch 基础包组
base-devel			# Arch 开发工具包组
linux				# Linux 内核
linux-firmware			# Linux 固件
amd-ucode / intel-ucode		# intel / amd 微码
grub				# 引导加载程序
efibootmgr			# UEFI 引导管理
os-prober			# 用于检测多系统引导
dhcpcd				# 动态分配 IP 地址
iwd				# tty 网络连接工具
archinstall			# Arch 安装脚本（提供很多便捷工具）
update-grub			# 便捷更新 grub 配置
vi / vim / nano / micro		# tty 文本编辑器
sudo				# 提权工具

# 一些基础工具（可选安装）
neovetch			# 显示系统信息
neovim				# 文本编辑器
fish				# 带输入预测的终端
tree				# 显示目录树状图
ffmpeg				# 音视频处理
git				# 项目版本管理
wget				# 下载工具
perl-image-exiftool		# 图片 EXIF 工具
ufw				# 防火墙
terminus-font			# 提供 tty 下最大的 ter-132b 字体
yay				# aur 助手

# 文件管理
Yazi				# 终端文件管理器
├── file			# 用于文件类型检测
├── ttf-noto-nerd		# 图标字体
├── ffmpeg			# 用于视频缩略图
├── ueberzugpp			# 图片预览
├── 7zip			# 用于档案提取和预览
├── jq				# 用于 JSON 预览
├── poppler			# PDF 预览
├── fd				# 用于文件搜索
├── ripgrep			# 用于文件内容搜索
├── fzf				# 用于快速文件子树导航
├── zoxide			# 用于历史目录导航
├── imagemagick			# 用于 SVG、字体、HEIC 和 JPEG XL 预览
└── wl-clipboard		# 用于系统剪贴板支持

# 图形界面
wayland				# 显示管理器
xorg-xwayland			# xorg 兼容
ttf-noto-sans-mono-vf		# 英文等宽字体（动态字重）	
ttf-noto-sans-mono-cjk-vf	# 中文等宽字体（动态字重）
noto-fonts-emoji		# emoji 表情字体
fcitx5-im			# 输入法框架（包组）
├── fcitx5-chinese-addons	# 中文输入法
└── fcitx5-pinyin-moegirl	# 萌娘百科词库
xdg-desktop-portal		# D-Bus 接口（桌面集成功能：文件选择、屏幕共享、通知系统、设置管理、URI 处理等）
└── xdg-desktop-portal-wlr	# D-Bus 接口的 wlroots 桌面（如 Hyprland、Wayfire 等）后端实现
hyprland			# 窗口管理器
├── alacritty			# 终端模拟器
├── waybar			# 状态栏
│	├── rofi-wayland	# 程序启动器
│	├── htop		# 查看运行的程序
│	├── networkmanager	# 网络管理器
│	├── blueberry		# 蓝牙管理器
│	├── brightnessctl	# 亮度控制
│	├── pipewire		# 音视频处理框架
│	├── pipewire-pulse	# 音频管理
│	├── pavucontrol		# 音量控制
│	└── wlogout		# 退出登陆
├── swaybg			# 壁纸
├── swaylock			# 锁屏
├── mako			# 通知显示工具
├── grim			# 截图
├── slurp			# 截图时选择区域
├── wf-recorder			# 录屏（可选安装）
├── mpc				# 音频播放框架（可选安装）
├── mpd				# 终端控制的音频播放器（可选安装）
├── mpv				# 视频播放器（可选安装）
├── nautilus			# Gnome 文件管理器（可选安装）
├── loupe			# Gnome 图片查看器（可选安装）
└── google-chrome		# Chrome 网络管理器（可选安装）

# 功能补强
eza				# 一个高级版的 ls
android-sdk-platform-tools	# Android adb 工具（adb、fastboot）
ntfs-3g				# 提供挂载和读写 NTFS 分区的能力（NTFS 为 Windows 分区）
gvfs-mtp			# 提供自动挂载 U 盘、MTP 设备的能力
```
