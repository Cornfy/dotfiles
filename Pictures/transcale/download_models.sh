#!/usr/bin/env bash

# 解析脚本物理位置
readonly SCRIPT_DIR=$(dirname "$(realpath "$0")")
readonly TARGET_DIR="$SCRIPT_DIR/.pth_models"
readonly TMP_DIR="${TARGET_DIR}_tmp"

# 检测操作系统类型
OS_TYPE=$(uname -s)

# ============================================================
# 📦 通用资产配置矩阵 (本地文件名 与 远程镜像下载链接 物理绑定)
# ============================================================
declare -A MODEL_MAP=(
    # 1. 4x-Nomos8kDAT
    ["4x-Nomos8kDAT.pth"]="https://hf-mirror.com/vladmandic/sdnext-upscalers/resolve/main/DAT-4x.pth"
    
    # 2. 4x-AnimeSharp
    # 二次元线条锐化与渐变保留的平衡神作
    # 由经典插值演变而来，专门针对动漫边缘优化，既能让线条干净，又不易造成渐变色块断层
    ["4x-AnimeSharp.pth"]="https://hf-mirror.com/utnah/esrgan/resolve/main/4x-AnimeSharp.pth"
    
    # 3. 4x_fatal_Anime
    # 手绘/厚涂细节守护者，极力避免塑料抹平感
    # 二次元圈非常著名的模型，非常擅长去除画面杂质并还原纸纹、水彩笔触质感，不会产生工业级塑料涂抹感
    ["4x_fatal_Anime.pth"]="https://hf-mirror.com/uwg/upscaler/resolve/main/ESRGAN/4x_fatal_Anime_500000_G.pth"
    
    # 4. 4x-Swin2SR-Compressed
    # Swin2SR 官方去伪影/去低保真噪声模型
    # 专门针对经过重度 JPEG 压缩或者低清缩放的图像进行修复，可以有效清洗并修复画面中的块状网格或拉丝条纹
    ["4x-Swin2SR-Compressed.pth"]="https://hf-mirror.com/uwg/upscaler/resolve/main/SwinIR/Swin2SR_CompressedSR_X4_48.pth"
)

# ============================================================
# 🎨 极客统一色彩矩阵定义
# ============================================================
readonly CLR_RESET="\033[0m"
readonly CLR_BLUE="\033[1;34m"
readonly CLR_CYAN="\033[1;36m"
readonly CLR_GREEN="\033[1;32m"
readonly CLR_YELLOW="\033[1;33m"
readonly CLR_RED="\033[1;31m"
readonly CLR_MAGENTA="\033[1;35m"

# ============================================================
# 🛡️ 物理信号拦截器 (安全防线)
# ============================================================
cleanup_sh() {
    echo -e "\n\n${CLR_RED}🛑 [风险拦截] 检测到物理中断 (Ctrl+C)！正在紧急触发原子回滚...${CLR_RESET}"
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
        echo "🧹 影子隔离区已物理抹除，本地老文件完好无损。"
    fi
    exit 1
}
trap cleanup_sh SIGINT SIGTERM

# ============================================================
# ⚙️ 网络发动机检测
# ============================================================
ENGINE=""
if command -v wget &> /dev/null; then
    ENGINE="wget"
elif command -v curl &> /dev/null; then
    ENGINE="curl"
else
    echo -e "${CLR_RED}❌ 核心缺失: 未检测到 wget 或 curl 网络工具${CLR_RESET}"
    if [ "$OS_TYPE" = "Darwin" ]; then
        echo -e "${CLR_YELLOW}💡 提示: macOS 用户建议通过 Homebrew 安装:${CLR_RESET}"
        echo -e "    👉 brew install wget"
    else
        echo -e "${CLR_YELLOW}💡 提示: Linux 用户请执行以下命令安装:${CLR_RESET}"
        echo -e "    👉 sudo pacman -S wget curl"
    fi
    exit 1
fi

mkdir -p "$TARGET_DIR"

# ============================================================
# 🔍 预检清单 (Pre-flight Check)
# ============================================================
echo -e "${CLR_BLUE}🔍 正在检索本地资产，生成物理同步清单...${CLR_RESET}"
echo "---------------------------------------------------"

new_downloads=0
updates_checks=0
declare -a todo_list

for local_name in "${!MODEL_MAP[@]}"; do
    local_file="$TARGET_DIR/$local_name"
    
    if [ -f "$local_file" ]; then
        todo_list+=("${CLR_YELLOW}[时间戳校验]${CLR_RESET} 📦 $local_name (本地资产已存在)")
        ((updates_checks++))
    else
        todo_list+=("${CLR_GREEN}[全新拉取]${CLR_RESET} 📥 $local_name (${CLR_RED}约 60M~150MB${CLR_RESET})")
        ((new_downloads++))
    fi
done

for item in "${todo_list[@]}"; do
    echo -e "  $item"
done

echo "---------------------------------------------------"
echo -e "📊 资产分析: 物理全新拉取 ${CLR_GREEN}$new_downloads${CLR_RESET} 个，智能缓存校验 ${CLR_YELLOW}$updates_checks${CLR_RESET} 个。"
echo -e "🚀 调度发动机: ${CLR_MAGENTA}$ENGINE${CLR_RESET}"
echo "---------------------------------------------------"

# 🛑 核心交互确认
read -p "🔔 是否确认执行上述同步流? [Y/n] " -r choice
choice="${choice:-Y}"

if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    echo -e "\n${CLR_YELLOW}👋 [操作取消] 物理同步流已安全终止。${CLR_RESET}"
    exit 0
fi

echo -e "\n${CLR_GREEN}🚀 裁决通过！物理隔离沙盒启动...${CLR_RESET}\n"

# ============================================================
# 🚀 物理执行矩阵 (原子级安全)
# ============================================================
rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR"
total_models=${#MODEL_MAP[@]}
current=1

for local_name in "${!MODEL_MAP[@]}"; do
    remote_url="${MODEL_MAP[$local_name]}"
    local_file="$TARGET_DIR/$local_name"
    tmp_file="$TMP_DIR/$local_name"
    
    echo -e "▶️ [${CLR_MAGENTA}$current/$total_models${CLR_RESET}] 正在同步: ${CLR_CYAN}$local_name${CLR_RESET}"
    
    # 如果本地有老资产，先拷贝到沙盒中用于断点续传/时间戳对比
    if [ -f "$local_file" ]; then
        cp -p "$local_file" "$tmp_file"
    fi

    # 驱动下载引擎
    if [ "$ENGINE" = "wget" ]; then
        wget -c -N -q --show-progress -L "$remote_url" -O "$tmp_file"
        res_code=$?
    else
        curl -sL -C - "$remote_url" -o "$tmp_file" --progress-bar
        res_code=$?
    fi

    # 原子事务提交控制
    if [ $res_code -eq 0 ] && [ -s "$tmp_file" ]; then
        mv "$tmp_file" "$local_file"
        echo -e "    ${CLR_GREEN}✨ [事务提交]${CLR_RESET} 资产安全落地并闭环。\n"
    else
        rm -f "$tmp_file"
        echo -e "    ${CLR_YELLOW}🛡️ [回滚保护]${CLR_RESET} 远程资产未更新或网络中断，保持本地完好。\n"
    fi

    ((current++))
    echo "---------------------------------------------------"
done

rm -rf "$TMP_DIR"
echo -e "${CLR_GREEN}🎉 所有 Transformer 核心模型物理同步流完美闭环！${CLR_RESET}"
