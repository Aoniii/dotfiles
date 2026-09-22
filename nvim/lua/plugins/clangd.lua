return {
  -- clangd through LazyVim's lspconfig setup (no manual setup() call)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {},
      },
    },
  },

  -- Format C/C++ with cfmt (uncrustify + tab fixes), same as Zed
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "cfmt_c" },
        cpp = { "cfmt_cpp" },
      },
      formatters = {
        cfmt_c = {
          command = vim.fn.expand("~/.local/bin/cfmt"),
          args = { "C" },
          stdin = true,
        },
        cfmt_cpp = {
          command = vim.fn.expand("~/.local/bin/cfmt"),
          args = { "CPP" },
          stdin = true,
        },
      },
    },
  },
}
