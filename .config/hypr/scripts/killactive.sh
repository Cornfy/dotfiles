#!/bin/bash

# 获取当前活动窗口的地址和PID
ACTIVE_WINDOW_INFO="$(hyprctl activewindow)"
ADDRESS=$(echo "$ACTIVE_WINDOW_INFO" | head -n 1 | awk '{print $2}')
PID=$(echo "$ACTIVE_WINDOW_INFO" | grep 'pid:' | awk '{print $2}')

# 尝试正常关闭窗口
hyprctl dispatch killactive

# 等待窗口关闭检测
sleep 0.3

# 检查原窗口是否仍然存在
WINDOW_STILL_EXISTS=$(hyprctl clients | grep "$ADDRESS")

if [ -n "$WINDOW_STILL_EXISTS" ]; then
  # 精准终止原窗口所属进程（不误杀其他窗口）
  kill -9 $PID
fi
