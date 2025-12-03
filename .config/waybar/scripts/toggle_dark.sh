#!/bin/bash

# 状态功能：获取当前主题并输出 JSON 格式的状态信息
get_status_json() {
    CURRENT_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme)
    if [ "$CURRENT_SCHEME" = "'prefer-dark'" ]; then
        # 当前是暗色
        ICON="🌙"
        TOOLTIP="Click to switch to Light Theme"
    else
        # 当前是亮色
        ICON="☀️"
        TOOLTIP="Click to switch to Dark Theme"
    fi

    # 输出 Waybar 要求的 JSON 格式
    echo "{\"text\": \"$ICON\", \"tooltip\": \"$TOOLTIP\"}"
}

# 核心功能：切换主题并发送通知
toggle_theme_and_notify() {
    CURRENT_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme)
    
    if [ "$CURRENT_SCHEME" = "'prefer-dark'" ]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        THEME_NAME="Light"
        ICON="☀️"
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        THEME_NAME="Dark"
        ICON="🌙"
    fi
    
    # 检查 Waybar 是否在运行，如果找到进程，则发送信号
    if pgrep -x waybar > /dev/null; then
        pkill -RTMIN+8 waybar
    fi

    # 发送桌面通知
    notify-send -t 3000 "$ICON Theme Switched" "Current theme is set to $THEME_NAME."
}


# 主执行逻辑：根据传入的参数决定做什么

case "$1" in
    # 1. Waybar exec 调用：只获取状态 (JSON)
    status)
        get_status_json
        ;;

    # 2. Waybar on-click 或手动终端执行
    toggle)
        toggle_theme_and_notify
        ;;

    # 3. 默认模式：视为 'toggle' (手动终端执行)
    *)
        toggle_theme_and_notify
        ;;
esac
