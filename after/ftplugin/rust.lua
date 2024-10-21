vim.opt.expandtab = false
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

vim.api.nvim_create_autocmd('BufWritePre', {
	callback = function() vim.lsp.buf.format() end
})
