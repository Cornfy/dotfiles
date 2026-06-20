#!/bin/bash

# ============================================================
# 配置区域
readonly SOURCE_DIR="$HOME/Pictures/Upscayl/Input"             # 原始截图输入目录
readonly FINAL_DIR="$HOME/Pictures/Upscayl/Optimized"          # 最终存放目录

# --- Upscayl CLI 核心配置 ---
readonly MODEL_PATH="$HOME/Pictures/Upscayl/.models/"          # NCNN 模型基础目录
readonly MODEL_NAME="high-fidelity-4x"                         # 使用的高保真模型
readonly RESIZE_FILTER="mitchell"                              # 缩放滤镜 (推荐 mitchell 或 catmullrom)

# --- 动态缩放与高级开关 ---
readonly TARGET_SCALE="2"                                      # 期望的最终成品的倍率！(支持 1, 2, 1.5 等任意数字)
readonly DOUBLE_UPSCALE="false"                                # 是否开启双修复流，升图两次 (true/false)

# --- 支持的图片格式扩展名 ---
readonly EXTENSIONS=("png" "jpg" "jpeg" "webp")
# ============================================================

show_help() {
    cat << EOF
📊 自动化 AI 图像修复与归档工具 (CLI Workflow)
---------------------------------------------------
使用方法:
  $0 -r, --run      🚀 实际运行全自动处理流
  $0 -h, --help     💡 显示此帮助信息

当前生效配置:
  📁 输入目录: $SOURCE_DIR
  📁 输出目录: $FINAL_DIR
  📈 目标倍率: ${TARGET_SCALE}x (双修流: $DOUBLE_UPSCALE)
  🖼️ 匹配格式: ${EXTENSIONS[*]}

---------------------------------------------------
💡 模型下载与安装提示 (Model Download Tips):
  由于你将模型路径自定义为了: $MODEL_PATH
  如果运行提示找不到模型，请按以下方式配置：
  
  1. 系统原生模型拷贝 (如果你安装了 Linux 桌面版 Upscayl):
     mkdir -p "$MODEL_PATH"
     cp -r /usr/lib/upscayl/models/* "$MODEL_PATH"
     
  2. 官方 GitHub 开源下载:
     如果你需要更多更强大的模型（如 RealESRGAN, Ultrasharp），可以前往
     👉 https://github.com/upscayl/upscayl 获取并丢进上面的目录中。
---------------------------------------------------
EOF
}

check_dependencies() {
    local dependencies=("upscayl" "identify" "bc" "oxipng" "exiftool" "media-sorter")
    local missing_deps=()

    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "❌ 错误: 脚本运行缺少以下必要依赖工具:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo "---------------------------------------------------"
        echo "💡 提示: 你可以使用以下命令安装缺少的系统组件 (media-sorter 除外):"
        echo "  sudo pacman -S upscayl-ncnn imagemagick bc oxipng perl-image-exiftool"
        exit 1
    fi
}

# 核心函数：动态计算分辨率并调用 Upscayl
upscayl_process() {
    local src="$1"
    local dest="$2"

    # 借助 ImageMagick 获取原图的宽高
    local width=$(identify -format "%w" "$src")
    local height=$(identify -format "%h" "$src")

    # 根据 TARGET_SCALE 计算出目标分辨率 (支持浮点数计算)
    local target_w=$(printf "%.0f" $(echo "$width * $TARGET_SCALE" | bc))
    local target_h=$(printf "%.0f" $(echo "$height * $TARGET_SCALE" | bc))
    local target_res="${target_w}x${target_h}"

    if [[ "$DOUBLE_UPSCALE" == "true" ]]; then
        echo "  [1/4 Upscayl] 正在执行【双修复流】-> 目标尺寸: $target_res"
        local tmp_pass1="${dest%.*}_pass1.png"

        # Pass 1: 先用默认的 4 倍放大强行拉起细节
        upscayl -i "$src" -o "$tmp_pass1" -m "$MODEL_PATH" -n "$MODEL_NAME" > /dev/null 2>&1

        # Pass 2: 二次精修并同时缩放到计算出来的目标分辨率
        upscayl -i "$tmp_pass1" -o "$dest" -m "$MODEL_PATH" -n "$MODEL_NAME" -r "${target_res}:${RESIZE_FILTER}" > /dev/null 2>&1
        rm -f "$tmp_pass1"
    else
        echo "  [1/4 Upscayl] 正在执行【单修复流】-> 目标尺寸: $target_res"
        # 单轮流：直接放大并通过 -r 缩放到目标分辨率
        upscayl -i "$src" -o "$dest" -m "$MODEL_PATH" -n "$MODEL_NAME" -r "${target_res}:${RESIZE_FILTER}" > /dev/null 2>&1
    fi
}

# 压缩与色彩校准
optimize_and_calibrate() {
    local target="$1"
    echo "  [2/4 Optimize] 正在优化体积并校准色彩..."
    oxipng -o 4 --strip safe "$target" > /dev/null 2>&1
    exiftool -ColorSpace=sRGB -overwrite_original "$target" > /dev/null 2>&1
}

# 同步修改时间（mtime）
sync_mtime() {
    local ref="$1"
    local target="$2"
    if [[ -f "$ref" ]]; then
        touch -r "$ref" "$target"
        echo "  [3/4 TimeSync] 已从原图同步 mtime"
        return 0
    fi
}

# 调用 Go 工具，根据 EXIF 信息重命名图片
# 若 EXIF 缺失，则先将 mtime 写入 EXIF 中
finalize_metadata() {
    local dir="$1"
    if [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
        echo "  [4/4 Finalize] 正在运行 media-sorter 固化 EXIF 并重命名..."
        # 配合自制的 Go 工具：使用原生支持的 -yes 参数进行全自动无人值守处理
        media-sorter -no-backup -yes -dir "$dir"
    fi
}

# ============================================================
# 4. 核心工作流执行体
# ============================================================
run_workflow() {
    # 1. 优先环境依赖检查
    check_dependencies

    # 2. 基础目录检查
    [[ ! -d "$SOURCE_DIR" ]] && echo "❌ 错误: 找不到原图目录: $SOURCE_DIR" && exit 1

    # --- 动态构建 find 的格式匹配参数 ---
    local find_args=()
    for ext in "${EXTENSIONS[@]}"; do
        if [[ ${#find_args[@]} -gt 0 ]]; then
            find_args+=("-o")
        fi
        find_args+=("-iname" "*.$ext")
    done

    # 3. 检查文件数量
    local file_count=$(find "$SOURCE_DIR" -maxdepth 1 -type f \( "${find_args[@]}" \) | wc -l)
    if [[ "$file_count" -eq 0 ]]; then
        echo "⚠️  $SOURCE_DIR 目录下没有发现任何支持的图片 (${EXTENSIONS[*]})。"
        exit 0
    fi

    mkdir -p "$FINAL_DIR"
    echo "🚀 开始 CLI 动态分辨率处理流 (找到 $file_count 张待处理图片)..."
    echo "---------------------------------------------------"

    # 4. 遍历处理核心循环
    find "$SOURCE_DIR" -maxdepth 1 -type f \( "${find_args[@]}" \) -print0 | while IFS= read -r -d '' img; do
        local filename=$(basename "$img")
        local base_name="${filename%.*}"
        local dest_file="$FINAL_DIR/${base_name}.png"

        echo "正在处理: $filename"

        upscayl_process "$img" "$dest_file"

        if [[ -f "$dest_file" ]]; then
            optimize_and_calibrate "$dest_file"
            sync_mtime "$img" "$dest_file"
        else
            echo "❌ 错误: $filename AI 处理失败！"
        fi

        echo "Done: ${base_name}.png"
        echo "---------------------------------------------------"
    done

    # 5. 批量执行 Go 归档工具
    finalize_metadata "$FINAL_DIR"

    echo "✨ 所有任务处理完成！"
    echo "📂 成品位于: $FINAL_DIR"
}

# ============================================================
# 5. 参数解析入口 (默认显示帮助)
# ============================================================

# 如果没有传递任何参数，默认打印帮助菜单
if [ "$#" -eq 0 ]; then
    show_help
    exit 0
fi

# 解析输入参数
case "$1" in
    -r|--run)
        run_workflow
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "❌ 错误: 未知参数 '$1'"
        echo "---------------------------------------------------"
        show_help
        exit 1
        ;;
esac
