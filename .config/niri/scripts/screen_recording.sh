#!/bin/bash

basepath="$HOME/Videos/Recording"
output="$basepath/VID_$(date '+%Y%m%d_%H%M%S_%3N').mp4"

mkdir -p  $basepath

hardware_recorder() {
	# VA-API 设备，用于硬件加速
	VAAPI_DEVICE="/dev/dri/renderD128" 

	# 如果没有 notify-send 命令，请安装 libnotify 包
	if pgrep -x "wf-recorder" > /dev/null; then
		# 在杀掉进程前，先看一眼它的文件名参数
		# [w] 技巧是为了过滤掉 grep 进程本身
		local recording_path=$(ps aux | grep "[w]f-recorder" | awk -F '-f ' '{print $2}' | awk '{print $1}')
		pkill -SIGINT wf-recorder
		notify-send "✅ [vaapi_hevc] 屏幕录制完成" "视频已保存到：\n$recording_path"
	else
		notify-send "🎥 [vaapi_hevc] 屏幕录制开始..."
		# 参数解释
		# --device $VAAPI_DEVICE	# 指定 VA-API 设备
		# --codec hevc_vaapi		# 视频编码格式：硬件 HEVC
		# --codec-param qp="18"		# 恒定质量模式 (CQP)，QP 值越低质量越高（一般 18 ~ 28 ）。
		# --codec-param preset=speed	# 预设，速度优先
		# --audio			# 音频录制
		# --audio-backend=pipewire	# 指定 PipeWire 作为音频后端
		# --audio-codec aac		# 音频编码格式 aac
		# --sample-rate 48000		# 音频采样率 48 kHz
		# --audio-codec-param b=128k	# 音频比特率 128 kbps
		wf-recorder -f "$output" \
			--device "$VAAPI_DEVICE" \
			--codec hevc_vaapi \
			--codec-param qp="18" \
			--codec-param preset=speed \
			--audio \
			--audio-backend=pipewire \
			--audio-codec aac \
			--sample-rate 48000 \
			--audio-codec-param b=128k \
			&> /dev/null &		
		sleep 1
		if ! pgrep -x "wf-recorder" > /dev/null ; then
			notify-send "⚠️ 屏幕录制启动失败，请检查录制脚本和 VA-API 配置！！" "$0"
		fi
	fi
}

software_recorder() {
	# 如果没有 notify-send 命令，请安装 libnotify 包
	if pgrep -x "wf-recorder" > /dev/null; then
		# 在杀掉进程前，先看一眼它的文件名参数
		# [w] 技巧是为了过滤掉 grep 进程本身
		local recording_path=$(ps aux | grep "[w]f-recorder" | awk -F '-f ' '{print $2}' | awk '{print $1}')
		pkill -SIGINT wf-recorder
		notify-send "✅ [libx265] 屏幕录制完成" "视频已保存到：\n$recording_path"
	else
		notify-send "🎥 [libx265] 屏幕录制开始..."
		# 参数解释
		# --codec libx265		# 视频编码格式	H.265
		# --pixel-format yuv420p	# 视频色彩空间	YUV420
		# --codec-param b=16000k	# 视频比特率	16 Mbps
		# --audio			# 音频录制
		# --audio-backend=pipewire	# 指定 PipeWire 作为音频后端
		# --audio-codec aac		# 音频编码格式	aac
		# --sample-rate 48000		# 音频采样率	48 kHz
		# --audio-codec-param b=128k	# 音频比特率	128 kbps
		wf-recorder -f "$output" \
			--codec libx265 \
			--pixel-format yuv420p \
			--codec-param b=16000k \
			--audio \
			--audio-backend=pipewire \
			--audio-codec aac \
			--sample-rate 48000 \
			--audio-codec-param b=128k \
			&> /dev/null &
		sleep 1
		if ! pgrep -x "wf-recorder" > /dev/null ; then
			notify-send "⚠️ 屏幕录制启动失败，请检查录制脚本！！" "$0"
		fi
	fi
}


# 执行函数进行屏幕录制（二选一）
hardware_recorder	# 硬件加速
# software_recorder	# 软件回退
