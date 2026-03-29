local opt = vim.opt

-- 行号
opt.relativenumber = false
opt.number = true

-- 光标行
opt.cursorline = true

-- 防止包裹
opt.wrap = true

-- 启用鼠标
opt.mouse:append("a")

-- 系统剪切板
opt.clipboard:append("unnamedplus")

-- 启用不可见字符显示
opt.list = true
-- 自定义不可见字符的显示样式
opt.listchars = {
  tab = "» ",		-- Tab 显示为 » 加空格
  trail = "·",		-- 行尾多余的空格显示为点
  nbsp = "␣",		-- 不换行空格
  -- eol = "↵",		-- 如果你想显示换行符，取消这一行的注释
  -- space = "·",	-- 如果你想显示所有空格，取消这一行的注释
}
