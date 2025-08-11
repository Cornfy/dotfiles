return {
  'iamcco/markdown-preview.nvim',

  ft = {'markdown', 'pandoc.markdown', 'rmd'},

  -- 这是 config 函数，它在插件加载后执行
  config = function()
    -- 确保 Node.js 和 pnpm/npm 可执行。
    -- 这个检查应该在 mkdp#util#install() 之前。
    local has_pnpm = vim.fn.executable('pnpm') == 1
    local has_npm = vim.fn.executable('npm') == 1

    -- 插件首次加载时自动检查并安装依赖（如果需要）
    -- mkdp#util#install() 会检查 ~/.local/share/nvim/lazy/markdown-preview.nvim/node_modules
    -- 如果不存在或不完整，它会触发安装
    if has_pnpm or has_npm then
        -- 调用插件自带的安装函数。如果已安装，它会快速跳过。
        -- 默认优先使用 yarn，然后 npm。如果你想强制 pnpm，可以传参。
        vim.fn['mkdp#util#install'](has_pnpm and 'pnpm' or 'npm')
    else
        vim.notify("Error: Neither pnpm nor npm found. Cannot install markdown-preview.nvim dependencies.", vim.log.levels.ERROR)
    end

    -- 设置快捷键 (使用你设置的 <leader> 键。默认为 \ 键。)
    -- 我设置为依次按下 <leader>md 切换 markdown 预览。
    vim.keymap.set('n', '<leader>md', ':MarkdownPreviewToggle<CR>', { desc = 'Toggle Markdown Preview' })

    -- 额外添加一个更明确的安装快捷键，以防万一。
    vim.keymap.set('n', '<leader>mi', ":call mkdp#util#install('pnpm')<CR>", { desc = 'Install Markdown Preview Deps (pnpm)' })
  end
}
