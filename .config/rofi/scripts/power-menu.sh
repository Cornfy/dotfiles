#!/bin/bash

killall -SIGTERM rofi &> /dev/null

# =================================================================
# ROFI POWER MENU - BASH VERSION WITH ARRAY
# =================================================================

# -----------------------------------------------------
# Configuration
# -----------------------------------------------------
# 在这里修改菜单的标题和选项。

# Rofi 菜单的标题
PROMPT="Power Menu: "

# 菜单选项，使用 Bash 数组
# 格式: "<图标> <显示文本>:<内部关键词>"
declare -a OPTIONS=(
  "⏻ 关机 | Power Off:shutdown"
  " 重启 | Restart:reboot"
  " 锁屏 | Lock:lock"
  "󰒲 挂起 | Suspend (to RAM):suspend"
  "󰗼 注销 | Logout:logout"

  # 如果你需要休眠功能，建议参阅 Arch Wiki 获取帮助
  # "󰤄 休眠 | Hibernate (to Disk):hibernate"

  # 你可以轻松地在这里添加或删除行
  # 可自行调整 ~/.config/rofi/themes/power-menu.rasi 中的高度与宽度
)

# 锁屏命令
# 我使用 swaylock ，如果你使用其他工具，请修改此处
LOCK_CMD="swaylock"

# -----------------------------------------------------
# DO NOT EDIT BEYOND THIS LINE
# -----------------------------------------------------

# "引擎"部分：解析配置并显示菜单
# 使用 printf 将数组的每个元素打印到新的一行，然后传递给 Rofi
chosen_display=$(printf '%s\n' "${OPTIONS[@]}" | cut -d':' -f1 | rofi -dmenu -i -p "$PROMPT" -theme ~/.config/rofi/themes/power-menu.rasi)

# 如果用户按 Esc 退出了，则不做任何事
if [ -z "$chosen_display" ]; then
    exit 0
fi

# 根据用户选择的显示文本，从原始配置中找出对应的内部关键词
chosen_key=$(printf '%s\n' "${OPTIONS[@]}" | grep "^$chosen_display" | cut -d':' -f2)

# 根据找出的关键词执行命令
case "$chosen_key" in
    "shutdown")
        systemctl poweroff
        ;;
    "reboot")
        systemctl reboot
        ;;
    "lock")
        $LOCK_CMD
        ;;
    "suspend")
        systemctl suspend
        ;;
    "hibernate")
        systemctl hibernate
        ;;
    "logout")
        case "$XDG_CURRENT_DESKTOP" in
            Hyprland)
                hyprctl dispatch exit
                ;;
            sway)
                swaymsg exit
                ;;
            *)
                if command -v loginctl >/dev/null 2>&1; then
                    loginctl terminate-session "$XDG_SESSION_ID"
                fi
                ;;
        esac
        ;;
esac
