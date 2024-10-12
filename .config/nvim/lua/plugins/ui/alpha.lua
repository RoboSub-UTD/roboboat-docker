return {
    "goolord/alpha-nvim",
    event = "VimEnter",
    cond = not vim.g.vscode,
    opts = function()
        local dashboard = require("alpha.themes.dashboard")
        local logo = [[
╔──────────────────────────────────────╗
│  _   _ _____ _____     _____ __  __  │
│ | \ | | ____/ _ \ \   / /_ _|  \/  | │
│ |  \| |  _|| | | \ \ / / | || |\/| | │
│ | |\  | |__| |_| |\ V /  | || |  | | │
│ |_| \_|_____\___/  \_/  |___|_|  |_| │
╚──────────────────────────────────────╝
          Configured with 
]]

        -- Set header
        dashboard.section.header.val = vim.split(logo, "\n")

        -- Set menu
        dashboard.section.buttons.val = {
            dashboard.button("f", "     Find file", ":cd $PWD | Telescope find_files<CR>"),
            dashboard.button("r", "     Recent", ":Telescope oldfiles<CR>"),
            dashboard.button("s", "     Settings", ":e $MYVIMRC | :cd %:p:h | pwd<CR>"),
            dashboard.button("c", "     Colorschemes", ":lua require('nvchad.themes').open()<CR>"),
            dashboard.button("l", "󰒲     Lazy Menu", ":Lazy<CR>"),
            dashboard.button("q", "󰩈     Quit NVIM", ":xit<CR>"),
        }

        return dashboard.opts
    end,
    config = function(_, opts)
        -- close Lazy and re-open when the dashboard is ready
        if vim.o.filetype == "lazy" then
            vim.cmd.close()
            vim.api.nvim_create_autocmd("User", {
                pattern = "AlphaReady",
                callback = function() require("lazy").show() end,
            })
        end

        require("alpha").setup(opts)
    end,
}
