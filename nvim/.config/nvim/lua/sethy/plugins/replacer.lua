return {
    "gabrielpoca/replacer.nvim",
    lazy = true,
    keys = {
        { "<leader>qr", function() require("replacer").run() end,  desc = "QF replacer run" },
        { "<leader>qs", function() require("replacer").save() end, desc = "QF replacer save" },
    },
}
