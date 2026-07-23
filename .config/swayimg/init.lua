-- ==============================================================================
-- Swayimg v5.x Lua 配置文件
-- 位置: ~/.config/swayimg/init.lua
-- ==============================================================================

--------------------------------------------------------------------------------
-- 1. 全局与图像读取设置 (Global & Image List)
--------------------------------------------------------------------------------
-- 基础功能与读取选项
swayimg.enable_exif_orientation(true)                                   -- 开启 EXIF 自动旋转
swayimg.enable_antialiasing(true)                                       -- 开启抗锯齿渲染
swayimg.imagelist.enable_adjacent(true)                                 -- 自动添加同目录下的其他图片
swayimg.imagelist.enable_fsmon(true)                                    -- 监听文件系统变动（自动刷新）
swayimg.imagelist.set_order("numeric")                                  -- 文件自然数字排序 (1, 2, 3, 10...)

--------------------------------------------------------------------------------
-- 2. 外观与默认行为设置 (UI & Default Options)
--------------------------------------------------------------------------------
-- 默认显示模式与行为
swayimg.viewer.set_default_scale("optimal")                             -- 默认最佳缩放（大图自适应窗口，小图保持原大小）
swayimg.viewer.set_default_position("center")
swayimg.viewer.enable_centering(true)                                   -- 自动居中显示
-- swayimg.viewer.enable_loop(true)                                     -- 开启列表循环浏览

-- 背景与透明图显示设置
swayimg.viewer.set_window_background(0xff1e1e2e)                        -- 主窗口背景（Catppuccin 深配色）
swayimg.viewer.set_image_chessboard(12, 0xff313244, 0xff181825)         -- PNG 透明区域棋盘格

-- 性能与预加载设置
swayimg.viewer.limit_preload(2)                                         -- 预加载前后图片数
swayimg.viewer.limit_history(5)                                         -- 缓存历史图片数

-- 图片信息显示
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

-- 界面功能与状态控制
swayimg.viewer.on_key("Space", function() swayimg.set_fullscreen() end) -- 空格切换全屏
swayimg.viewer.on_key("i", function()                                   -- 按 i 切换信息显示
    if swayimg.text.visible() then
        swayimg.text.hide()
    else
        swayimg.text.show()
    end
end)

-- 鼠标左键拖拽
swayimg.viewer.set_drag_button("MouseLeft")
-- 鼠标滚轮切图
swayimg.viewer.on_mouse("ScrollUp", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_mouse("ScrollDown", function() swayimg.viewer.switch_image("next") end)

-- Ctrl + 滚轮：以鼠标当前指针位置为中心进行缩放
swayimg.viewer.on_mouse("Ctrl-ScrollUp", function()
    local pos = swayimg.get_mouse_pos()
    swayimg.viewer.set_abs_scale(swayimg.viewer.get_scale() * 1.15, pos.x, pos.y)
end)
swayimg.viewer.on_mouse("Ctrl-ScrollDown", function()
    local pos = swayimg.get_mouse_pos()
    swayimg.viewer.set_abs_scale(swayimg.viewer.get_scale() / 1.15, pos.x, pos.y)
end)

-- 按键切图 (Vim 键位: h/l、左右方向键、Home/End)
swayimg.viewer.on_key("h", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("l", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("Left", function() swayimg.viewer.switch_image("prev") end)
swayimg.viewer.on_key("Right", function() swayimg.viewer.switch_image("next") end)
swayimg.viewer.on_key("Home", function() swayimg.viewer.switch_image("first") end)
swayimg.viewer.on_key("End", function() swayimg.viewer.switch_image("last") end)

-- 重置图片缩放
swayimg.viewer.on_key("0", function() swayimg.viewer.set_fix_scale("optimal") end)

-- 缩放与显示模式切换
swayimg.viewer.on_key("Equal", function() swayimg.viewer.set_abs_scale(swayimg.viewer.get_scale() * 1.25) end) -- '+' 键放大
swayimg.viewer.on_key("Minus", function() swayimg.viewer.set_abs_scale(swayimg.viewer.get_scale() / 1.25) end) -- '-' 键缩小

-- 循环切换缩放模式 (Tab 键)
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
    swayimg.text.set_status("Scale Mode: " .. target.name) -- 屏幕弹出提示
end)

-- 模式切换与程序退出
swayimg.viewer.on_key("Return", function() swayimg.set_mode("gallery") end) -- 按 Enter 进入画廊模式
swayimg.viewer.on_key("q", function() swayimg.exit(0) end)
swayimg.viewer.on_key("Escape", function() swayimg.exit(0) end)

--------------------------------------------------------------------------------
-- 4. 画廊模式交互绑定 (Gallery Mode Keybindings)
--------------------------------------------------------------------------------
swayimg.gallery.bind_reset()

-- 缩略图网格导航 (Vim 键位: h/j/k/l 及 方向键)
swayimg.gallery.on_key("h", function() swayimg.gallery.switch_image("left") end)
swayimg.gallery.on_key("l", function() swayimg.gallery.switch_image("right") end)
swayimg.gallery.on_key("k", function() swayimg.gallery.switch_image("up") end)
swayimg.gallery.on_key("j", function() swayimg.gallery.switch_image("down") end)
swayimg.gallery.on_key("Left", function() swayimg.gallery.switch_image("left") end)
swayimg.gallery.on_key("Right", function() swayimg.gallery.switch_image("right") end)
swayimg.gallery.on_key("Up", function() swayimg.gallery.switch_image("up") end)
swayimg.gallery.on_key("Down", function() swayimg.gallery.switch_image("down") end)

-- 模式切换与程序退出
swayimg.gallery.on_key("Return", function() swayimg.set_mode("viewer") end) -- 按 Enter 查看所选图片
swayimg.gallery.on_key("q", function() swayimg.exit(0) end)
swayimg.gallery.on_key("Escape", function() swayimg.exit(0) end)
