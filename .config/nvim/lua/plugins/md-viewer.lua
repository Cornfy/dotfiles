return {
  "Cornfy/md-viewer",
  ft = { "markdown" },
  cmd = { "MdViewerToggle", "MdViewerStart", "MdViewerStop" },
  keys = {
    { "<leader>md", "<cmd>MdViewerToggle<cr>", desc = "Toggle Markdown Preview" },
  },
  opts = {
    debounce_ms = 50, -- Debounce rate for typing preview (ms)
    throttle_ms = 16, -- Throttle rate for cursor sync scroll (60fps)
  },
  config = function(_, opts)
    require("md-viewer").setup(opts)
  end,
}
