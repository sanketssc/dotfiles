return {
    "folke/sidekick.nvim",
    opts = {
        cli = { mux = { backend = "tmux", enabled = false } },
    },
    keys = {
        {
            "<tab>",
            function()
                if not require("sidekick").nes_jump_or_apply() then
                    return "<Tab>"
                end
            end,
            expr = true,
            desc = "NES jump/apply",
        },
        { "<leader>aa", function() require("sidekick.cli").toggle() end,        desc = "Sidekick CLI" },
        { "<leader>ap", function() require("sidekick.cli").select_prompt() end, desc = "Sidekick prompt" },
    },
}
