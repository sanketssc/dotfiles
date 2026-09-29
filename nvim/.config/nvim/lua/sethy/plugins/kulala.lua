vim.filetype.add({ extension = { http = "http" } })

return {
    -- mistweaverco/kulala.nvim went private (Sep 2026). This recovery copy still carries upstream's
    -- history; pinned to the exact upstream commit we ran before (pure Lua + system curl, no
    -- kulala-core binary). Don't unpin: its newer commits fetch a rebuilt binary from a third party.
    "andycowan/kulala.nvim",
    commit = "6656c9d332735ca6a27725e0fb45a1715c4372d9",
    ft = { "http", "rest" },
    keys = {
        { "<leader>oh", function() require("kulala").scratchpad() end,              desc = "HTTP scratchpad" },
        { "<leader>hs", function() require("kulala").run() end,                     desc = "Send req",        ft = "http" },
        { "<leader>hr", function() require("kulala").replay() end,                  desc = "Replay",          ft = "http" },
        { "<leader>hn", function() require("kulala").jump_next() end,               desc = "Next req",        ft = "http" },
        { "<leader>hp", function() require("kulala").jump_prev() end,               desc = "Prev req",        ft = "http" },
        { "<leader>hc", function() require("kulala").copy() end,                    desc = "Copy as cURL",    ft = "http" },
        { "<leader>hC", function() require("kulala").from_curl() end,               desc = "Paste from curl", ft = "http" },
        { "<leader>hi", function() require("kulala").inspect() end,                 desc = "Inspect",         ft = "http" },
        { "<leader>ht", function() require("kulala").toggle_view() end,             desc = "Toggle view",     ft = "http" },
        { "<leader>hg", function() require("kulala").download_graphql_schema() end, desc = "GraphQL schema",  ft = "http" },
        { "<leader>hS", function() require("kulala").show_stats() end,              desc = "Stats",           ft = "http" },
        { "<leader>hq", function() require("kulala").close() end,                   desc = "Close",           ft = "http" },
    },
    opts = {},
}
