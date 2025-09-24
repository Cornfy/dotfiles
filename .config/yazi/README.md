# 我的 Yazi 配置

这份文档详细介绍了我的 [Yazi](https://github.com/sxyazi/yazi) 文件管理器配置。这是一个为 Wayland 环境量身打造的、高效、美观且功能强大的文件管理体验，深度整合了各种命令行工具和自定义插件。

## 核心理念

本配置的核心是通过以下方式增强 Yazi 的原生功能：

- **强大的预览能力**：利用 `piper` 插件，将 `eza`, `glow`, `mediainfo`, `ouch` 等优秀的命令行工具无缝整合为文件预览器。
- **插件驱动的工作流**：通过安装一系列功能性插件（如 `smart-enter`, `compress`, `chmod`, `wl-clipboard` 等），简化常见的文件操作。
- **高度定制化的界面**：通过 `init.lua` 脚本，自定义了顶部标题栏、底部状态栏以及文件列表的行信息，使其更符合个人习惯和审美。
- **明确的操作逻辑**：通过精心设计的 `keymap.toml`，为常用功能和插件设置了直观的快捷键。

## 基本用法

Yazi 的操作逻辑深受 Vim 启发，以下是一些最基础的按键：

| 按键 | 备用按键 | 功能描述 |
| :--- | :--- | :--- |
| `k` | `↑` | 光标上移 |
| `j` | `↓` | 光标下移 |
| `h` | `←` | 进入父目录 |
| `l` | `→` | **[已修改]** 智能进入：若是目录则进入，若是文件则打开 |
| `o` | `<Enter>` | 打开文件 |
| `O` | `<Shift>` + `<Enter>` | 使用选择的方式打开文件 |
| `q` | | 退出 Yazi (若使用 `y` 脚本，会改变终端目录) |
| `Q` | | 退出 Yazi (若使用 `y` 脚本，不会改变终端目录) |
| `gg` | | 跳转到列表顶部 |
| `G` | | 跳转到列表底部 |
| `gh` | | 跳转到家目录|
| `<Space>` | | 选中/取消选中当前文件 |
| `v` | | 进入可视化选择模式 |
| `y` | | Yazi 内部“复制”（Yank） |
| `x` | | Yazi 内部“剪切” |
| `p` | | 粘贴 |
| `-` | | 粘贴软链接 |
| `a` | | 创建文件或文件夹，名称后跟 `/` 则为文件夹 |
| `r` | | 重命名文件 |
| `d` | | 删除到回收站 |
| `D` | | 永久删除 |
| `.` | | 显示隐藏文件 |
| `cc` | | 复制文件路径 |
| `cf` | | 复制文件名 |

更多按键参阅[官方文档#快速开始](https://yazi-rs.github.io/docs/quick-start/)

**注意**：推荐使用 `y` [shell wrapper](https://yazi-rs.github.io/docs/quick-start#shell-wrapper) 来启动 Yazi，这样退出时可以同步更改终端的工作目录。

## 插件详解

本配置通过 `package.toml` 安装并管理了以下插件，并通过 `keymap.toml` 为它们分配了快捷键：

| 插件 | 快捷键 | 功能描述 |
| :--- | :--- | :--- |
| **smart-enter** | `l` 或 `→` | **智能进入**。这是核心改动之一，将“进入目录”和“打开文件”两个操作合二为一，极大提升了流畅度。 |
| **piper** | (无) | **管道预览器**。这是一个基础插件，用于执行任意 Shell 命令并将结果输出到预览窗口。本配置大量使用它来实现自定义预览。 |
| **mediainfo** | (无) | 用于预览音视频和图片文件的详细媒体信息，替换了 Yazi 的默认预览器。 |
| **ouch** | `C` `C` | 使用 `ouch` 工具**压缩**选中的文件。 |
| **compress** | `C` `a` `a/p/h/l/u` | 一个功能更丰富的压缩插件，支持密码(`p`)、加密头(`h`)、压缩等级(`l`)等多种选项。 |
| **wl-clipboard**| `Y` | **[Wayland]** 将选中的文件路径以 `file://` URI 格式复制到系统剪贴板，方便粘贴到其他图形应用。 |
| **chmod** | `c` `m` | 对选中的文件执行 `chmod` 命令，方便快速修改文件权限。 |
| **mount** | `M` `P` | **[Linux/macOS]** 打开一个菜单，用于管理（挂载/卸载/弹出）本地磁盘分区。 |

## 自定义配置详解

### `yazi.toml` - 主配置文件

- **`[mgr]` 管理器设置**:
  - `show_hidden = true`: 默认显示隐藏文件 (以 `.` 开头)。
  - `show_symlink = true`: 在文件名后显示符号链接指向的目标。
  - `linemode = "info"`: 使用名为 `info` 的自定义行模式，具体实现在 `init.lua` 中。
  - `ratio = [1, 4, 5]`: 调整三栏（父目录、当前目录、预览）的宽度比例，增大了预览窗口的占比。

- **`[opener]` & `[open]` 打开器规则**:
  - `edit-in-new-window`: 添加了一个新的打开方式，可以通过 `foot` 终端在新窗口中编辑文件，而不会阻塞 Yazi。此选项已应用于所有文本文件，可在 `Shift+O` 菜单中选择。
  - `extract`: 为解压操作额外增加了 `ouch` 的选项，提供更现代、更快速的压缩包处理能力。
  - **`reveal` & `play` (元信息查看优化)**: 对显示文件元信息（如照片的 EXIF、音视频的媒体信息）的命令进行了重要优化。原先使用 `read` 命令暂停的方式，在通过 `y` 脚本启动 Yazi 时会导致交互阻塞。现在，已统一改为**使用 `bat` 作为分页器**。

- **`[plugin]` 预览器配置**:
  - **`prepend_previewers`**: 这是预览功能的核心。我们定义了一套覆盖默认行为的预览规则，优先级从上到下：
    1.  **目录**: 使用 `eza` 以树状结构预览目录内容（最多3层）。
    2.  **Markdown**: 使用 `glow` 进行精美的 Markdown 渲染预览。
    3.  **媒体文件**: 使用 `mediainfo` 插件预览所有音视频和图片文件的详细元数据。
    4.  **压缩包**: 使用 `ouch` 插件预览主流压缩包（zip, tar, 7z, rar 等）的文件列表。
  - **`prepend_preloaders`**: 配合 `mediainfo` 插件，为其预加载数据。

- **`[tasks]` 任务设置**:
  - `image_alloc = 1073741824`: 将单个图片解码的内存限制提高到 1GB，以应对高分辨率图片或像 PSD/AI 这样的大文件预览。

### `init.lua` - 界面与功能定制

这个文件通过 Lua 脚本对 Yazi 的界面和功能进行了深度美化：

1.  **自定义顶部标题栏**:
    - 在左上角添加了 `username@hostname:` 的信息（如 `elysia@archlinux:`），方便在多台机器上工作时快速识别当前环境。

2.  **自定义底部状态栏**:
    - 在右下角添加了当前光标悬停文件的**所有者**和**用户组**信息（如 `elysia:elysia`），对于权限管理非常有用。

3.  **自定义行模式 `Linemode:info()`**:
    - 实现了在 `yazi.toml` 中设置的 `linemode = "info"`。
    - 对于每个文件，在名称右侧显示**易读的文件大小**（如 `15.1 MiB`）和**智能格式化的修改时间**（当年份为今年时，显示月日和时间；否则显示年份和时间）。

## 安装与依赖

要完整复现此配置，您需要：

0.  **安装 Yazi 及其依赖项**:
    - 可参阅 [官方文档#安装](https://yazi-rs.github.io/docs/installation) 或 [我的README.md#文件管理](https://github.com/Cornfy/dotfiles/blob/main/README.md#%E4%B8%AA%E4%BA%BA%E7%9A%84-hyprland-%E9%85%8D%E7%BD%AE%E6%89%80%E9%9C%80%E7%9A%84%E4%BE%9D%E8%B5%96%E5%8C%85)

1.  **安装 Yazi 插件额外需要的依赖项**:

    - 安装 `bat` 、`eza` 、`glow` 、`mediainfo` 、`ouch` 等包。

2.  **克隆配置文件**:
    - 将此仓库中的 `yazi` 文件夹完整复制到您的 `~/.config/` 目录下。
    - 当然，我的配置文件中已经包含了我使用的插件。

3.  **安装 Yazi 插件**:
    - Yazi 的插件需要通过其内置的包管理器 `ya` 单独安装。进入 Yazi 配置目录并执行：
      ```bash
      ya pkg install
      ```
      这个命令会读取 `package.toml` 文件，并自动从 GitHub 下载并安装所有必需的插件。

    - 你也可单独安装，我使用的插件具体如下：
      ```bash
      ya pkg add \
          yazi-rs/plugins:piper \
          boydaihungst/mediainfo \
          ndtoan96/ouch \
          yazi-rs/plugins:smart-enter \
          yazi-rs/plugins:chmod \
          KKV9/compress \
          grappas/wl-clipboard \
          yazi-rs/plugins:mount
      ```

    - **注意**：我修改了 `yazi/plugins/piper.yazi/main.lua` 文件，以去掉 Yazi 的 25.9.15 版本要求（截至目前 Yazi 的正式版还是 25.5.31 ），以避免预览目录时不必要的错误提示（**这不是合适的操作**）。因此在更新 piper 插件时，应当将 `main.lua.default` 恢复为 `main.lua` 。

4.  **你也可以自行安装其他 Yazi 插件**:
    - Yazi 的插件需要通过其内置的包管理器 `ya` 单独安装。进入 Yazi 配置目录并执行：
      ```bash
      ya pkg add <PLUGIN_NAME>
      ```
    - 安装插件之后，你可能需要修改 yazi.toml 或 keymap.toml

    - 更多插件可查阅[官方文档中的资源部分](https://yazi-rs.github.io/docs/resources)

现在，启动 Yazi，您将拥有一个与我完全相同的、功能强大的文件管理环境。
