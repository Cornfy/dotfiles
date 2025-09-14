#!/bin/bash

# --- 使用绝对路径 ---
MPC_CMD="/usr/bin/mpc"

# --- JSON 转义函数 (保持不变) ---
json_escape() {
    local input="$1"
    local escaped="${input//\\/\\\\}"
    escaped="${escaped//\"/\\\"}"
    escaped="${escaped//$'\n'/\\n}"
    echo -n "$escaped"
}

# 1. 检查 MPD 状态并获取状态
if ! status_output=$($MPC_CMD status 2>/dev/null); then
    player_status="unavailable"
else
    player_status=$(echo "$status_output" | awk 'NR==2 {print $1}' | tr -d '[]')
fi

# 2. 如果状态是 stopped, unavailable 或空，则显示占位符
if [[ "$player_status" == "stopped" || "$player_status" == "unavailable" || -z "$player_status" ]]; then
    text=" MPD"
    tooltip="MPD is stopped or unavailable"
    class="stopped"
    printf '{"text":"%s", "tooltip":"%s", "class":"%s"}\n' \
        "$(json_escape "$text")" "$(json_escape "$tooltip")" "$(json_escape "$class")"
    exit 0
fi

# 3. 设置图标和 CSS Class
if [[ "$player_status" == "playing" ]]; then
    icon=""
    class="playing"
else # Paused
    icon=""
    class="paused"
fi

# ================================================================
#                       核心修改部分
# ================================================================

# 4. 准备 Bar 上显示的 'text'
#    - 使用 iconv 净化 mpc 输出，丢弃无效字符
#    - 使用 ${var:0:30} 进行字符安全的截断
song_title=$($MPC_CMD -f "%title%" current 2>/dev/null | iconv -f UTF-8 -t UTF-8 -c)
text="$icon ${song_title:0:30}"

# 5. 准备悬停提示的 'tooltip' (同样进行净化)
full_song_info=$($MPC_CMD -f "%artist% - %title%" current 2>/dev/null | iconv -f UTF-8 -t UTF-8 -c)
progress=$(echo "$status_output" | awk 'NR==2 {print $3, $4}')
volume=$(echo "$status_output" | awk -F'volume:' 'NR==3 {print $2}' | awk '{print $1}')
tooltip=$(printf "🎵 %s\n\n %s\n %s" \
    "$full_song_info" \
    "$progress" \
    "$volume")

# ================================================================

# 6. 构建并输出最终 JSON
text_escaped=$(json_escape "$text")
tooltip_escaped=$(json_escape "$tooltip")
class_escaped=$(json_escape "$class")

printf '{"text":"%s", "tooltip":"%s", "class":"%s"}\n' \
    "$text_escaped" \
    "$tooltip_escaped" \
    "$class_escaped"
