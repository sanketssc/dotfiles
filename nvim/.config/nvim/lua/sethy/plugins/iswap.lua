return {
    "mizlan/iswap.nvim",
    keys = {
        { "gw",         ":ISwapWithRight<cr>", desc = "Swap arg right" },
        { "gW",         ":ISwapWithLeft<cr>",  desc = "Swap arg left" },
        { "<leader>is", ":ISwap<cr>",          desc = "Pick swap" },
        { "<leader>iS", ":ISwapNode<cr>",      desc = "Pick swap node" },
    },
    opts = {
        keys = "asdfghjkl;",
        autoswap = true,
    },
}
