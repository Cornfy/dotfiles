#!/bin/bash

basepath="$HOME/Videos/Recording"
output="$basepath/VID_$(date '+%Y%m%d_%H%M%S_%3N').mp4"

mkdir -p "$basepath"
command -v gpu-screen-recorder >/dev/null || { echo "错误：gpu-screen-recorder 未找到。请安装 gpu-screen-recorder 包。" >&2; exit 1; }
command -v notify-send >/dev/null || { echo "错误：notify-send 未找到。请安装 libnotify 包。" >&2; exit 1; }

hevc_recorder() {
	# 参数 $1 代表编码器类型：传入 "gpu" 使用显卡硬件，传入 "cpu" 使用处理器软件编码
	local mode=$1 

	if pgrep -f "gpu-screen-recorder" > /dev/null; then
		# 提取当前正在录制的文件名，用于通知显示
		local recording_path=$(ps aux | grep "[g]pu-screen-recorder" | awk -F '-o ' '{print $2}' | awk '{print $1}')
		# 使用 SIGINT 信号停止，这是录制 MP4 必须的，否则视频头信息无法闭合导致无法播放
		pkill -SIGINT -f gpu-screen-recorder
		notify-send "✅ [GSR-$mode] 屏幕录制完成" "视频已保存到：\n$recording_path"
	else
		notify-send "🎥 [GSR-$mode] 屏幕录制开始..."
		# ----------------------------------------------------------------------
		# gpu-screen-recorder 参数详细说明：
		# ----------------------------------------------------------------------
		# -w screen		# 录制范围：全屏
		# -f 60			# 帧率：60 FPS
		# -encoder "$mode"	# 编码器：gpu 或 cpu
		# -k hevc		# 视频编码格式：使用 H.265 (HEVC)，高压缩比高清晰度
		# -q very_high		# 预设质量：很高 (在比特率限制内尽可能压榨画质)
		# -a "default_output"	# 音频设备：自动捕获 PipeWire 默认输出流 (内置音频)
		# -ac aac		# 音频编码格式：AAC (兼容性最好)
		# -ab 128k		# 音频比特率：128 kbps
		# -o "$output"		# 输出文件名
		# ----------------------------------------------------------------------
		gpu-screen-recorder \
			-w screen \
			-f 60 \
			-encoder "$mode" \
			-k hevc \
			-q very_high \
			-a "default_output" \
			-ac aac \
			-ab 128k \
			-o "$output" \
			&> /dev/null &
		sleep 1
		if ! pgrep -f "gpu-screen-recorder" > /dev/null ; then
			notify-send "⚠️ 启动失败！" "可能的错误：显卡驱动不支持 HEVC、PipeWire 挂起或路径无写入权限。"
		fi
	fi
}

# 推荐：硬件加速录制
hevc_recorder "gpu"

# 备选：软件录制 (仅当硬件加速不可用时，取消下面注释并注释掉上面的 gpu 行)
# hevc_recorder "cpu"
