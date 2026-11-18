-- Minimal init for headless tests: repo on runtimepath, no plugins.
local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))
vim.opt.rtp:prepend(root)
vim.opt.loadplugins = false
vim.opt.swapfile = false
