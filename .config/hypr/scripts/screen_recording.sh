#!/bin/bash

basepath="$HOME/Videos/Recording"
output="$basepath/VID_$(date '+%Y%m%d_%H%M%S').mp4"

mkdir -p  $basepath

# 如果没有 notify-send 命令，请安装 libnotify 包
if pidof wf-recorder > /dev/null; then
	pkill wf-recorder
	notify-send "录制完成" "保存路径：$output"
else
	notify-send "屏幕录制开始..."
	wf-recorder --codec libx265 -a @DEFAULT_MONITOR@ -f "$output" &> /dev/null
fi
