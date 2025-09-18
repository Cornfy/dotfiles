#!/usr/bin/env bash

# ===== 脚本健壮性设置 =====
set -euo pipefail

# ===== 依赖检查 =====
command -v grim >/dev/null || { echo "错误：grim 未找到。" >&2; exit 1; }
command -v slurp >/dev/null || { echo "错误：slurp 未找到。" >&2; exit 1; }
command -v wl-copy >/dev/null || { echo "错误：wl-copy 未找到。" >&2; exit 1; }
command -v notify-send >/dev/null || { echo "错误：notify-send 未找到。请安装 libnotify。" >&2; exit 1; }
command -v hyprctl >/dev/null || { echo "错误：hyprctl 未找到。" >&2; exit 1; }
command -v jq >/dev/null || { echo "错误：jq 未找到。" >&2; exit 1; }


# ===== 配置 =====
basepath="$HOME/Pictures/ScreenShots"
mkdir -p "$basepath"

# --- 图标配置 (Emoji 或 Nerd Font 字符) ---
SUCCESS_ICON="📸"
FAILURE_ICON="❌"
CANCEL_ICON="🚫"

# ===== 功能函数 =====

# 发送通知
send_notification() {
  notify-send "$1" "$2"
}

# 捕获屏幕并处理
# 这个函数现在假定它总是会成功执行，因为取消的逻辑在它之外处理
capture_and_save() {
  local output_file="$basepath/IMG_$(date '+%Y%m%d_%H%M%S_%3N').png"
  
  if grim "$@" - | tee "$output_file" | wl-copy --type image/png; then
    send_notification "${SUCCESS_ICON} 截图成功" "图像已保存到剪贴板并存为:\n${output_file##*/}"
  else
    send_notification "${FAILURE_ICON} 截图失败" "无法使用 grim 捕获屏幕。"
  fi
}


# ===== 主逻辑 =====
mode="${1:-fullscreen}" # 默认为 fullscreen

case "$mode" in
  fullscreen)
    # 截取全屏
    capture_and_save
    ;;

  select)
    # 用户手动选择一个区域
    geometry=$(slurp -d -b 00000000 -c 00A3EF -w 2) || {
      send_notification "${CANCEL_ICON} 截图已取消" "用户取消了操作。"
      exit 0
    }
    capture_and_save -g "$geometry"
    ;;

  active)
    # 截取当前活动窗口
    geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    capture_and_save -g "$geometry"
    ;;

  *)
    send_notification "${FAILURE_ICON} 脚本错误" "未知的截图模式: '$mode'"
    exit 1
    ;;
esac
