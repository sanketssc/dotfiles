# Neovim Keybindings Reference

> **Leader Key**: `<space>`
> Auto-generated from config at `lua/sethy/`

---

## Table of Contents

- [Git](#git)
- [File System / File Explorer](#file-system--file-explorer)
- [Navigation / Motion](#navigation--motion)
- [Finding / Searching](#finding--searching)
- [LSP](#lsp)
- [Completion (nvim-cmp)](#completion-nvim-cmp)
- [Editing / Text Manipulation](#editing--text-manipulation)
- [Window / Split / Tab Management](#window--split--tab-management)
- [Debugging](#debugging)
- [Diagnostics / Trouble](#diagnostics--trouble)
- [Session Management](#session-management)
- [Terminal](#terminal)
- [Folding (nvim-ufo)](#folding-nvim-ufo)
- [Markdown-Specific](#markdown-specific)
- [Miscellaneous](#miscellaneous)
- [Plugin Default Keybindings (Not Customized)](#plugin-default-keybindings-not-customized)
- [Keycode Clashes](#keycode-clashes)
- [Suggested Git Plugins](#suggested-git-plugins)

---

## Git

### Fugitive (`gitstuff.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>gg` | n | Open git status (`:Git`) | gitstuff.lua |
| `<leader>P` | n (fugitive buf) | Git push | gitstuff.lua |
| `<leader>p` | n (fugitive buf) | Git pull --rebase | gitstuff.lua |
| `<leader>t` | n (fugitive buf) | Git push -u origin (set tracking) | gitstuff.lua |

### Gitsigns (`gitstuff.lua` on_attach)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `]h` | n | Next hunk | gitstuff.lua |
| `[h` | n | Previous hunk | gitstuff.lua |
| `<leader>gs` | n | Stage hunk | gitstuff.lua |
| `<leader>gs` | v | Stage selected hunk | gitstuff.lua |
| `<leader>gr` | n | Reset hunk | gitstuff.lua |
| `<leader>gr` | v | Reset selected hunk | gitstuff.lua |
| `<leader>gS` | n | Stage buffer | gitstuff.lua |
| `<leader>gR` | n | Reset buffer | gitstuff.lua |
| `<leader>gu` | n | Undo stage hunk | gitstuff.lua |
| `<leader>gp` | n | Preview hunk | gitstuff.lua |
| `<leader>gbl` | n | Blame line (full) | gitstuff.lua |
| `<leader>gB` | n | Toggle line blame | gitstuff.lua |
| `<leader>gd` | n | Diff this | gitstuff.lua |
| `<leader>gD` | n | Diff this ~ | gitstuff.lua |
| `ih` | o, x | Select hunk (text object) | gitstuff.lua |

### LazyGit (via Snacks) (`snacks.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>lg` | n | Open LazyGit | snacks.lua |
| `<leader>gl` | n | LazyGit logs | snacks.lua |

### Git Worktree (`gitworktree.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>wl` | n | List git worktrees | gitworktree.lua |
| `<leader>wc` | n | Create git worktree | gitworktree.lua |

### Git (Snacks Picker) (`snacks.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>gbr` | n | Pick and switch git branches | snacks.lua |

---

## File System / File Explorer

### Oil (`oil.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `-` | n | Open parent directory | oil.lua |
| `<leader>-` | n | Toggle oil float window | oil.lua |
| `<M-h>` | n (oil buf) | Open file in split | oil.lua (internal) |
| `q` | n (oil buf) | Close oil | oil.lua (internal) |

### Mini.Files (`mini.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>ee` | n | Open mini file explorer | mini.lua |
| `<leader>ef` | n | Open at current file location | mini.lua |

### File Operations (Core) (`keymaps.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>x` | n | Make current file executable | keymaps.lua |
| `<leader>fp` | n | Copy file path to clipboard | keymaps.lua |

### Snacks (`snacks.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>rN` | n | Fast rename current file | snacks.lua |
| `<leader>dB` | n | Delete/close buffer (confirm) | snacks.lua |

### Image (`image-support.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>pi` | n | Paste image from clipboard | image-support.lua |

---

## Navigation / Motion

### Core Navigation (`keymaps.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<C-d>` | n | Half-page down (cursor centered) | keymaps.lua |
| `<C-u>` | n | Half-page up (cursor centered) | keymaps.lua |
| `n` | n | Next search result (centered) | keymaps.lua |
| `N` | n | Previous search result (centered) | keymaps.lua |
| `J` | n | Join lines (cursor stays) | keymaps.lua |
| `;` | n | Enter command mode (alias for `:`) | keymaps.lua |

### Flash (`flash.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `zk` | n, x, o | Flash jump | flash.lua |
| `Zk` | n, x, o | Flash Treesitter jump | flash.lua |
| `r` | o | Remote Flash | flash.lua |
| `R` | o, x | Treesitter Search | flash.lua |
| `<C-s>` | c | Toggle Flash Search | flash.lua |

### Harpoon (`harpoon.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>a` | n | Add file to harpoon | harpoon.lua |
| `<C-e>` | n | Toggle harpoon quick menu | harpoon.lua |
| `<C-y>` | n | Select harpoon file 1 | harpoon.lua |
| `<C-i>` | n | Select harpoon file 2 | harpoon.lua |
| `<C-n>` | n | Select harpoon file 3 | harpoon.lua |
| `<C-s>` | n | Select harpoon file 4 | harpoon.lua |
| `<C-S-P>` | n | Previous harpoon file | harpoon.lua |
| `<C-S-N>` | n | Next harpoon file | harpoon.lua |

### Marks (`snacks.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>sm` | n | Find marks (Snacks picker) | snacks.lua |

### Todo Comments (`todo-comments.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `]t` | n | Next todo comment | todo-comments.lua |
| `[t` | n | Previous todo comment | todo-comments.lua |

### Treesitter Incremental Selection (`treesitter.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<C-space>` | n | Init/increment node selection | treesitter.lua |

---

## Finding / Searching

### Snacks Picker (`snacks.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>pf` | n | Find files | snacks.lua |
| `<leader>pc` | n | Find config file | snacks.lua |
| `<leader>ps` | n | Grep (search text) | snacks.lua |
| `<leader>pws` | n, x | Search visual selection or word | snacks.lua |
| `<leader>pk` | n | Search keymaps | snacks.lua |
| `<leader>pt` | n | All todos | snacks.lua |
| `<leader>pT` | n | Main todos (TODO/FIXME/FORGETNOT) | snacks.lua |
| `<leader>vh` | n | Help pages | snacks.lua |
| `<leader>th` | n | Pick colorschemes | snacks.lua |

### Telescope (`telescope.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>pr` | n | Fuzzy find recent files | telescope.lua |
| `<leader>pWs` | n | Find connected words under cursor | telescope.lua |
| `<leader>ths` | n | Theme switcher (Telescope) | telescope.lua |

### Telescope Insert Mode (`telescope.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<C-k>` | i (telescope) | Move to previous result | telescope.lua |
| `<C-j>` | i (telescope) | Move to next result | telescope.lua |

---

## LSP

### LSP Keybindings (`lsp/lspconfig.lua` - buffer-local on LspAttach)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `gR` | n | Show LSP references | lspconfig.lua |
| `gD` | n | Go to declaration | lspconfig.lua |
| `gd` | n | Show LSP definitions | lspconfig.lua |
| `gi` | n | Show LSP implementations | lspconfig.lua |
| `gt` | n | Show LSP type definitions | lspconfig.lua |
| `<leader>vca` | n, v | Code actions | lspconfig.lua |
| `<leader>rn` | n | Smart rename | lspconfig.lua |
| `<leader>D` | n | Buffer diagnostics | lspconfig.lua |
| `<leader>d` | n | Line diagnostics | lspconfig.lua |
| `K` | n | Hover documentation | lspconfig.lua |
| `<leader>rs` | n | Restart LSP | lspconfig.lua |
| `<C-h>` | i | Signature help | lspconfig.lua |

---

## Completion (nvim-cmp)

### (`nvim-cmp.lua` - active in insert/snippet mode)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<C-j>` | i, s | Select next completion item | nvim-cmp.lua |
| `<C-k>` | i, s | Select previous completion item | nvim-cmp.lua |
| `<C-n>` | i, s | Select next item | nvim-cmp.lua |
| `<C-p>` | i, s | Select previous item | nvim-cmp.lua |
| `<Down>` | i, s | Select next item | nvim-cmp.lua |
| `<Up>` | i, s | Select previous item | nvim-cmp.lua |
| `<C-y>` | i, s | Confirm completion | nvim-cmp.lua |
| `<CR>` | i, s | Confirm completion | nvim-cmp.lua |
| `<C-e>` | i, s | Close completion window | nvim-cmp.lua |
| `<C-d>` | i, s | Close docs | nvim-cmp.lua |
| `<C-f>` | i, s | Scroll docs down | nvim-cmp.lua |
| `<C-b>` | i, s | Scroll docs up | nvim-cmp.lua |
| `<Tab>` | i, s | Next item / expand snippet / complete | nvim-cmp.lua |
| `<S-Tab>` | i, s | Previous item / unindent / jump snippet | nvim-cmp.lua |

---

## Editing / Text Manipulation

### Core (`keymaps.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>J` | v | Move selected lines down | keymaps.lua |
| `<leader>K` | v | Move selected lines up | keymaps.lua |
| `<` | v | Decrease indent (stays in visual) | keymaps.lua |
| `>` | v | Increase indent (stays in visual) | keymaps.lua |
| `<leader>p` | x | Paste without yanking replaced text | keymaps.lua |
| `p` | v | Paste without yanking replaced text | keymaps.lua |
| `<leader>Y` | n | Yank to system clipboard | keymaps.lua |
| `<leader>d` | n, v | Delete without affecting register | keymaps.lua |
| `x` | n | Delete char without affecting register | keymaps.lua |
| `<C-c>` | i | Escape insert mode | keymaps.lua |
| `<C-c>` | n | Clear search highlighting | keymaps.lua |
| `Q` | n | Disabled (no-op) | keymaps.lua |
| `<leader>s` | n | Replace word under cursor globally | keymaps.lua |

### Mini.Surround (`mini.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `sa` | n, v | Add surrounding | mini.lua |
| `ds` | n | Delete surrounding | mini.lua |
| `sr` | n | Replace surrounding | mini.lua |
| `sf` | n | Find surrounding (right) | mini.lua |
| `sF` | n | Find surrounding (left) | mini.lua |
| `sh` | n | Highlight surrounding | mini.lua |
| `sn` | n | Update n_lines | mini.lua |

### Mini.SplitJoin (`mini.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `sj` | n, x | Join arguments | mini.lua |
| `sk` | n, x | Split arguments | mini.lua |

### Mini.Trailspace (`mini.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>cw` | n | Erase trailing whitespace | mini.lua |

### Formatting (`formatting.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>mp` | n, v | Format file or selection | formatting.lua |
| `<leader>f` | n | Format file via LSP | keymaps.lua |

### Linting (`linting.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>l` | n | Trigger linting | linting.lua |

### Emmet (`emmet.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>xe` | n, v | Wrap with abbreviation | emmet.lua |

---

## Window / Split / Tab Management

### Splits (`keymaps.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>sv` | n | Split window vertically | keymaps.lua |
| `<leader>sh` | n | Split window horizontally | keymaps.lua |
| `<leader>se` | n | Make splits equal size | keymaps.lua |
| `<leader>sx` | n | Close current split | keymaps.lua |

### Tabs (`keymaps.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>to` | n | Open new tab | keymaps.lua |
| `<leader>tx` | n | Close current tab | keymaps.lua |
| `<leader>tn` | n | Go to next tab | keymaps.lua |
| `<leader>tp` | n | Go to previous tab | keymaps.lua |
| `<leader>tf` | n | Open current file in new tab | keymaps.lua |

### Vim-Maximizer (`vim-maximizer.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>sm` | n | Maximize/minimize split | vim-maximizer.lua |

---

## Debugging

### (`debugging.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<Leader>db` | n | Toggle breakpoint | debugging.lua |
| `<Leader>dc` | n | Continue debugging | debugging.lua |

---

## Diagnostics / Trouble

### Trouble (`trouble.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>xw` | n | Workspace diagnostics | trouble.lua |
| `<leader>xd` | n | Document diagnostics | trouble.lua |
| `<leader>xq` | n | Quickfix list | trouble.lua |
| `<leader>xl` | n | Location list | trouble.lua |
| `<leader>xt` | n | Todos in trouble | trouble.lua |

### LSP Diagnostics Toggle (`keymaps.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>lx` | n | Toggle LSP diagnostics visibility | keymaps.lua |

---

## Session Management

### Auto-Session (`auto-session.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>wr` | n | Restore session for cwd | auto-session.lua |
| `<leader>ws` | n | Save session for cwd | auto-session.lua |

---

## Terminal

### Terminal Popup (`terminalpop.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<space>c/` | n, t | Toggle floating terminal | terminalpop.lua |
| `<esc><esc>` | t | Exit terminal mode | terminalpop.lua |

---

## Folding (nvim-ufo)

### (`nvim-ufo.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `zR` | n | Open all folds | nvim-ufo.lua |
| `zM` | n | Close all folds | nvim-ufo.lua |

---

## Undotree

### (`undotree.lua`)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<leader>u` | n | Toggle undotree | undotree.lua |

---

## Markdown-Specific

### (`after/ftplugin/markdown.lua` - buffer-local)

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `tn` | n, v | Toggle numbers on line(s) | markdown.lua |
| `tb` | n, v | Toggle bullets on line(s) | markdown.lua |
| `tc` | n, v | Toggle checkboxes on line(s) | markdown.lua |
| `tt` | n, v | Toggle task state on line(s) | markdown.lua |
| `tl` | n, v | Smart list toggle on line(s) | markdown.lua |
| `<leader>tc` | n | Mark all tasks as done | markdown.lua |
| `<leader>tu` | n | Mark all tasks as undone | markdown.lua |

---

## Miscellaneous

| Key | Mode | Action | Source |
|-----|------|--------|--------|
| `<C-f>` | n | Open tmux-sessionizer | keymaps.lua |

---

## Plugin Default Keybindings (Not Customized)

These are notable default keybindings from plugins that are NOT overridden in config:

### Gitsigns Defaults (active unless overridden)
| Key | Action |
|-----|--------|
| `]c` | Next change (diff mode) |
| `[c` | Previous change (diff mode) |

### Flash Defaults
| Key | Action |
|-----|--------|
| `f/F/t/T` | Enhanced with Flash labels |

### Mini.Surround Defaults (customized - see above)
Original defaults would be `gz` prefix but config changes them to `s` prefix.

### Marks.nvim Defaults
| Key | Action |
|-----|--------|
| `mx` | Set mark x |
| `m,` | Set next available mark |
| `m;` | Toggle next available mark |
| `dmx` | Delete mark x |
| `dm-` | Delete all marks on line |
| `dm<space>` | Delete all marks in buffer |
| `m]` | Move to next mark |
| `m[` | Move to previous mark |
| `m:` | Preview mark |

### Nvim-Autopairs Defaults
| Key | Action |
|-----|--------|
| `(`, `[`, `{`, `"`, `'` | Auto-close pair |
| `)`, `]`, `}` | Skip over closing pair |
| `<BS>` | Delete pair |

---

## Keycode Clashes

### CONFIRMED CLASHES (Same mode, same key, both active)

| Key | Mode | Mapping 1 | Mapping 2 | Severity |
|-----|------|-----------|-----------|----------|
| `<leader>sm` | n | **Snacks**: Find marks | **Vim-Maximizer**: Maximize/minimize split | **HIGH** - Both active in normal mode. One will shadow the other. |
| `<leader>d` | n | **Core**: Delete without affecting register | **LSP** (buffer-local): Show line diagnostics | **HIGH** - LSP buffer-local mapping will override core mapping in LSP-attached buffers. |

### POTENTIAL CLASHES (Different modes or contexts, but worth noting)

| Key | Mode | Mapping 1 | Mapping 2 | Note |
|-----|------|-----------|-----------|------|
| `<C-i>` | n | **Harpoon**: Select file 2 | **Vim built-in**: Jump forward in jumplist (`<C-i>` = `<Tab>` internally) | **HIGH** - You lose the built-in jumplist forward navigation. `<C-i>` and `<Tab>` are the same keycode in terminals. |
| `<C-s>` | n / c | **Harpoon**: Select file 4 (n) | **Flash**: Toggle flash search (c) | LOW - Different modes. |
| `<C-e>` | n / i | **Harpoon**: Toggle menu (n) | **nvim-cmp**: Close completion (i) | LOW - Different modes. Also overrides Vim's built-in scroll-down-one-line. |
| `<C-n>` | n / i | **Harpoon**: Select file 3 (n) | **nvim-cmp**: Next item (i) | LOW - Different modes. Also overrides Vim's built-in completion. |
| `<C-y>` | n / i | **Harpoon**: Select file 1 (n) | **nvim-cmp**: Confirm (i) | LOW - Different modes. Also overrides Vim's built-in scroll-up-one-line. |
| `<C-f>` | n / i | **Core**: tmux-sessionizer (n) | **nvim-cmp**: Scroll docs (i) | LOW - Different modes. Overrides Vim's built-in page-forward. |
| `<C-d>` | n / i | **Core**: Half-page down (n) | **nvim-cmp**: Close docs (i) | LOW - Different modes. |
| `<leader>p` | x / n | **Core**: Paste no-yank (x) | **Snacks**: `<leader>pf`, `<leader>ps`, etc. (n) | LOW - Different modes, and Snacks uses longer combos. |
| `<leader>f` | n | **Core**: Format via LSP | **Snacks**: Prefix for potential future `<leader>f*` mappings | LOW - Currently no conflict, but `<leader>f` causes timeout delay before `<leader>fp`. |
| `<leader>x` | n | **Core**: Make file executable | **Trouble**: `<leader>xw`, `<leader>xd`, etc. | **MEDIUM** - `<leader>x` will cause a timeout delay. Neovim waits to see if you'll press `w`/`d`/etc. |
| `gt` | n | **LSP**: Type definitions | **Vim built-in**: Go to next tab | **MEDIUM** - Overrides Vim's built-in tab navigation in LSP buffers. |
| `<leader>ee`/`<leader>ef` | n | **Mini.Files** | **Nvim-Tree** (disabled) | NONE - nvim-tree is disabled, no actual conflict. |
| `<leader>lg` | n | **Snacks**: LazyGit | **Gitstuff**: LazyGit (disabled) | NONE - gitstuff lazygit is disabled. |

### OVERRIDDEN VIM BUILT-INS (Worth knowing)

| Key | Built-in Action | Your Mapping |
|-----|-----------------|--------------|
| `<C-i>` | Jump forward in jumplist | Harpoon file 2 |
| `<C-e>` | Scroll window down one line | Harpoon menu |
| `<C-y>` | Scroll window up one line | Harpoon file 1 / cmp confirm |
| `<C-n>` | Next match (built-in completion) | Harpoon file 3 / cmp next |
| `<C-f>` | Page forward | tmux-sessionizer |
| `gt` | Go to next tab | LSP type definitions |
| `J` | Join lines (cursor moves) | Join lines (cursor stays) - improved |
| `n`/`N` | Next/prev search result | Same but centered - improved |
| `Q` | Ex mode | Disabled |
| `x` | Delete char into register | Delete char into black hole register |

---

## Suggested Git Plugins

### Already Installed

- **vim-fugitive** - Git commands (`:Git`, `:Gblame`, etc.)
- **gitsigns.nvim** - Git gutter signs, hunk staging, blame
- **lazygit** (via snacks.nvim) - Terminal UI for git
- **git-worktree.nvim** - Worktree management

### Recommended Additions

#### 1. diffview.nvim
> **What**: Tabbed diff viewer with file history. Side-by-side diffs for any ref, merge conflicts, and full file history browser.
>
> **Why**: Fugitive's diff is single-file. Diffview gives you a full project-wide diff view with a file panel, similar to VS Code's source control panel.
>
> **Repo**: `sindrets/diffview.nvim`
>
> ```lua
> {
>   "sindrets/diffview.nvim",
>   cmd = { "DiffviewOpen", "DiffviewFileHistory" },
>   keys = {
>     { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
>     { "<leader>gdh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
>     { "<leader>gdH", "<cmd>DiffviewFileHistory<cr>", desc = "Branch History" },
>     { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
>   },
> }
> ```

#### 2. neogit
> **What**: Magit-inspired interactive git interface inside Neovim. Staging, committing, rebasing, cherry-picking all from a buffer.
>
> **Why**: More Neovim-native than LazyGit. Great if you want to stay inside Neovim for all git operations. Works well alongside fugitive.
>
> **Repo**: `NeogitOrg/neogit`
>
> ```lua
> {
>   "NeogitOrg/neogit",
>   dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
>   cmd = "Neogit",
>   keys = {
>     { "<leader>gn", "<cmd>Neogit<cr>", desc = "Neogit" },
>   },
>   opts = {
>     integrations = { diffview = true },
>   },
> }
> ```

#### 3. git-conflict.nvim
> **What**: Highlights git conflict markers and provides keymaps to resolve them (choose ours/theirs/both/none).
>
> **Why**: Much faster conflict resolution than manually editing markers. Visual highlights make conflicts impossible to miss.
>
> **Repo**: `akinsho/git-conflict.nvim`
>
> ```lua
> {
>   "akinsho/git-conflict.nvim",
>   version = "*",
>   event = "BufReadPre",
>   opts = {},
>   -- Default keys: co (choose ours), ct (choose theirs),
>   -- cb (choose both), c0 (choose none), ]x/[x (next/prev conflict)
> }
> ```

#### 4. gitlinker.nvim
> **What**: Generate shareable git permalinks (GitHub/GitLab/Bitbucket URLs) for the current line or selection.
>
> **Why**: Extremely useful for code reviews, sharing specific lines in Slack/PRs, or linking to code in documentation.
>
> **Repo**: `linrongbin16/gitlinker.nvim`
>
> ```lua
> {
>   "linrongbin16/gitlinker.nvim",
>   cmd = "GitLink",
>   keys = {
>     { "<leader>gy", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Copy git permalink" },
>     { "<leader>gY", "<cmd>GitLink!<cr>", mode = { "n", "v" }, desc = "Open git permalink in browser" },
>   },
>   opts = {},
> }
> ```

#### 5. octo.nvim
> **What**: Review GitHub PRs, manage issues, and browse repos entirely from within Neovim.
>
> **Why**: If you work heavily with GitHub PRs, this lets you review, comment, approve, and merge without leaving Neovim.
>
> **Repo**: `pwntester/octo.nvim`
>
> ```lua
> {
>   "pwntester/octo.nvim",
>   cmd = "Octo",
>   dependencies = {
>     "nvim-lua/plenary.nvim",
>     "nvim-telescope/telescope.nvim",
>     "nvim-tree/nvim-web-devicons",
>   },
>   opts = {},
> }
> ```

### Quick Comparison

| Plugin | Best For | Already Have Alternative? |
|--------|----------|--------------------------|
| **diffview.nvim** | Project-wide diffs, file history | Fugitive (single-file diffs) |
| **neogit** | Full git workflow in Neovim | LazyGit (terminal-based) |
| **git-conflict.nvim** | Merge conflict resolution | Nothing - **highly recommended** |
| **gitlinker.nvim** | Sharing code links | Nothing - very useful |
| **octo.nvim** | GitHub PR reviews in Neovim | Nothing - useful if heavy GH user |

**Top pick**: `diffview.nvim` + `git-conflict.nvim` would complement your existing setup the most without overlap.

---

## All Plugins (Status Overview)

| Plugin | Purpose | Status |
|--------|---------|--------|
| lazy.nvim | Plugin manager | Active |
| telescope.nvim | Fuzzy finder | Active |
| flash.nvim | Motion/jump | Active |
| harpoon | File navigation | Active |
| trouble.nvim | Diagnostics UI | Active |
| oil.nvim | File explorer | Active |
| nvim-tree | File explorer | **Disabled** |
| undotree | Undo history | Active |
| vim-fugitive | Git commands | Active |
| gitsigns.nvim | Git gutter | Active |
| lazygit (snacks) | Git TUI | Active |
| git-worktree.nvim | Worktree mgmt | Active |
| nvim-dap | Debugging | Active |
| todo-comments.nvim | TODO highlights | Active |
| snacks.nvim | UI/Utils | Active |
| mini.nvim | Various utils | Active |
| vim-maximizer | Window maximize | Active |
| marks.nvim | Mark management | Active |
| conform.nvim | Formatting | Active |
| nvim-lint | Linting | Active |
| nvim-emmet | HTML expansion | Active |
| treesitter | Syntax/parsing | Active |
| nvim-autopairs | Auto brackets | Active |
| nvim-surround | Surround editing | **Disabled** |
| showkeys.nvim | Key display | Active |
| auto-session | Session mgmt | Active |
| render-markdown | MD rendering | Active |
| nvim-ufo | Code folding | Active |
| tailwindcss-colorizer | CSS colors | Active |
| img-clip.nvim | Image paste | Active |
| wilder.nvim | Cmd completion | Active |
| noice.nvim | UI enhancement | Active |
| incline.nvim | Floating filename | Active |
| lualine.nvim | Statusline | Active |
| nvim-lspconfig | LSP config | Active |
| mason.nvim | LSP installer | Active |
| nvim-cmp | Completion | Active |
| luasnip | Snippets | Active |
