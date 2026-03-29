-- lua/plugins/completion.lua
return {
  {
    'saghen/blink.cmp',
    -- 依赖建议：提供基础的代码片段库
    dependencies = 'rafamadriz/friendly-snippets',

    version = '*',
    opts = {
      -- 'default' 为类似 nvim-cmp 的快捷键，'super-tab' 为类似 VS Code 的逻辑
      keymap = { preset = 'super-tab' },

      appearance = {
        -- 设置图标来源（需要安装 Nerd Font）
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono'
      },

      -- 启用内置补全源
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },

    -- 可选：如果你希望在特定事件加载，或者直接交给 lazy 加载
    opts_extend = { "sources.default" }
  },
}
