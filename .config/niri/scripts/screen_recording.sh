#!/bin/bash

basepath="$HOME/Videos/Recording"
output="$basepath/VID_$(date '+%Y%m%d_%H%M%S_%3N').mp4"

mkdir -p  $basepath

# 如果没有 notify-send 命令，请安装 libnotify 包
if pgrep -x "wf-recorder" > /dev/null; then
	pkill -SIGINT wf-recorder
	notify-send "✅ 屏幕录制完成" "视频已保存到：$output"
else
	notify-send "🎥 屏幕录制开始..."
	wf-recorder -f "$output" \
		--codec libx265 \
		--pixel-format yuv420p \
		--codec-param b=16000k \
		--audio \
		--audio-codec aac \
		--sample-rate 48000 \
		--audio-codec-param b=128k \
		&> /dev/null &
	sleep 1
	if ! pgrep -x "wf-recorder" > /dev/null ; then
		notify-send "⚠️ 屏幕录制启动失败，请检查录制脚本！！" "$0"
	fi
fi

# 参数解释
# --codec libx265		# 视频编码格式	H.265
# --pixel-format yuv420p	# 视频色彩空间	YUV420
# --codec-param b=16000k	# 视频比特率	16 Mbps
# --audio			# 音频录制
# --audio-codec aac		# 音频编码格式	aac
# --sample-rate 48000		# 音频采样率	48 kHz
# --audio-codec-param b=128k	# 音频比特率	128 kbps

