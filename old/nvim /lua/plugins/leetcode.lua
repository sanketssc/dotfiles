return {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    lazy = false,
    
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim", -- required by telescope
      "MunifTanjim/nui.nvim",
  
      -- optional
      "nvim-treesitter/nvim-treesitter",
      "rcarriga/nvim-notify",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      -- configuration goes here
      injector = {
        ["cpp"] = {
          before = { "#include <bits/stdc++.h>", "using namespace std;" },
          -- after = "int main() {}",
        },
      },
      keys = {
        vim.keymap.set("n", "<leader>lr", "<cmd>Leet run<CR>", { desc = "LeetCode Run tests" }),
        vim.keymap.set("n", "<leader>ls", "<cmd>Leet submit<CR>", { desc = "LeetCode Submit solution" }),
        vim.keymap.set("n", "<leader>lcl", "<cmd>Leet lang<CR>", { desc = "LeetCode Change Language"})
    },
    },
    
  }