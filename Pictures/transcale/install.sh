#!/usr/bin/env bash
set -e

# 🎨 色彩矩阵定义
readonly CLR_RESET="\033[0m"
readonly CLR_CYAN="\033[1;36m"
readonly CLR_GREEN="\033[1;32m"
readonly CLR_YELLOW="\033[1;33m"
readonly CLR_RED="\033[1;31m"

# 检测操作系统与硬件架构
OS_TYPE=$(uname -s)
ARCH_TYPE=$(uname -m)

echo -e "${CLR_CYAN}=> [Pre-flight] 正在扫描基础构建依赖...${CLR_RESET}"
echo "---------------------------------------------------"

# 1. 核心依赖检查：现代 Python 包管理器 uv
if ! command -v uv &> /dev/null; then
    echo -e "${CLR_RED}❌ 核心缺失: 未在您的系统 PATH 中检测到 'uv'${CLR_RESET}"
    if [ "$OS_TYPE" = "Darwin" ]; then
        echo -e "${CLR_YELLOW}💡 提示: 作为 macOS 用户，您可以使用 Homebrew 快速安装:${CLR_RESET}"
        echo -e "    👉 brew install uv"
    else
        echo -e "${CLR_YELLOW}💡 提示: 作为 Linux 用户，请使用您的系统包管理器安装。例如在 Arch Linux 下:${CLR_RESET}"
        echo -e "    👉 sudo pacman -S uv"
    fi
    echo "---------------------------------------------------"
    exit 1
fi

echo -e "📦 基础管理器: ${CLR_GREEN}[uv] 已物理就绪${CLR_RESET}"

# 2. 初始化虚拟环境
echo -e "${CLR_CYAN}=> [uv] 正在沙盒中物理对齐 Python 3.10 运行时...${CLR_RESET}"
if [ ! -d ".venv" ]; then
    uv venv --python 3.10
else
    echo -e "    ℹ️ 检测到本地 .venv 物理空间已存在，跳过初始化。"
fi

# 3. 硬件感知分流与依赖部署
if [ "$OS_TYPE" = "Darwin" ]; then
    # macOS 运行环境适配
    if [ "$ARCH_TYPE" = "arm64" ]; then
        echo -e "\n🍏 ${CLR_GREEN}[苹果芯模式] 检测到 Apple Silicon (${ARCH_TYPE})，正在部署 MPS 硬件加速 AI 堆栈...${CLR_RESET}"
    else
        echo -e "\n💻 ${CLR_CYAN}[Mac Intel模式] 检测到 Intel 架构 Mac，正在部署标准 CPU 运行堆栈...${CLR_RESET}"
    fi
    # macOS 上的标准 PyTorch 分发包已原生集成 MPS 硬件加速
    uv pip install torch torchvision spandrel pillow rich
else
    # Linux 运行环境适配
    if lspci | grep -qi nvidia || command -v nvidia-smi &> /dev/null; then
        echo -e "\n🔥 ${CLR_YELLOW}[狂飙模式] 物理嗅探到 NVIDIA 硬件驱动，正在注入 CUDA 加速版 AI 堆栈...${CLR_RESET}"
        echo -e "   ${CLR_YELLOW}(由于包含物理运行时，体积在 2.5GB+，请保持网络畅通)${CLR_RESET}"
        uv pip install torch torchvision spandrel pillow rich
    else
        echo -e "\n🧠 ${CLR_CYAN}[精简模式] 未检测到 N卡，正在注入轻量化 CPU 向量加速版 AI 堆栈...${CLR_RESET}"
        uv pip install torch torchvision \
            --index-url https://download.pytorch.org/whl/cpu \
            --index-strategy unsafe-first-match
        uv pip install spandrel pillow rich
    fi
fi

echo "---------------------------------------------------"
echo -e "🎉 ${CLR_GREEN}[✓] 依赖环境已完美对齐！您可以免激活直接运行业务。${CLR_RESET}"
