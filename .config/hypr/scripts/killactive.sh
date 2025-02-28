#!/bin/bash

# 定义日志文件
LOG="${HOME}/hypr_killactive.log"
touch "$LOG"

# 获取当前活动窗口的地址和PID
ACTIVE_WINDOW_INFO="$(hyprctl activewindow)"
ADDRESS=$(echo "$ACTIVE_WINDOW_INFO" | head -n 1 | awk '{print $2}')
PID=$(echo "$ACTIVE_WINDOW_INFO" | grep 'pid:' | awk '{print $2}')

echo "ADDRESS: $ADDRESS" > "$LOG"
echo "PID    : $PID" >> "$LOG"

# 尝试正常关闭窗口
hyprctl dispatch killactive

# 等待窗口关闭检测
sleep 0.3

# 检查原窗口是否仍然存在
WINDOW_STILL_EXISTS=$(hyprctl clients | grep "$ADDRESS")

echo "WINDOW_STILL_EXISTS: $WINDOW_STILL_EXISTS" >> "$LOG"

if [ -n "$WINDOW_STILL_EXISTS" ]; then
  # 精准终止原窗口所属进程（不误杀其他窗口）
  kill -9 $PID
  echo "强制关闭窗口 PID: $PID" >> "$LOG"
else
  echo "窗口已正常关闭" >> "$LOG"
fi
