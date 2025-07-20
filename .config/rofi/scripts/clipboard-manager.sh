#!/bin/bash

# =================================================================
# ROFI ADVANCED CLIPBOARD MANAGER (FINAL VERSION WITH SAFE KEYBINDS)
# =================================================================
#
# This version gives up on the problematic 'Delete' key and uses
# non-conflicting 'Alt' keybindings for robustness.
#
# This script depends on `wl-clipboard` and `cliphist` packages.
# 该脚本依赖 `wl-clipboard` 和 `cliphist` 包。

# -----------------------------------------------------
# Configuration Area
# -----------------------------------------------------
# 使用不会与 Rofi 默认功能冲突的 Alt 组合键。

# 删除单个条目的按键
KEY_DELETE="Alt+d"	# 'd' for 'delete'

# 清空所有历史的按键
KEY_CLEAR="Alt+c"	# 'c' for 'clear'

# -----------------------------------------------------
# Engine - Do not edit below
# -----------------------------------------------------

# 定义我们自己的自定义按键绑定
CUSTOM_BINDINGS="-kb-custom-1 ${KEY_DELETE} -kb-custom-2 ${KEY_CLEAR}"

# 主循环
while true; do
    # 启动 Rofi
    SELECTION=$(cliphist list | rofi -dmenu -i -p "Clipboard: " \
        -theme ~/.config/rofi/themes/clipboard-manager.rasi \
        -mesg "Enter: Paste | ${KEY_DELETE}: Remove | ${KEY_CLEAR}: Clear All" \
        ${CUSTOM_BINDINGS})
    ROFI_EXIT=$?

    case $ROFI_EXIT in
        0)  # Enter: 粘贴并退出
            echo "$SELECTION" | wl-copy
            break
            ;;
        1)  # Esc: 直接退出
            break
            ;;
        10) # Custom 1 (Alt+d): 删除单个条目
            echo "$SELECTION" | cliphist delete
            ;;
        11) # Custom 2 (Alt+c): 清空所有
            cliphist wipe
            ;;
        *)  # 安全网，防止死锁
            break
            ;;
    esac
done
