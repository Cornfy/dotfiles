#!/bin/bash
# file: bwrap-run.sh
# 描述: Bubblewrap 通用沙箱封装工具 (面向环境ID管理, 使用Shell代理统一执行)

# --- 1. 用户配置区 (Configuration Settings) ---
readonly ROOT_DIRECTORY_FOR_PERSISTENCE_OF_ALL_SANDBOXES_ON_SYSTEM="$HOME/.sandbox_data"
readonly HOME_DIRECTORY_FOR_APPLICATION_INSIDE_SANDBOX="$HOME"
readonly VALUE_OF_PATH_ENVIRONMENT_VARIABLE_IN_SANDBOX="/usr/local/bin:/usr/bin:/bin"

# --- 2. 内部变量 (Runtime & Context) ---
FULL_PATH_OF_COMMAND_ON_SYSTEM=""                  # 宿主机上本次要执行的命令的绝对路径
SANDBOX_ID=""                                      # 沙箱的唯一标识符
PERSISTENCE_DIRECTORY_OF_SANDBOX_ID_ON_SYSTEM=""   # 宿主机上沙箱持久化数据的目录
TARGET_COMMAND_STRING_INSIDE_SANDBOX=""            # 传递给沙箱内 /bin/bash -c 的最终命令字符串
SCRIPT_OPERATION_MODE=""                           # "RUN_COMMAND", "LIST", "HELP"


# --- 3. 辅助函数 ---

# 打印用法信息并退出
print_usage_and_exit() {
    echo "用法:"
    echo "  1. 运行命令/应用 (交互式选择沙箱ID):"
    echo "      $0 <可执行文件/命令> [参数...]"
    echo "      例如: $0 firefox"
    echo ""
    echo "  2. 运行命令/应用 (指定沙箱ID):"
    echo "      $0 --id <沙箱名> <可执行文件/命令> [参数...]"
    echo "      例如: $0 --id browser_work firefox"
    echo ""
    echo "  3. 进入沙箱执行 Shell (指定沙箱ID):"
    echo "      $0 --id <沙箱名>"
    echo "      例如: $0 --id browser_work"
    echo ""
    echo "  4. 管理和信息:"
    echo "      $0 --list             # 列出所有已创建的沙箱"
    echo "      $0 --help             # 打印此帮助信息"
    exit 1
}

