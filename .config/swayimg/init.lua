-- Swayimg v5.7 Lua 配置文件

--------------------------------------------------------------------------------
-- 1. 全局与图像读取设置
--------------------------------------------------------------------------------

swayimg.exif_orientation = true
swayimg.antialiasing = true
swayimg.imagelist.adjacent = true
swayimg.imagelist.fsmon = true
swayimg.imagelist.order = "numeric"


--------------------------------------------------------------------------------
-- 2. 外观与默认行为设置
--------------------------------------------------------------------------------

-- 默认显示模式与行为
swayimg.viewer.default_scale = "optimal"
swayimg.viewer.default_position = "center"
swayimg.viewer.autopos = "center"
swayimg.viewer.loop = false

-- 背景与透明图显示设置
swayimg.viewer.set_window_background(0xff1e1e2e)
swayimg.viewer.set_image_chessboard(12, 0xff313244, 0xff181825)

-- 性能与预加载设置
swayimg.viewer.preload = 2
swayimg.viewer.history = 5

-- 图片信息显示样式
swayimg.viewer.text = {
    topleft = {
        "[{list.index}/{list.total}] {name}",
        "----------------------------------------",
        "Format:\t{format}",
        "Geometry:\t{frame.width}x{frame.height} px ({scale})",
        "File Size:\t{sizehr}",
        "Modified:\t{time}"
    }
}


--------------------------------------------------------------------------------
-- 3. 查看器模式交互绑定
--------------------------------------------------------------------------------

swayimg.viewer.bind_reset()

-- 切换全屏：空格
swayimg.viewer.on_key("Space", function()
    swayimg.fullscreen = not swayimg.fullscreen
end)

-- 切换信息显示：i
swayimg.viewer.on_key("i", function()
    swayimg.text.visible = not swayimg.text.visible
end)

-- 拖拽：鼠标左键
swayimg.viewer.drag_button = "MouseLeft"

-- 缩放：鼠标滚轮，以鼠标指针位置为中心
swayimg.viewer.on_scroll(function(keymod, horizontal, vertical)
    if vertical == 0 then
        return
    end

    local pos = swayimg.get_mouse_pos()
    local scale = swayimg.viewer.scale

    if vertical > 0 then
        scale = scale / 1.15
    else
        scale = scale * 1.15
    end

    swayimg.viewer.set_abs_scale(scale, pos.x, pos.y)
end)

-- 切图：Vim 键位、方向键、Home/End
swayimg.viewer.on_key("h", function()
    swayimg.viewer.open("prev")
end)

swayimg.viewer.on_key("l", function()
    swayimg.viewer.open("next")
end)

swayimg.viewer.on_key("left", function()
    swayimg.viewer.open("prev")
end)

swayimg.viewer.on_key("right", function()
    swayimg.viewer.open("next")
end)

swayimg.viewer.on_key("home", function()
    swayimg.viewer.open("first")
end)

swayimg.viewer.on_key("end", function()
    swayimg.viewer.open("last")
end)

-- 缩放：+/-
swayimg.viewer.on_key("equal", function()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale * 1.25)
end)

swayimg.viewer.on_key("minus", function()
    swayimg.viewer.set_abs_scale(swayimg.viewer.scale / 1.25)
end)

-- 重置缩放：0
swayimg.viewer.on_key("0", function()
    swayimg.viewer.set_fix_scale("optimal")
end)

-- 循环切换缩放模式：Tab
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

-- 旋转：[/]
swayimg.viewer.on_key("]", function()
    swayimg.viewer.rotate(90)
end)

swayimg.viewer.on_key("[", function()
    swayimg.viewer.rotate(270)
end)

-- 模式切换与程序退出
swayimg.viewer.on_key("Return", function()
    swayimg.mode = "gallery"
end)

swayimg.viewer.on_key("q", function()
    swayimg.exit(0)
end)

swayimg.viewer.on_key("Escape", function()
    swayimg.exit(0)
end)


--------------------------------------------------------------------------------
-- 4. 画廊模式交互绑定
--------------------------------------------------------------------------------

swayimg.gallery.bind_reset()

-- 缩略图网格导航：Vim 键位
swayimg.gallery.on_key("h", function()
    swayimg.gallery.select("left")
end)

swayimg.gallery.on_key("l", function()
    swayimg.gallery.select("right")
end)

swayimg.gallery.on_key("k", function()
    swayimg.gallery.select("up")
end)

swayimg.gallery.on_key("j", function()
    swayimg.gallery.select("down")
end)

-- 方向键
swayimg.gallery.on_key("left", function()
    swayimg.gallery.select("left")
end)

swayimg.gallery.on_key("right", function()
    swayimg.gallery.select("right")
end)

swayimg.gallery.on_key("up", function()
    swayimg.gallery.select("up")
end)

swayimg.gallery.on_key("down", function()
    swayimg.gallery.select("down")
end)

-- 模式切换与程序退出
swayimg.gallery.on_key("Return", function()
    swayimg.mode = "viewer"
end)

swayimg.gallery.on_key("q", function()
    swayimg.exit(0)
end)

swayimg.gallery.on_key("Escape", function()
    swayimg.exit(0)
end)


--------------------------------------------------------------------------------
-- 5. 未绑定按键调试
--------------------------------------------------------------------------------

swayimg.viewer.on_unassigned_key(function(key)
    swayimg.text.status = "Unassigned key: " .. key
end)

swayimg.gallery.on_unassigned_key(function(key)
    swayimg.text.status = "Gallery unassigned: " .. key
end)
