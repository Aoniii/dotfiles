return {
  {
    "neovim/nvim-lspconfig",
    ft = { "c", "cpp" },
    config = function()
      require("lspconfig").clangd.setup({})
    end,
  },
}
