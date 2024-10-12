return {
    {
        "williamboman/mason.nvim",
        cond = not vim.g.vscode,
        opts = {
            ui = { order = "rounded" },
            -- linters, debuggers, etc...
            ensure_installed = {
                "black",
                "codelldb",
                "eslint_d",
                "glow",
                "isort",
                "prettierd",
                "stylua",
            },
        },
        -- see https://www.lazyvim.org/plugins/lsp#masonnvim-1
        config = function(_, opts)
            require("mason").setup(opts)
            local registry = require("mason-registry")

            local function ensure_installed()
                for _, tool in ipairs(opts.ensure_installed) do
                    local package = registry.get_package(tool)
                    if not package:is_installed() then
                        package:install()
                    end
                end
            end

            -- install packages if they haven't already been installed
            if registry.refresh then
                registry.refresh(ensure_installed)
            else
                ensure_installed()
            end
        end,
    },
    {
        "neovim/nvim-lspconfig",
        cond = not vim.g.vscode,
        lazy = false,
        cmd = "LspInfo",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            {
                "folke/lazydev.nvim",
                ft = "lua",
                opts = {
                    library = {
                        { path = "luvit-meta/library", words = { "vim%.uv" } },
                        { path = "LazyVim", words = { "LazyVim" } },
                        { path = "wezterm-types", mods = { "wezterm" } },
                    },
                },
            },
        },
        config = function()
            -- define border style
            local border_opts = { border = "rounded" }
            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, border_opts)
            vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, border_opts)
            vim.diagnostic.config({ float = border_opts })

            -- define lsp icons
            local icons = { Error = "", Warn = "", Hint = "󰌵", Info = "" }

            for type, icon in pairs(icons) do
                local highlight = "DiagnosticSign" .. type
                vim.fn.sign_define(highlight, { text = icon, texthl = highlight, numhl = highlight })
            end

            -- map only after lsp has attached
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(event)
                    local mapd = function(mode, binding, action, desc)
                        vim.keymap.set(mode, binding, action, { buffer = event.buf, desc = "LSP: " .. desc })
                    end

                    -- Enable completion triggered by <C-x><C-o>
                    vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                    local builtin = require("telescope.builtin")
                    mapd("n", "gd", builtin.lsp_definitions, "[G]o to [D]efinition")
                    mapd("n", "gi", builtin.lsp_implementations, "[G]o to [I]mplementation")
                    mapd("n", "gr", builtin.lsp_references, "[G]o to [R]eferences")
                    mapd("n", "gD", vim.lsp.buf.declaration, "[G]o to [D]eclaration")
                    mapd("n", "K", vim.lsp.buf.hover, "Hover")
                    mapd({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
                    mapd("i", "<C-k>", vim.lsp.buf.signature_help, "[H]elp")
                    mapd("n", "<leader>rn", function() require("nvchad.lsp.renamer")() end, "[R]e[N]ame")

                    vim.lsp.inlay_hint.enable(true) -- inlay hints by default
                    mapd(
                        "n",
                        "<leader>ci",
                        function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({})) end,
                        "[C]ode [I]nlay Hint Toggle"
                    )

                    vim.keymap.set(
                        "n",
                        "<leader>ss",
                        function() vim.cmd.Telescope("lsp_document_symbols") end,
                        { desc = "[S]earch LSP [S]ymbols" }
                    )
                end,
            })
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim", -- Optional
        cond = not vim.g.vscode,
        event = { "BufReadPre", "BufNewFile", "InsertEnter" },
        keys = {
            { "<leader>m", vim.cmd.Mason, desc = "[M]ason" },
        },
        opts = {
            ensure_installed = {
                "bashls",
                "clangd",
                "dockerls",
                "docker_compose_language_service",
                "jedi_language_server",
                "jsonls",
                "lua_ls",
                "marksman",
            },
        },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "p00f/clangd_extensions.nvim",
        },
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            local lspconfig_util = require("lspconfig/util")

            local default_setup = function(server)
                lspconfig[server].setup({ capabilities = require("cmp_nvim_lsp").default_capabilities() })
            end

            local mason_lspconfig = require("mason-lspconfig")
            mason_lspconfig.setup(vim.tbl_extend("keep", opts, {
                handlers = {
                    -- auto-setup lsps
                    default_setup,

                    clangd = function()
                        lspconfig.clangd.setup({
                            on_attach = function(_, _)
                                require("clangd_extensions.inlay_hints").setup_autocmd()
                                require("clangd_extensions.inlay_hints").set_inlay_hints()
                            end,
                        })
                    end,

                    jsonls = function()
                        lspconfig.jsonls.setup({
                            init_options = {
                                provideFormatter = false,
                            },
                        })
                    end,

                    lua_ls = function()
                        lspconfig.lua_ls.setup({
                            Lua = {
                                format = {
                                    enable = false,
                                },
                            },
                        })
                    end,
                },
            }))
        end,
    },
}
