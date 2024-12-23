return {
  "nvim-telescope/telescope.nvim",
  lazy = false,
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- treesitter
    "nvim-lua/plenary.nvim", -- collection of lua functions
    "BurntSushi/ripgrep", -- regex pattern search tool
    "nvim-tree/nvim-web-devicons", -- icons
    "sharkdp/fd", -- find alternative
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- native fuzzy finding via fzf
  },
  config = function()
    local telescope = require("telescope")
    local themes = require("telescope.themes")
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")
    -- modify dropdown theme
    telescope.setup({
      defaults = {
        -- KEYMAPS (in attached telescope buffers) --
        mappings = {
          i = {
          -- insert mode
            ["<C-h>"] = "which_key"
          },
          n = {
          -- normal mode
          },
        }
      },
      pickers = {
        find_files = {
          theme = "dropdown",
        },
        git_files = {
          theme = "dropdown", 
        },
        grep_string = {
          theme = "dropdown", 
        },
        live_grep = {
          theme = "dropdown", 
        },
        buffers = {
          theme = "dropdown", 
        },
        help_tags = {
          theme = "dropdown", 
        },
        man_pages = {
          theme = "dropdown", 
        },
        quickfix = {
          theme = "dropdown", 
        },
        current_buffer_fuzzy_find = {
          theme = "dropdown",
        }
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        }
      },
    })
    telescope.load_extension("fzf")
    -- KEYMAPS --
    -- file pickers
    KEYMAP("n", "<leader>ff", builtin.find_files, keymap_opts("telescope: find files in cwd"), bufnr) -- fuzzy find CWD
    KEYMAP("n", "<leader>fg", builtin.git_files, keymap_opts("telescope: find git files in cwd"), bufnr) -- fuzzy find git files in CWD (output of git ls-files)
    KEYMAP("n", "<leader>fs", builtin.grep_string, keymap_opts("telescope: grep selected string in cwd"), bufnr) -- search CWD for string under cursor
    KEYMAP("n", "<leader>fl", builtin.live_grep, keymap_opts("telescope: live grep in cwd"), bufnr) -- search CWD for a string and live preview results
    -- vim pickers
    KEYMAP("n", "<leader>fb", builtin.buffers, keymap_opts("telescope: list open buffers")) -- list open buffers
    KEYMAP("n", "<leader>fc", builtin.commands, keymap_opts("telescope: list editor commands")) -- list editor commands
    KEYMAP("n", "<leader>fh", builtin.help_tags, keymap_opts("telescope: list help tags")) -- list help tags
    KEYMAP("n", "<leader>fm", builtin.man_pages, keymap_opts("telescope: list man pages")) -- list man pages
    KEYMAP("n", "<leader>fq", builtin.quickfix, keymap_opts("telescope: search quickfix list")) -- search items in quickfix list
    KEYMAP("n", "<leader>fo", builtin.vim_options, keymap_opts("telescope: list vim options")) -- list vim options
    KEYMAP("n", "<leader>fa", builtin.autocommands, keymap_opts("telescope: list autocmds")) -- list autocmds
    KEYMAP("n", "<leader>fk", builtin.keymaps, keymap_opts("telescope: list keymaps (normal mode)")) -- list keymaps
    KEYMAP("n", "<leader>fhi", builtin.highlights, keymap_opts("telescope: list highlight groups")) -- list highlight groups
    KEYMAP("n", "<leader>fbo", builtin.current_buffer_fuzzy_find, keymap_opts("telescope: search inside currently opened bufffer")) -- search inside currently opened buffer
    -- lsp pickers 
    KEYMAP("n", "<leader>fd", builtin.diagnostics, keymap_opts("telescope: list diagnostics for open buffers")) -- list lsp diagnostics for open buffers
    KEYMAP("n", "<leader>fr", builtin.lsp_references, keymap_opts("telescope: list lsp references for word under cursor")) -- list lsp references for word under cursor
    KEYMAP("n", "<leader>fi", builtin.lsp_implementations, keymap_opts("telescope: list lsp implementations for word under cursor")) -- list lsp implementations for word under cursor
    KEYMAP("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" }) -- list todo comments
    -- KEYMAP("n", "<leader>f?", builtin.definitions, keymap_opts("telescope: goto definition of word under cursor")) -- goto definition of word under cursor
    KEYMAP("n", "<leader>ft?", builtin.lsp_type_definitions, keymap_opts("telescope: goto type definition of word under cursor")) -- goto type definition of word under cursor
    -- git pickers 
    KEYMAP("n", "<leader>fgc", builtin.git_commits, keymap_opts("telescope: list git commits")) -- list git commits
    KEYMAP("n", "<leader>fgs", builtin.git_status, keymap_opts("telescope: list current git changes per file with diff preview")) -- list current git changes per file with diff preview
    KEYMAP("n", "<leader>fgt", builtin.git_stash, keymap_opts("telescope: list git tracked stash items")) -- list current git changes per file with diff preview
    -- treesitter pickers
    KEYMAP("n", "<leader>fts", builtin.treesitter, keymap_opts("telescope: list function names & variables exposed by treesitter")) -- list function names & variables exposed by treesitter
  end
}
