vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

vim.opt_local.conceallevel = 2

vim.opt_local.spell = true
vim.opt.spelllang = 'en,es,it'

vim.keymap.set('n', 'gs', function () require 'telescope.builtin'.spell_suggest() end)
