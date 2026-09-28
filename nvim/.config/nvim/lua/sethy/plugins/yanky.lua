return {
    "gbprod/yanky.nvim",
    event = "VeryLazy",
    opts = {
        ring = { history_length = 200 },
        highlight = { timer = 150 },
    },
    keys = {
        { "y",          "<Plug>(YankyYank)",                    mode = { "n", "x" }, desc = "Yank" },
        { "p",          "<Plug>(YankyPutAfter)",                mode = { "n", "x" }, desc = "Put after" },
        { "P",          "<Plug>(YankyPutBefore)",               mode = { "n", "x" }, desc = "Put before" },
        { "gp",         "<Plug>(YankyGPutAfter)",               mode = { "n", "x" }, desc = "GPut after" },
        { "gP",         "<Plug>(YankyGPutBefore)",              mode = { "n", "x" }, desc = "GPut before" },
        { "]p",         "<Plug>(YankyPutIndentAfterLinewise)",  desc = "Put indent after" },
        { "[p",         "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put indent before" },
        { "]y",         "<Plug>(YankyCycleForward)",            desc = "Cycle yank fwd" },
        { "[y",         "<Plug>(YankyCycleBackward)",           desc = "Cycle yank back" },
        { "<leader>yh", "<cmd>YankyRingHistory<cr>",            desc = "Yank history" },
    },
}
