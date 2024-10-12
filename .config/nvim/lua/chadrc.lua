local M = {}

M.base46 = {
    theme = "rosepine",
    theme_toggle = { "rosepine", "rosepine-dawn" },
    integrations = { "dap" },
}

M.lsp = {
    signature = true,
}

M.ui = {
    statusline = {
        theme = "minimal",
        separator_style = "round",
    },
    telescope = { style = "bordered" },
    tabufline = {
        lazyload = true,
        order = { "treeOffset", "buffers", "tabs", "btns" },
        modules = nil,
    },
}

return M
