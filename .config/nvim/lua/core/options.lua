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
