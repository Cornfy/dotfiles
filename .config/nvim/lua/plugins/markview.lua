-- lua/plugins/markview.lua
return {
  "OXY2DEV/markview.nvim",
  lazy = false,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("markview").setup({
      -- 保持多行代码块（Code Block）的背景与语言角标
      code_blocks = {
        enable = true,
      },
    })

    -- 1. 清理 1~6 级标题的整行背景条
    for i = 1, 6 do
      vim.api.nvim_set_hl(0, "MarkviewHeading" .. i .. "Bg", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "MarkviewHeading" .. i, { bg = "NONE", bold = true })
    end

    -- 2. 去掉单行/行内 `代码` 的灰色背景块，仅保留前景色高亮（避免产生参差不齐的方块）
    vim.api.nvim_set_hl(0, "MarkviewInlineCode", { bg = "NONE", fg = "#89b4fa" })

    -- 快捷键
    vim.keymap.set("n", "<leader>md", "<cmd>Markview toggle<CR>", { desc = "Toggle Markview Render" })
  end,
}