# 列出所有已创建的沙箱并退出
list_sandboxes_and_exit() {
    if [ ! -d "$ROOT_DIRECTORY_FOR_PERSISTENCE_OF_ALL_SANDBOXES_ON_SYSTEM" ]; then
        echo "宿主沙箱根目录 '$ROOT_DIRECTORY_FOR_PERSISTENCE_OF_ALL_SANDBOXES_ON_SYSTEM' 不存在。"
        exit 0
    fi
    
    echo "📦 已创建的沙箱列表 (持久化目录):"
    local count=0
    for sandbox_dir in "$ROOT_DIRECTORY_FOR_PERSISTENCE_OF_ALL_SANDBOXES_ON_SYSTEM"/*/; do
        if [ -d "$sandbox_dir" ]; then
            local id_name=$(basename "$sandbox_dir")
            echo "  - $id_name"
            count=$((count + 1))
        fi
    done

    if [ $count -eq 0 ]; then
        echo "  (没有已创建的沙箱)"
    fi
    exit 0
}

# 交互式询问沙箱 ID 并确认
prompt_for_identifier() {
    local default_id="$1"
    
    echo "--- 交互式沙箱 ID 确认 ---"

    local input_id=""
    read -r -p "请输入沙箱 ID (留空使用默认: $default_id): " input_id
    if [ -z "$input_id" ]; then
        SANDBOX_ID="$default_id"
    else
        SANDBOX_ID="$input_id"
    fi

    echo "✅ 确认沙箱 ID: $SANDBOX_ID"
    echo "---------------------------"
}

# 辅助函数：安全地将参数数组转换为单个、带引用的 Shell 字符串
# 解决 Shell 代理模式下的二次引用问题。
quote_arguments() {
    local quoted_args=()
    local arg
    for arg in "$@"; do
        # 使用 printf %q 进行健壮的 Shell 引用
        quoted_args+=( "$(printf %q "$arg")" )
    done
    echo "${quoted_args[*]}"
}

# 辅助函数：如果目标是 Home 目录命令，在持久化目录中创建必要的目录结构
_prepare_home_command_for_overlay_bind() {
    local host_command_path="$FULL_PATH_OF_COMMAND_ON_SYSTEM"
    
    if [[ "$host_command_path" == "$HOME"* ]]; then
        # 计算命令在 HOME 目录下的相对路径 (例如：Desktop/hello.sh)
        local relative_path_in_home="${host_command_path#$HOME/}"
        local target_dir_in_persistence
        target_dir_in_persistence="$PERSISTENCE_DIRECTORY_OF_SANDBOX_ID_ON_SYSTEM/$(dirname "$relative_path_in_home")"
        
        if [ ! -d "$target_dir_in_persistence" ]; then
            echo "ℹ️ 正在沙箱中创建命令的父目录结构: $target_dir_in_persistence"
            mkdir -p "$target_dir_in_persistence" || { echo "错误: 无法创建沙箱内目录结构"; exit 1; }
        fi
        return 0 # 是 Home 目录命令
    else
        return 1 # 不是 Home 目录命令
    fi
}

# 初始化持久化路径和目录
initialize_persistence_paths() {
    
    if [ -z "$SANDBOX_ID" ]; then
        echo "内部错误：沙箱 ID 未设置。"
        exit 1
    fi
    
    PERSISTENCE_DIRECTORY_OF_SANDBOX_ID_ON_SYSTEM="$ROOT_DIRECTORY_FOR_PERSISTENCE_OF_ALL_SANDBOXES_ON_SYSTEM/$SANDBOX_ID"

    # --- 1. 创建沙箱根目录 ---
    if [ ! -d "$PERSISTENCE_DIRECTORY_OF_SANDBOX_ID_ON_SYSTEM" ]; then
        echo "宿主数据目录 '$PERSISTENCE_DIRECTORY_OF_SANDBOX_ID_ON_SYSTEM' 不存在，正在创建..."
        mkdir -p "$PERSISTENCE_DIRECTORY_OF_SANDBOX_ID_ON_SYSTEM" || { echo "错误: 无法创建数据目录"; exit 1; }
    fi
    
    # --- 2. 为 Home 命令创建目录结构 (仅当 FULL_PATH_OF_COMMAND_ON_SYSTEM 已设置时) ---
    if [ -n "$FULL_PATH_OF_COMMAND_ON_SYSTEM" ]; then
        _prepare_home_command_for_overlay_bind
        echo "🎯 目标命令: $(basename "$FULL_PATH_OF_COMMAND_ON_SYSTEM")"
    else
        echo "🎯 目标命令: /bin/bash"
    fi
    
    echo "📂 使用沙箱路径: $HOME_DIRECTORY_FOR_APPLICATION_INSIDE_SANDBOX (主机路径: $PERSISTENCE_DIRECTORY_OF_SANDBOX_ID_ON_SYSTEM)"
}

# 解析输入参数并确定操作模式
parse_arguments_and_determine_mode() {
    if [ $# -eq 0 ]; then
        print_usage_and_exit
    fi

    local command_to_execute=""
    local command_arguments=()
    
    case "$1" in
        "--help")
            SCRIPT_OPERATION_MODE="HELP"
            print_usage_and_exit
            ;;
        "--list")
            SCRIPT_OPERATION_MODE="LIST"
            list_sandboxes_and_exit
            ;;
        "--id")
            # 模式 2 & 3: $0 --id <沙箱名> [命令] [参数...]
            if [ $# -lt 2 ]; then
                echo "错误：使用 --id 模式时，必须指定 <沙箱名>。"
                print_usage_and_exit
            fi
            
            SANDBOX_ID="$2"
            
            if [ $# -ge 3 ]; then
                command_to_execute="$3"
                command_arguments=("${@:4}")
            else
                # 模式 3: $0 --id <沙箱名> (默认执行 bash)
                command_to_execute="/bin/bash"
                command_arguments=()
            fi
            
            # 模式统一为 RUN_COMMAND
            SCRIPT_OPERATION_MODE="RUN_COMMAND"
            ;;
        *)
            # 模式 1: $0 <可执行文件/命令> [参数...]
            
            command_to_execute="$1"
            command_arguments=("${@:2}")
            
            # 模式统一为 RUN_COMMAND
            SCRIPT_OPERATION_MODE="RUN_COMMAND"
            
            # 将 ID 确定逻辑放在这里 (需要先找到命令的默认 ID)
            local resolved_path=""
            resolved_path=$(realpath -e "$command_to_execute" 2>/dev/null)
            if [ -z "$resolved_path" ]; then
                resolved_path=$(command -v "$command_to_execute" 2>/dev/null)
            fi

            if [ -n "$resolved_path" ]; then
                local binary_file_name=$(basename "$resolved_path")
                prompt_for_identifier "$binary_file_name"
            else
                echo "错误：无法找到可执行文件 '$command_to_execute' 的完整路径。"
                print_usage_and_exit
            fi
            ;;
    esac
    
    # --- 统一 RUN_COMMAND 模式下的路径解析和命令封装 ---
    if [ "$SCRIPT_OPERATION_MODE" == "RUN_COMMAND" ]; then
        local resolved_path=""
        # 查找目标命令的宿主绝对路径
        resolved_path=$(realpath -e "$command_to_execute" 2>/dev/null)
        if [ -z "$resolved_path" ]; then
            resolved_path=$(command -v "$command_to_execute" 2>/dev/null)
        fi

        if [ -z "$resolved_path" ]; then
             echo "错误：无法找到目标命令 '$command_to_execute' 的完整路径。"
             exit 1
        fi
 
        FULL_PATH_OF_COMMAND_ON_SYSTEM="$resolved_path"
        
        # --- 确定沙箱内要执行的命令路径/名 ---
        local command_to_run_inside_sandbox=""
        
        # 1. 如果命令在 $HOME 目录下（Overlay 绑定），使用绝对路径执行
        if [[ "$FULL_PATH_OF_COMMAND_ON_SYSTEM" == "$HOME"* ]]; then
            # 在沙箱内，路径保持不变，因此使用宿主的绝对路径
            command_to_run_inside_sandbox="$FULL_PATH_OF_COMMAND_ON_SYSTEM"
            echo "ℹ️ 命令位于 Home 目录，将使用绝对路径执行: $command_to_run_inside_sandbox"
        
        # 2. 如果命令在系统非核心目录（如 /opt），使用绝对路径执行
        elif [[ "$FULL_PATH_OF_COMMAND_ON_SYSTEM" != "/usr/"* && "$FULL_PATH_OF_COMMAND_ON_SYSTEM" != "/bin"* && "$FULL_PATH_OF_COMMAND_ON_SYSTEM" != "/sbin"* ]]; then
            # 对于 /opt 或 /usr/local/bin 等路径，也最好使用绝对路径，以防 PATH 丢失
            command_to_run_inside_sandbox="$FULL_PATH_OF_COMMAND_ON_SYSTEM"
            echo "ℹ️ 命令位于非核心系统目录，将使用绝对路径执行: $command_to_run_inside_sandbox"
    
        # 3. 否则，命令在核心系统目录（/usr/bin, /bin），依赖沙箱内 $PATH 查找（使用 basename）
        else
            # 依赖沙箱内已设置的 $PATH
            command_to_run_inside_sandbox=$(basename "$command_to_execute")
            echo "ℹ️ 命令位于核心系统目录，将依赖 \$PATH 查找执行: $command_to_run_inside_sandbox"
        fi
        
        # 1. 引用命令参数
        local quoted_args
        quoted_args=$(quote_arguments "${command_arguments[@]}")
        
        # 2. 封装最终命令字符串
        TARGET_COMMAND_STRING_INSIDE_SANDBOX="$command_to_run_inside_sandbox $quoted_args"
    fi
}


# --- 4. 绑定函数 (GUI/RUNTIME) ---

_bind_wayland() {
    if [ -n "$WAYLAND_DISPLAY" ]; then
        local WAYLAND_SOCKET_PATH="/run/user/$UID/$WAYLAND_DISPLAY"
        if [ -e "$WAYLAND_SOCKET_PATH" ]; then
            echo "启用 Wayland 支持..."
            BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --bind $WAYLAND_SOCKET_PATH $WAYLAND_SOCKET_PATH"
            BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --setenv WAYLAND_DISPLAY $WAYLAND_DISPLAY"
        fi
    fi
}
_bind_x11_fallback() {
    if [ -n "$DISPLAY" ]; then
        echo "启用 X11 支持..."
        BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --bind /tmp/.X11-unix /tmp/.X11-unix"
        BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --setenv DISPLAY $DISPLAY"
    fi
}
_bind_audio() {
    if [ -n "$XDG_RUNTIME_DIR" ] && [ -d "$XDG_RUNTIME_DIR" ]; then
        if [ -d "/run/user/$UID/pipewire-0" ]; then
            echo "启用 PipeWire 音频支持..."
            BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --bind /run/user/$UID/pipewire-0 /run/user/$UID/pipewire-0"
        fi
        if [ -d "/run/user/$UID/pulse" ]; then
            echo "启用 PulseAudio 兼容层支持..."
            BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --bind /run/user/$UID/pulse /run/user/$UID/pulse"
        fi
    fi
}
_bind_vulkan() {
    local VULKAN_SHARE_DIR="/usr/share/vulkan"
    local VULKAN_ETC_DIR="/etc/vulkan"
    if [ -d "$VULKAN_SHARE_DIR" ]; then
        echo "绑定 Vulkan 配置 (USR_SHARE 路径)..."
        BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --ro-bind $VULKAN_SHARE_DIR $VULKAN_SHARE_DIR"
    elif [ -d "$VULKAN_ETC_DIR" ]; then
        echo "绑定 Vulkan 配置 (ETC 路径)..."
        BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --ro-bind $VULKAN_ETC_DIR $VULKAN_ETC_DIR"
    fi
}
_bind_devices() {
    echo "绑定输入设备和 FUSE..."
    BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --dev-bind /dev/input /dev/input"
    BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --dev-bind /dev/fuse /dev/fuse"
}
_bind_dbus_and_aux() {
    BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --bind /run/user/$UID/bus /run/user/$UID/bus"
    if [ -d "/run/user/$UID/at-spi" ]; then
        echo "启用 AT-SPI (辅助功能) 支持..."
        BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --bind /run/user/$UID/at-spi /run/user/$UID/at-spi"
    fi
    if [ -d "/run/user/$UID/gvfs" ]; then
        echo "启用 GVFS 支持..."
        BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --bind /run/user/$UID/gvfs /run/user/$UID/gvfs"
    fi
}
_bind_fonts() {
    echo "绑定系统和用户自定义字体..."
    BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --ro-bind /etc/fonts /etc/fonts"
    BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --ro-bind /usr/share/fonts /usr/share/fonts" 
    if [ -d "/usr/local/share/fonts" ]; then
        BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --ro-bind /usr/local/share/fonts /usr/local/share/fonts" 
    fi
    if [ -d "$HOME/.local/share/fonts" ]; then
        BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS+=" --ro-bind $HOME/.local/share/fonts $HOME/.local/share/fonts" 
    fi
}


# --- 5. 执行逻辑 (Shell 代理模式核心) ---
execute_sandboxed_command() {
    echo "正在沙箱内运行: $SANDBOX_ID..."

    local bwrap_arguments=()
    local host_command_path="$FULL_PATH_OF_COMMAND_ON_SYSTEM"

    # 基础隔离
    bwrap_arguments+=(
        --unshare-all
	--share-net
	--die-with-parent
	--proc /proc
	--dev /dev
	--tmpfs /tmp
	--tmpfs /run
    )

    # 系统目录绑定
    bwrap_arguments+=(
        --ro-bind /usr /usr
	--ro-bind /etc /etc
	--ro-bind /sys /sys
	--ro-bind /bin /bin
	--ro-bind /sbin /sbin
	--ro-bind /lib /lib
	--ro-bind /lib64 /lib64
    )

    # 、GPU 绑定
    bwrap_arguments+=(
	--dev-bind /dev/dri /dev/dri
    )

    # GUI/运行时 (展开变量)
    bwrap_arguments+=( $BWRAP_ARGUMENTS_FOR_GUI_AND_RUNTIME_BINDINGS )
    
    # --- 加载持久化环境 & 绑定本次执行的命令 ---
    
    # A. 统一加载环境 (所有模式的第一步)
    bwrap_arguments+=(
        --bind "$PERSISTENCE_DIRECTORY_OF_SANDBOX_ID_ON_SYSTEM" "$HOME_DIRECTORY_FOR_APPLICATION_INSIDE_SANDBOX" 
    )
    echo "✅ 策略：统一加载沙箱环境 HOME ($HOME_DIRECTORY_FOR_APPLICATION_INSIDE_SANDBOX)。"

    
    # B. 绑定本次要执行的命令 (仅当命令位于非核心系统路径或 Home 目录时才需额外绑定)
    if [ -n "$host_command_path" ]; then
        if [[ "$host_command_path" == "$HOME"* ]]; then
            # 策略 A: Home 目录命令 - 在 HOME 覆盖层上只读绑定文件本身
            bwrap_arguments+=(
                --ro-bind "$host_command_path" "$host_command_path"
            )
            echo "✅ 策略：Home 目录命令，在环境上进行文件级绑定 (Overlay)。"
        
        # 策略 B: 非核心系统路径应用 (如 /opt/app)
        elif [[ "$host_command_path" != "/usr/"* && "$host_command_path" != "/bin"* && "$host_command_path" != "/sbin"* && "$host_command_path" != "/lib"* && "$host_command_path" != "/lib64"* ]]; then
             local command_dir=$(dirname "$host_command_path")
             bwrap_arguments+=(
                --ro-bind "$command_dir" "$command_dir"
             )
             echo "⚠️ 策略：命令位于非核心系统路径 ($command_dir)。已绑定其父目录。"
        else
             echo "ℹ️ 策略：命令依赖于已全局绑定的系统目录 (/usr, /bin 等)。"
        fi
    else
        echo "ℹ️ 策略：执行 Shell 默认命令 (/bin/bash)，依赖于已全局绑定的系统目录。"
    fi

    # --- 3. 环境设置与执行 ---
    
    # 统一使用 /bin/bash -c "COMMAND" 执行
    local shell_command_target="/bin/bash"
    local shell_command_args=(-c "$TARGET_COMMAND_STRING_INSIDE_SANDBOX")
    
    bwrap_arguments+=(
        --chdir "$HOME_DIRECTORY_FOR_APPLICATION_INSIDE_SANDBOX" 
        --setenv HOME "$HOME_DIRECTORY_FOR_APPLICATION_INSIDE_SANDBOX" 
        --setenv PATH "$VALUE_OF_PATH_ENVIRONMENT_VARIABLE_IN_SANDBOX"
    )

    # # 打印 DEBUG 信息
    # echo "--- DEBUG INFO ---"
    # echo "bwrap_arguments[@] : "
    # echo "    ${bwrap_arguments[@]}"
    # echo ""
    # echo "Shell Command Target :"
    # echo "    $shell_command_target ${shell_command_args[*]}"
    # echo ""
    # echo "Target Command String INSIDE SANDBOX :"
    # echo "    $TARGET_COMMAND_STRING_INSIDE_SANDBOX"
    # echo "------------------"
    
    # 执行最终命令 (将注释符号 # 移除即可投入生产环境)
    bwrap "${bwrap_arguments[@]}" \
        -- "$shell_command_target" "${shell_command_args[@]}"
}

# --- 6. 脚本主入口 (Main Entry) ---
# 6.1. 解析参数并确定模式
parse_arguments_and_determine_mode "$@"

# 6.2. 初始化沙箱持久化路径（对 RUN_COMMAND 模式都适用）
if [ "$SCRIPT_OPERATION_MODE" == "RUN_COMMAND" ]; then
    initialize_persistence_paths

    # 6.3. 绑定 GUI 相关资源
    _bind_wayland
    _bind_x11_fallback
    _bind_audio
    _bind_vulkan
    _bind_devices
    _bind_dbus_and_aux
    _bind_fonts

    # 6.4. 执行应用或命令
    execute_sandboxed_command
fi
