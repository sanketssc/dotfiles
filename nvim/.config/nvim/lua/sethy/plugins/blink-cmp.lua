return {
    {
        "saghen/blink.cmp",
        version = "1.*",
        event = "InsertEnter",
        dependencies = {
            "rafamadriz/friendly-snippets",
            "Kaiser-Yang/blink-cmp-git",
            "L3MON4D3/LuaSnip",
        },
        opts = {
            keymap = {
                preset = "default",
                ["<C-y>"] = { "select_and_accept" },
                ["<CR>"] = { "select_and_accept", "fallback" },
                ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                ["<C-j>"] = { "select_next", "fallback" },
                ["<C-k>"] = { "select_prev", "fallback" }, ["<C-n>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<C-f>"] = { "scroll_documentation_down", "fallback" },
                ["<C-b>"] = { "scroll_documentation_up", "fallback" },
                ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
            },
            appearance = { nerd_font_variant = "mono" },
            snippets = { preset = "luasnip" },
            sources = {
                default = { "lsp", "path", "snippets", "buffer", "lazydev", "git" },
                providers = {
                    lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
                    git = {
                        module = "blink-cmp-git",
                        name = "Git",
                        opts = { commit = { triggers = {} } },
                    },
                },
            },
            completion = {
                accept = { auto_brackets = { enabled = true } },
                documentation = { auto_show = true, auto_show_delay_ms = 50 },
                ghost_text = { enabled = true },
                menu = { border = "rounded" },
            },
            fuzzy = { implementation = "prefer_rust" },
        },
        opts_extend = { "sources.default" },
    },
    -- { "hrsh7th/nvim-cmp", enabled = false },
}
