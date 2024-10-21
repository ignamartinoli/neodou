vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

-- vim.g.tex_conceal = 'abdmgs'
vim.opt_local.conceallevel = 2

vim.opt_local.spell = true
vim.opt.spelllang = 'en,es,it'

vim.keymap.set('i', '<C-s>', [[<C-g>u<Esc>[s1z=`]a<C-g>u]])
vim.keymap.set('n', 'gs', function () require 'telescope.builtin'.spell_suggest() end)
