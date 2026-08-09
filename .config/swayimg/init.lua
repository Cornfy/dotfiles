-- Swayimg v5.5+ Lua 配置文件

--------------------------------------------------------------------------------
-- 1. 全局与图像读取设置 (Global & Image List)
--------------------------------------------------------------------------------
-- 基础功能与读取选项
swayimg.exif_orientation = true     -- 开启 EXIF 自动旋转
swayimg.antialiasing = true         -- 开启抗锯齿渲染
swayimg.imagelist.adjacent = true   -- 自动添加同目录下的其他图片
swayimg.imagelist.fsmon = true      -- 监听文件系统变动（自动刷新）
swayimg.imagelist.order = "numeric" -- 文件自然数字排序 (1, 2, 3, 10...)


--------------------------------------------------------------------------------
-- 2. 外观与默认行为设置 (UI & Default Options)
--------------------------------------------------------------------------------
-- 默认显示模式与行为
swayimg.viewer.default_scale = "optimal"                        -- 默认最佳缩放（大图自适应窗口，小图保持原大小）
swayimg.viewer.default_position = "center"                      -- 图片加载时居中显示
swayimg.viewer.autocenter = true                                -- 实时自动居中显示
swayimg.viewer.loop = false                                     -- 开启列表循环浏览

-- 背景与透明图显示设置
swayimg.viewer.set_window_background(0xff1e1e2e)                -- 主窗口背景（Catppuccin 深配色）
swayimg.viewer.set_image_chessboard(12, 0xff313244, 0xff181825) -- PNG 透明区域棋盘格

-- 性能与预加载设置
swayimg.viewer.preload = 2                                      -- 预加载前后图片数
swayimg.viewer.history = 5                                      -- 缓存历史图片数

-- 图片信息显示样式
swayimg.viewer.set_text("topleft", {
    "[{list.index}/{list.total}] {name}",
    "----------------------------------------",
    "Format:\t{format}",
    "Geometry:\t{frame.width}x{frame.height} px ({scale})",
    "File Size:\t{sizehr}",
    "Modified:\t{time}"
})

--------------------------------------------------------------------------------
-- 3. 查看器模式交互绑定 (Viewer Mode Keybindings)
--------------------------------------------------------------------------------
swayimg.viewer.bind_reset()

-- 切换全屏: 空格
swayimg.viewer.on_key("Space", function()
    swayimg.fullscreen = not swayimg.fullscreen
end)

-- 切换信息显示: i
swayimg.viewer.on_key("i", function()
    swayimg.text.visible = not swayimg.text.visible
end)

-- 拖拽: 鼠标左键
swayimg.viewer.drag_button = "MouseLeft"

-- 缩放: 鼠标滚轮 (以鼠标当前指针位置为中心进行缩放)
swayimg.viewer.on_mouse("ScrollUp", function()
    local pos = swayimg.get_mouse_pos()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale * 1.15, pos.x, pos.y)
end)
swayimg.viewer.on_mouse("ScrollDown", function()
    local pos = swayimg.get_mouse_pos()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale / 1.15, pos.x, pos.y)
end)

-- 切图: Vim 键位 (h/l, 左/右, Home/End)
swayimg.viewer.on_key("h", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("l", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("Left", function() swayimg.viewer.open("prev") end)
swayimg.viewer.on_key("Right", function() swayimg.viewer.open("next") end)
swayimg.viewer.on_key("Home", function() swayimg.viewer.open("first") end)
swayimg.viewer.on_key("End", function() swayimg.viewer.open("last") end)
-- -- 切图: 鼠标滚轮
-- swayimg.viewer.on_mouse("ScrollUp", function() swayimg.viewer.open("prev") end)
-- swayimg.viewer.on_mouse("ScrollDown", function() swayimg.viewer.open("next") end)

-- 缩放: +/-
swayimg.viewer.on_key("Equal", function()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale * 1.25)
end)
swayimg.viewer.on_key("Minus", function()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale / 1.25)
end)
-- 重置缩放: 0
swayimg.viewer.on_key("0", function() swayimg.viewer.set_fix_scale("optimal") end)

-- 循环切换缩放模式: Tab
local scale_modes = {
    { mode = "optimal", name = "Optimal" },
    { mode = "fit",     name = "Fit" },
    { mode = "fill",    name = "Fill" },
    { mode = "real",    name = "Real Size" }
}
local current_scale_idx = 1
swayimg.viewer.on_key("Tab", function()
    current_scale_idx = (current_scale_idx % #scale_modes) + 1
    local target = scale_modes[current_scale_idx]
    swayimg.viewer.set_fix_scale(target.mode)
    swayimg.text.status = "Scale Mode: " .. target.name
end)

-- 旋转: [/]
swayimg.viewer.on_key("]", function() swayimg.viewer.rotate(90) end)
swayimg.viewer.on_key("[", function() swayimg.viewer.rotate(270) end)

-- 模式切换与程序退出
swayimg.viewer.on_key("Return", function() swayimg.mode = "gallery" end) -- 按 Enter 进入画廊模式
swayimg.viewer.on_key("q", function() swayimg.exit(0) end)               -- 按 q 退出
swayimg.viewer.on_key("Escape", function() swayimg.exit(0) end)          -- 按 Esc 退出

--------------------------------------------------------------------------------
-- 4. 画廊模式交互绑定 (Gallery Mode Keybindings)
--------------------------------------------------------------------------------
swayimg.gallery.bind_reset()

-- 缩略图网格导航: Vim 键位 (h/j/k/l, 方向键)
swayimg.gallery.on_key("h", function() swayimg.gallery.select("left") end)
swayimg.gallery.on_key("l", function() swayimg.gallery.select("right") end)
swayimg.gallery.on_key("k", function() swayimg.gallery.select("up") end)
swayimg.gallery.on_key("j", function() swayimg.gallery.select("down") end)
swayimg.gallery.on_key("Left", function() swayimg.gallery.select("left") end)
swayimg.gallery.on_key("Right", function() swayimg.gallery.select("right") end)
swayimg.gallery.on_key("Up", function() swayimg.gallery.select("up") end)
swayimg.gallery.on_key("Down", function() swayimg.gallery.select("down") end)

-- 模式切换与程序退出
swayimg.gallery.on_key("Return", function() swayimg.mode = "viewer" end) -- 按 Enter 查看所选图片
swayimg.gallery.on_key("q", function() swayimg.exit(0) end)              -- 按 q 退出
swayimg.gallery.on_key("Escape", function() swayimg.exit(0) end)         -- 按 Esc 退出
