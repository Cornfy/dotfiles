#!/bin/bash

basepath="$HOME/Videos/Recording"
output="$basepath/VID_$(date '+%Y%m%d_%H%M%S').mkv"

mkdir -p  $basepath

# 如果没有 notify-send 命令，请安装 libnotify 包
if pidof wf-recorder > /dev/null; then
	pkill wf-recorder
else
	notify-send "屏幕录制开始..."
	wf-recorder -f "$output" \
		--codec libx265 \
		--pixel-format yuv420p \
		--codec-param b=8000k \
		--audio \
		--audio-codec aac \
		--sample-rate 48000 \
		--audio-codec-param b=128k \
		&> /dev/null
	if [ $? -eq 0 ]; then
		notify-send "屏幕录制完成" "保存路径：$output"
	else
		notify-send "⚠️ 屏幕录制失败，请检查录制脚本！！" "$0"
	fi
fi

# 参数解释
# --codec libx265		# 视频编码格式	H.265
# --pixel-format yuv420p	# 视频色彩空间	YUV420
# --codec-param b=8000k		# 视频比特率	8 Mbps
# --audio			# 音频录制
# --audio-codec aac		# 音频编码格式	aac
# --sample-rate 48000		# 音频采样率	48 kHz
# --audio-codec-param b=128k	# 音频比特率	128 kbps

