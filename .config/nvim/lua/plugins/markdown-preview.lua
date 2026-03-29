-- lua/plugins/markdown-preview.lua
return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown", "pandoc.markdown", "rmd" },

  build = function(plugin)
    -- 手动将插件路径加入 Neovim 的运行环境
    vim.opt.rtp:append(plugin.dir)

    local has_pnpm = vim.fn.executable("pnpm") == 1
    -- 现在 Neovim 认识这个函数了，可调用
    vim.fn["mkdp#util#install"](has_pnpm and "pnpm" or "npm")
  end,

  config = function()
    vim.keymap.set('n', '<leader>md', ':MarkdownPreviewToggle<CR>', { desc = 'Toggle Markdown Preview' })
  end
}
