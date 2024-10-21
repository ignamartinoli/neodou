-------------
-- Options --
-------------

-- Editing
vim.opt.syntax = 'on'

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Behaviour
vim.opt.clipboard = 'unnamedplus'
vim.opt.fsync = true
vim.opt.mouse = 'a'
vim.opt.swapfile = false
vim.opt.updatetime = 250

-- UI
vim.cmd.aunmenu 'PopUp.How-to\\ disable\\ mouse'
vim.cmd.aunmenu 'PopUp.-1-'

vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.showmode = false
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true

--------------
-- Mappings --
--------------

-- Delete word
-- vim.keymap.set('i', '<C-BS>', [[<C-W>]])
vim.keymap.set('i', '<C-Del>', [[<C-o>dw]])

-- Buffers
vim.keymap.set('n', '<BS>', [[:bd<CR>]], { silent = true }) -- TODO: bdelete! %d
vim.keymap.set('n', '<Tab>', [[:bnext<CR>]], { silent = true })
vim.keymap.set('n', '<S-Tab>', [[:bprevious<CR>]], { silent = true })

-- Soft undo
vim.keymap.set('i', ',', [[,<C-g>u]])

-- Saving
vim.keymap.set('n', '<C-s>', [[:w<CR>]], { silent = true })
vim.keymap.set('n', '<C-x>', [[:q!<CR>]], { silent = true }) -- TODO: plugin

-- Searching
vim.keymap.set('n', '<CR>', [[:nohlsearch<CR>]], { silent = true })
vim.keymap.set('n', '<Esc>', [[:nohlsearch<CR>]], { silent = true }) -- TODO: fix with bufnr and overload

-- Pasting yanked
vim.keymap.set('n', '<Leader>p', [["0p]], { noremap = false })
vim.keymap.set('n', '<Leader>P', [["0P]], { noremap = false })

-- Centering
vim.keymap.set('n', '<C-d>', [[zz]])
vim.keymap.set('n', 'n', [[nzzzv]])
vim.keymap.set('n', 'N', [[Nzzzv]])

-- Indenting
vim.keymap.set('v', '<Tab>', [[>gv]])
vim.keymap.set('v', '<S-Tab>', [[<gv]])

-- Filetypes
vim.filetype.add {
	pattern = {
		['.*/waybar/config'] = 'jsonc',
		['.*/mako/config'] = 'dosini',
		['.*/kitty/*.conf'] = 'bash',
		['.*/hypr/.*%.conf'] = 'hyprlang'
	}
}

------------------
-- Autocommands --
------------------

vim.api.nvim_create_autocmd('BufNewFile', {
	-- TODO: make a plugin
	callback = function ()
		-- local filetype = vim.api.nvim_get_option_value(0, 'filetype')
		local config = os.getenv('XDG_CONFIG_HOME') or (os.getenv('HOME') .. '/.config')
		local file = vim.api.nvim_eval([[expand('%:e')]])
		local template_path = config .. '/nvim/templates/skel.' .. file

		vim.cmd(string.format([[silent! execute '0r %s']], template_path))
		-- vim.cmd [[silent! execute '0r $HOME/.config/nvim/templates/skel.' . expand("<afile>:e")]]
	end,
	group = vim.api.nvim_create_augroup('templates', { clear = true }),
	pattern = '*.*'
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
	callback = function () vim.bo.filetype = 'glsl' end,
	group = vim.api.nvim_create_augroup('filetypes', { clear = true }),
	pattern = { '*.frag', '*.vert' }
})

-------------
-- Plugins --
-------------

Lazy_load = function(plugin)
  vim.api.nvim_create_autocmd({ 'BufRead', 'BufWinEnter', 'BufNewFile' }, {
    group = vim.api.nvim_create_augroup('BeLazyOnFileOpen' .. plugin, {}),
    callback = function()
      local file = vim.fn.expand '%'
      local condition = file ~= 'NvimTree_1' and file ~= '[lazy]' and file ~= ''

      if condition then
        vim.api.nvim_del_augroup_by_name('BeLazyOnFileOpen' .. plugin)

        -- dont defer for treesitter as it will show slow highlighting
        -- This deferring only happens only when we do "nvim filename"
        if plugin ~= 'nvim-treesitter' then
          vim.schedule(function()
            require('lazy').load { plugins = plugin }

            if plugin == 'nvim-lspconfig' then
              vim.cmd "silent! do FileType"
            end
          end, 0)
        else
          require('lazy').load { plugins = plugin }
        end
      end
    end,
  })
end

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system {
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable',
		lazypath,
	}
end
vim.opt.rtp:prepend(lazypath)

require 'lazy'.setup {
	-- LSP
	{
		'neovim/nvim-lspconfig',
		config = function ()
			vim.opt.shortmess:append 'c'

			vim.diagnostic.config {
				float = {
					border = 'rounded', header = '', prefix = '', show_header = false
				},
				severity_sort = true,
				virtual_text = false
			}

			vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
				border = 'rounded'
			})

			local signs = {
				DiagnosticSignError = '',
				DiagnosticSignHint = '',
				DiagnosticSignInfo = '',
				DiagnosticSignWarn = '',
				LightBulbSign = '󰁨'
			}
			for type, icon in pairs(signs) do vim.fn.sign_define(type, { text = icon, texthl = type, linehl = type, numhl = type }) end

			vim.api.nvim_create_autocmd({ 'CursorHold' }, {
				pattern = '*',
				callback = function () vim.diagnostic.open_float(nil, { focus = false }) end
			})

			require 'lspconfig'.prolog_ls.setup {
				docs = {
					description = [[
						https://github.com/jamesnvc/prolog_lsp

						Prolog Language Server
					]]
				},
				ft = 'prolog',
				on_attach = function (client)
					client.server_capabilities.semanticTokensProvider = nil
				end
			}
			require 'lspconfig'.nextls.setup {
				cmd = { '/home/sicro/.local/share/nvim/mason/bin/nextls', '--stdio' },
				init_options = {
					experimental = {
						completions = {
							enable = true
						}
					}
				}
			} -- TODO: remove these abominations
		end,
		dependencies = { 'hrsh7th/cmp-nvim-lsp', 'williamboman/mason-lspconfig.nvim', 'SmiteshP/nvim-navic' },
		event = 'FileType *',
		init = function ()
			-- vim.keymap.set('n', 'rn', vim.lsp.buf.rename) -- NOTE: or nvim-treesitter-refactor
			vim.keymap.set('n', 'K', vim.lsp.buf.hover)
			vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
			vim.keymap.set('n', 'ge', function () require 'telescope.builtin'.diagnostics() end)
			vim.keymap.set('n', 'gi', function () require 'telescope.builtin'.lsp_implementations() end)
			vim.keymap.set('n', 'gr', function () require 'telescope.builtin'.lsp_references() end)
			vim.keymap.set('n', 'gs', function () require 'telescope.builtin'.spell_suggest() end)
		end
	},
	{
		'kosayoda/nvim-lightbulb',
		dependencies = 'neovim/nvim-lspconfig',
		event = 'LspAttach',
		opts = {
			autocmd = { enabled = true },
			sign = { text = '󰌵' }
		}
	},
	{
		'ray-x/lsp_signature.nvim',
		config = true,
		event = 'LspAttach'
	},
	{
		'smjonas/inc-rename.nvim',
		config = true,
		dependencies = 'neovim/nvim-lspconfig',
		keys = {
			{ 'rn', function () return ':IncRename ' .. vim.fn.expand '<cword>' end, expr = true }
		}
	},
	{
		'stevearc/aerial.nvim',
		config = true,
		keys = {
			{ '<C-o>', function() require 'aerial'.toggle({ focus = false }) end, silent = true }
		}
	},
	{
		'j-hui/fidget.nvim',
		dependencies = 'neovim/nvim-lspconfig',
		event = 'LspAttach',
		opts = { -- BUG: wait for fix: https://github.com/j-hui/fidget.nvim/issues/122
			-- fmt = {
			-- 	max_messages = 2
			-- },
			sources = {
				lua_ls = {
					ignore = true
				}
			}
		},
		tag = 'legacy'
	},
	-- {
	-- 	'scalameta/nvim-metals',
	-- 	config = function ()
	-- 		local metals = require 'metals'.bare_config()
	--
	-- 		metals.settings = {
	-- 			showImplicitArguments = true,
	-- 			excludedPackages = { 'akka.actor.typed.javadsl', 'com.github.swagger.akka.javadsl' }
	-- 		}
	--
	-- 		metals.capabilities = require 'cmp_nvim_lsp'.default_capabilities()
	--
	-- 		vim.api.nvim_create_autocmd('FileType', {
	-- 			callback = function () require 'metals'.initialize_or_attach(metals) end,
	-- 			group = vim.api.nvim_create_augroup('nvim-metals', { clear = true }),
	-- 			pattern = { 'sbt', 'scala' }
	-- 		})
	-- 	end,
	-- 	ft = { 'sbt', 'scala' },
	-- 	depencencies = 'neovim/nvim-lspconfig'
	-- },
	{
		'scalameta/nvim-metals',
		dependencies = 'nvim-lua/plenary.nvim',
		config = function(self, metals_config)
			vim.api.nvim_create_autocmd('FileType', {
				callback = function() require 'metals'.initialize_or_attach(metals_config) end,
				group = vim.api.nvim_create_augroup('nvim-metals', { clear = true }),
				pattern = self.ft
			})
		end,
		ft = { 'sbt', 'scala' },
		opts = function()
			local metals_config = require("metals").bare_config()
			metals_config.on_attach = function(client, bufnr)
				-- your on_attach function
			end

			return metals_config
		end
	},
	{
		'nvimtools/none-ls.nvim',
		config = function ()
			local none = require 'null-ls'
			-- https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md
			-- flake8
			-- glslc
			-- proselint
			-- credo
			-- shaderc

			none.setup {
				sources = {
					none.builtins.diagnostics.mypy.with {
						args = function (params) return {
							'--hide-error-codes',
							'--hide-error-context',
							'--no-color-output',
							'--show-absolute-path',
							'--show-column-numbers',
							'--show-error-codes',
							'--no-error-summary',
							'--no-pretty',
							params.temp_path
						} end,
						prefer_local = '.venv/bin'
						-- 	runtime_condition = function(params)
						-- 		return require 'null-ls.utils'.path.exists(params.bufname)
						-- 	end
					}
				}
			}
		end,
		depencencies = { 'williamboman/mason-lspconfig.nvim', 'nvim-lua/plenary.nvim' },
		event = 'FileType *'
	},

	-- LSP Installer
	{
		'williamboman/mason.nvim',
		-- enabled = vim.bo.filetype ~= '',
		config = true,
		lazy = true
	},
	{
		-- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
		'williamboman/mason-lspconfig.nvim',
		config = function ()
			local lsp = require 'lspconfig'
			local servers = { 'arduino_language_server', 'asm_lsp', 'awk_ls', 'bashls', 'clangd', 'cobol_ls', 'cssls', 'html', 'dockerls', 'elmls', 'emmet_language_server', 'erlangls', 'gopls', 'hls', 'html', 'jdtls', 'julials', 'lemminx', 'lua_ls', 'marksman', 'perlnavigator', 'pylsp', 'ruff', 'rust_analyzer', 'sqlls', 'svelte', 'taplo', 'texlab', 'vls', 'yamlls' }
			-- https://www.reddit.com/r/neovim/comments/1cpkeqd/help_needed_with_python_lsp/
			-- basedpyright
			-- NOTE: not installing:
			-- mypy
			-- shellcheck
			-- ts_ls

			require 'mason-lspconfig'.setup {
				ensure_installed = servers,
				-- TODO: format with let servers = { name, Option<Config> }
				handlers = {
					function (server)
						lsp[server].setup {
							on_attach = function (client, bufnr)
								if client.server_capabilities.documentSymbolProvider then
									require 'nvim-navic'.attach(client, bufnr)

									vim.b.navic_lazy_update_context = true
									vim.o.winbar = [[      %{%v:lua.require'nvim-navic'.get_location()%} ]]
								end

								require 'lsp_signature'.on_attach({ hint_enable = false, hint_prefix = '' }, bufnr)
							end
						}
					end,
					-- ['elixirls'] = function () lsp.elixirls.setup {
					-- 	cmd = { '/home/sicro/.local/share/nvim/mason/bin/elixir-ls' },
					-- 	on_attach = function (client, bufnr)
					-- 		if client.server_capabilities.documentSymbolProvider then
					-- 			require 'nvim-navic'.attach(client, bufnr)
					--
					-- 			vim.b.navic_lazy_update_context = true
					-- 			vim.o.winbar = [[      %{%v:lua.require'nvim-navic'.get_location()%} ]]
					-- 		end
					--
					-- 		require 'lsp_signature'.on_attach({ hint_enable = false, hint_prefix = '' }, bufnr)
					-- 	end -- FIX:
					-- } end,
					['lemminx'] = function () lsp.lemminx.setup {
						on_attach = function (client, bufnr)
							if client.server_capabilities.documentSymbolProvider then
								require 'nvim-navic'.attach(client, bufnr)

								vim.b.navic_lazy_update_context = true
								vim.o.winbar = [[      %{%v:lua.require'nvim-navic'.get_location()%} ]]
							end

							require 'lsp_signature'.on_attach({ hint_enable = false, hint_prefix = '' }, bufnr)
						end,
						settings = {
							xml = {
								server = {
									workDir = "~/.cache/lemminx"
								}
							}
						}
					} end,
					['lua_ls']= function () lsp.lua_ls.setup {
						on_attach = function (client, bufnr)
							if client.server_capabilities.documentSymbolProvider then
								require 'nvim-navic'.attach(client, bufnr)

								vim.b.navic_lazy_update_context = true
								vim.o.winbar = [[      %{%v:lua.require'nvim-navic'.get_location()%} ]]
							end

							require 'lsp_signature'.on_attach({ hint_enable = false, hint_prefix = '' }, bufnr)
						end,
						settings = {
							Lua = {
								diagnostics = {
									globals = { 'vim' }
								},
								format = { enable = false },
								runtime = { version = 'LuaJIT' }
							}
						}
					} end,
					-- ['prolog_ls'] = function () lsp.prolog_ls.setup {
					-- 	docs = {
					-- 		description = [[
					-- 			https://github.com/jamesnvc/prolog_lsp
					--
					-- 			Prolog Language Server
					-- 		]]
					-- 	},
					-- 	ft = 'prolog',
					-- 	on_attach = function (client)
					-- 		client.server_capabilities.semanticTokensProvider = nil
					-- 	end
					-- } end,
					['pylsp'] = function () lsp.pylsp.setup {
						on_attach = function (client, bufnr)
							if client.server_capabilities.documentSymbolProvider then
								require 'nvim-navic'.attach(client, bufnr)

								vim.b.navic_lazy_update_context = true
								vim.o.winbar = [[      %{%v:lua.require'nvim-navic'.get_location()%} ]]
							end

							require 'lsp_signature'.on_attach({ hint_enable = false, hint_prefix = '' }, bufnr)
						end,
						settings = {
							pylsp = {
								plugins = {
									pycodestyle = {
										ignore = { 'E701', 'W191' },
										maxLineLength = 100
									},
									pyflakes = {
										enabled = false
									}
								}
							}
						}
					} end,
					-- ['rust_analyzer'] = function () lsp.rust_analyzer.setup {
					-- 	on_attach = function (client, bufnr)
					-- 		if client.server_capabilities.documentSymbolProvider then
					-- 			require 'nvim-navic'.attach(client, bufnr)
					--
					-- 			vim.b.navic_lazy_update_context = true
					-- 			vim.o.winbar = [[      %{%v:lua.require'nvim-navic'.get_location()%} ]]
					-- 		end
					--
					-- 		require 'lsp_signature'.on_attach({ hint_enable = false, hint_prefix = '' }, bufnr)
					-- 	end,
					-- 	-- settings = {
					-- 	-- 	['rust-analyzer'] = {
					-- 	-- 		diagnostics = {
					-- 	-- 			disabled = { 'unresolved-proc-macro' }
					-- 	-- 		},
					-- 	-- 	}
					-- 	-- }
					-- } end,
					['yamlls'] = function () lsp.yamlls.setup {
						on_attach = function (client, bufnr)
							if client.server_capabilities.documentSymbolProvider then
								require 'nvim-navic'.attach(client, bufnr)

								vim.b.navic_lazy_update_context = true
								vim.o.winbar = [[      %{%v:lua.require'nvim-navic'.get_location()%} ]]
							end

							require 'lsp_signature'.on_attach({ hint_enable = false, hint_prefix = '' }, bufnr)
						end,
						settings = {
							yaml = {
								keyOrdering = false
							}
						}
					} end
				}
			}
		end,
		dependencies = 'williamboman/mason.nvim',
		event = 'FileType *',
	},

	-- Diagnostics
	-- {
	-- 	'ErichDonGubler/lsp_lines.nvim',
	-- 	config = true,
	-- 	dependencies = 'neovim/nvim-lspconfig',
	-- 	event = 'LspAttach',
	-- 	init = function () vim.diagnostic.config({ virtual_lines = false }, require 'lazy.core.config'.ns) end
	-- },

	-- Completion
	{
		'hrsh7th/nvim-cmp',
		config = function ()
			local cmp = require 'cmp'
			local ctx = require 'cmp.config.context'
			local typ = require 'cmp.types'
			local snp = require 'luasnip'

			-- local has_words_before = function ()
			-- 	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
			-- 	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
			-- end

			cmp.setup {
				completion = { completeopt = 'menu,menuone,noselect' },
				enabled = function () return not (ctx.in_treesitter_capture 'comment' or ctx.in_syntax_group 'Comment') end,
				formatting = {
					format = require 'lspkind'.cmp_format { mode = 'symbol' }
				},
				mapping = cmp.mapping.preset.insert {
					["<CR>"] = cmp.mapping {
						c = cmp.mapping.confirm {
							behavior = cmp.ConfirmBehavior.Replace,
							select = true
						},
						i = function(fallback)
							if cmp.visible() and cmp.get_active_entry() then
								cmp.confirm {
									behavior = cmp.ConfirmBehavior.Replace,
									select = false
								}
							else
								fallback()
							end
						end,
						s = cmp.mapping.confirm { select = true }
					},
					['<Down>'] = cmp.mapping.close(),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						-- elseif snp.locally_jumpable(-1) then
						-- 	snp.jump(-1)
						-- elseif snp.jumpable(-1) then
						-- 	snp.jump(-1)
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						-- elseif snp.locally_jumpable(1) then
						-- 	snp.jump(1)
						-- elseif snp.expand_or_locally_jumpable() then
						-- 	snp.expand_or_jump()
						-- elseif snp.expand_or_jump() then
						-- 	snp.expand_or_jump()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<Up>'] = cmp.mapping.close()
				},
				preselect = typ.cmp.PreselectMode.None,
				snippet = {
					expand = function (args) snp.lsp_expand(args.body) end
				},
				sources = {
					{ name = 'nvim_lsp' },
					{
						name = 'luasnip',
						option = {
							delete_check_events = 'TextChanged,InsertLeave',
							history = true,
							region_check_events = 'InsertEnter',
							use_show_condition = false
						}
					},
					{ name = 'neorg' }
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered()
				}
			}

			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources(
					{
						{ name = 'path' },
					},
					{
						{
							name = 'cmdline',
							option = {
								ignore_cmds = { 'Man', '!' }
							}
						}
					}
				)
			})

			-- cmp.setup.cmdline({ '/', '?' }, {
			-- 	mapping = cmp.mapping.preset.cmdline(),
			-- 	sources = cmp.config.sources({
			-- 		{ name = 'buffer' },
			-- 	})
			-- })

			require 'cmp'.event:on('confirm_done', require 'nvim-autopairs.completion.cmp'.on_confirm_done())
		end,
		dependencies = { 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-cmdline', 'hrsh7th/cmp-path', 'saadparwaiz1/cmp_luasnip', 'onsails/lspkind.nvim', 'windwp/nvim-autopairs', 'L3MON4D3/LuaSnip' },
		event = { 'CmdlineEnter', 'InsertEnter' }
	},

	-- Language
	{
		'ray-x/go.nvim',
		build = function () require 'go.install'.update_all_sync() end,
		dependencies = { 'ray-x/guihua.lua', 'neovim/nvim-lspconfig', 'nvim-treesitter/nvim-treesitter' },
		config = function ()
			require 'go'.setup()

			vim.diagnostic.config { virtual_text = false }
		end,
		ft = { 'go', 'gomod' }
	},

	-- Syntax
	{
		'nvim-treesitter/nvim-treesitter',
		build = function () require 'nvim-treesitter.install'.update { with_sync = true } end,
		-- event = 'BufRead',
		event = 'FileType *',
		-- init = function ()
		-- 	local parser_config = require 'nvim-treesitter.parsers'.get_parser_configs()
		-- 	parser_config._hyperscript = {
		-- 		filetype = 'hyperscript',
		-- 		install_info = {
		-- 			url = 'https://github.com/dz4k/tree-sitter-_hyperscript',
		-- 			files = { 'src/parser.c' },
		-- 			branch = 'main',
		-- 			requires_generate_from_grammar = false,
		-- 		}
		-- 	}
		-- 	-- TODO: https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#adding-queries
		-- end,
		main = 'nvim-treesitter.configs',
		opts = {
			auto_install = true,
			ensure_installed = 'all',
			highlight = {
				enable = true,
				disable = { 'comment', 'latex' }
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					node_decremental = '<S-CR>',
					node_incremental = '<CR>',
				}
			},
			indent = {
				enable = true
			},
			textobjects = {
				select = {
					enable = true,
					include_surrounding_whitespace = true,
					keymaps = {
						['ab'] = '@block.outer',
						['aC'] = '@class.outer',
						['af'] = '@function.outer',
						['ac'] = '@conditional.outer',
						['al'] = '@loop.outer',
						['a/'] = '@comment.outer',
						['as'] = '@scope',
						['ib'] = '@block.inner',
						['iC'] = '@class.inner',
						['if'] = '@function.inner',
						['ic'] = '@conditional.inner',
						['il'] = '@loop.inner'
					},
					lookahead = true,
					selection_modes = {
						['@parameter.outer'] = 'v',
						['@function.outer'] = 'V',
						['@class.outer'] = '<c-v>'
					}
				}
			}
		}
	},
	{
		'nvim-treesitter/nvim-treesitter-textobjects',
		dependencies = 'nvim-treesitter/nvim-treesitter',
		event = 'FileType *'
	},
	{
		'echasnovski/mini.surround',
		config = true,
		keys = {
			{ 's', mode = { 'n', 'v' } }
		},
		version = false
	},

	-- Marks
	{
		'ThePrimeagen/harpoon',
		branch = 'harpoon2',
		config = function ()
			local hp = require 'harpoon'

			hp:setup()

			vim.keymap.set('n', '<Leader>a', function () hp:list():append() end)
			vim.keymap.set('n', '<Leader>h', function () hp.ui:toggle_quick_menu(hp:list()) end)
			vim.keymap.set('n',  '<C-1>', function () hp:list():select(1) end)
			vim.keymap.set('n',  '<C-2>', function () hp:list():select(2) end)
			vim.keymap.set('n',  '<C-3>', function () hp:list():select(3) end)
			vim.keymap.set('n',  '<C-4>', function () hp:list():select(4) end)

			-- NOTE: decide wether to run `require 'telescope'.load_extension 'harpoon'`
		end,
		dependencies = 'nvim-lua/plenary.nvim',
		keys = { '<Leader>a', '<C-h>', '<C-1>', '<C-2>', '<C-3>', '<C-4>' }
	},

	-- Fuzzy Finder
	{
		'nvim-telescope/telescope.nvim',
		config = function ()
			require 'telescope'.setup {
				extensions = {
					['ui-select'] = { require 'telescope.themes'.get_dropdown() }
				},
				vimgrep_argument = { 'rg', '--smart-case' }
			}

			require 'telescope'.load_extension 'fzf'
			require 'telescope'.load_extension 'ui-select'
		end,
		dependencies = {
			'folke/todo-comments.nvim',
			'nvim-lua/plenary.nvim',
			{ 'nvim-telescope/telescope-fzf-native.nvim', build = [[make]] },
			'nvim-telescope/telescope-ui-select.nvim'
		},
		ft = 'mason',
		keys = {
			{ 'ga', function () vim.lsp.buf.code_action() end },
			{ '<C-c>', function () require 'telescope'.load_extension 'todo-comments'.todo() end },
			{ '<C-f>', function () require 'telescope.builtin'.live_grep() end }
		}
	},

	-- File Explorer
	{
		'nvim-tree/nvim-tree.lua',
		dependencies = 'nvim-tree/nvim-web-devicons',
		keys = {
			{ '<C-e>', function () require 'nvim-tree.api'.tree.toggle() end, silent = true }
		},
		opts = {
			filters = { dotfiles = true },
			git = { enable = false },
			on_attach = function (bufnr)
				local api = require 'nvim-tree.api'

				vim.keymap.set('n', '<C-r>', api.fs.rename_sub, { buffer = bufnr })
				vim.keymap.set('n', '<C-t>', api.node.open.tab, { buffer = bufnr })
				vim.keymap.set('n', '<C-v>', api.node.open.vertical, { buffer = bufnr })
				-- vim.keymap.set('n', '<C-b>', api.node.open.horizontal, { buffer = bufnr })
				vim.keymap.set('n', '<BS>', api.node.navigate.parent_close, { buffer = bufnr })
				vim.keymap.set('n', '<CR>', api.node.open.edit, { buffer = bufnr })
				vim.keymap.set('n', '<Tab>', api.node.open.preview, { buffer = bufnr })
				vim.keymap.set('n', '>', api.node.navigate.sibling.next, { buffer = bufnr })
				vim.keymap.set('n', '<', api.node.navigate.sibling.prev, { buffer = bufnr })
				vim.keymap.set('n', '-', api.tree.change_root_to_parent, { buffer = bufnr })
				vim.keymap.set('n', 'a', api.fs.create, { buffer = bufnr })
				vim.keymap.set('n', 'bmv', api.marks.bulk.move, { buffer = bufnr })
				vim.keymap.set('n', 'B', api.tree.toggle_no_buffer_filter, { buffer = bufnr })
				vim.keymap.set('n', 'c', api.fs.copy.node, { buffer = bufnr })
				vim.keymap.set('n', 'C', api.tree.toggle_git_clean_filter, { buffer = bufnr })
				vim.keymap.set('n', '[c', api.node.navigate.git.prev, { buffer = bufnr })
				vim.keymap.set('n', ']c', api.node.navigate.git.next, { buffer = bufnr })
				vim.keymap.set('n', 'd', api.fs.remove, { buffer = bufnr })
				vim.keymap.set('n', 'D', api.fs.trash, { buffer = bufnr })
				vim.keymap.set('n', 'E', api.tree.expand_all, { buffer = bufnr })
				vim.keymap.set('n', 'e', api.fs.rename_basename, { buffer = bufnr })
				vim.keymap.set('n', ']e', api.node.navigate.diagnostics.next, { buffer = bufnr })
				vim.keymap.set('n', '[e', api.node.navigate.diagnostics.prev, { buffer = bufnr })
				vim.keymap.set('n', 'F', api.live_filter.clear, { buffer = bufnr })
				vim.keymap.set('n', 'f', api.live_filter.start, { buffer = bufnr })
				vim.keymap.set('n', 'g?', api.tree.toggle_help, { buffer = bufnr })
				vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, { buffer = bufnr })
				vim.keymap.set('n', '.', api.tree.toggle_hidden_filter, { buffer = bufnr })
				vim.keymap.set('n', 'I', api.tree.toggle_gitignore_filter, { buffer = bufnr })
				vim.keymap.set('n', 'J', api.node.navigate.sibling.last, { buffer = bufnr })
				vim.keymap.set('n', 'K', api.node.navigate.sibling.first, { buffer = bufnr })
				vim.keymap.set('n', 'm', api.tree.change_root_to_node, { buffer = bufnr })
				vim.keymap.set('n', 'o', api.node.open.edit, { buffer = bufnr })
				vim.keymap.set('n', 'O', api.node.open.no_window_picker, { buffer = bufnr })
				vim.keymap.set('n', 'p', api.fs.paste, { buffer = bufnr })
				vim.keymap.set('n', 'P', api.node.navigate.parent, { buffer = bufnr })
				vim.keymap.set('n', 'q', api.tree.close, { buffer = bufnr })
				vim.keymap.set('n', 'r', api.fs.rename, { buffer = bufnr })
				vim.keymap.set('n', 'R', api.tree.reload, { buffer = bufnr })
				vim.keymap.set('n', 's', api.node.run.system, { buffer = bufnr })
				vim.keymap.set('n', 'S', api.tree.search_node, { buffer = bufnr })
				vim.keymap.set('n', 'U', api.tree.toggle_custom_filter, { buffer = bufnr })
				vim.keymap.set('n', 'W', api.tree.collapse_all, { buffer = bufnr })
				vim.keymap.set('n', 'x', api.fs.cut, { buffer = bufnr })
				vim.keymap.set('n', 'y', api.fs.copy.filename, { buffer = bufnr })
				vim.keymap.set('n', 'Y', api.fs.copy.relative_path, { buffer = bufnr })
				vim.keymap.set('n', '<2-LeftMouse>', api.node.open.edit, { buffer = bufnr })
				vim.keymap.set('n', '<2-RightMouse>', api.tree.change_root_to_node, { buffer = bufnr })
				vim.keymap.set('n', '<Space>', api.node.open.edit, { buffer = bufnr })
			end,
			view = { signcolumn = 'no' },
		}
	},

	-- Color
	{
		'NvChad/nvim-colorizer.lua',
		ft = { 'css', 'html', 'scss' },
		opts = {
			filetypes = { 'css', 'html', 'scss' },
			user_default_options = {
				AARRGGBB = true,
				RRGGBBAA = true,
				css_fn = true,
				sass = {
					enable = true
				}
			}
		}
	},

	-- Colorscheme
	{
		'catppuccin/nvim',
		config = function ()
			require 'catppuccin'.setup {
				flavour = 'macchiato',
				integrations = {
					aerial = true,
					fidget = true,
					hop = true,
					indent_blankline = {
						enabled = true
					},
					markdown = true,
					mason = true,
					native_lsp = {
						enabled = true
					},
					navic = {
						enabled = true
					},
					treesitter = true,
					ts_rainbow2 = true
				}
			}

			vim.cmd.colorscheme 'catppuccin'
		end,
		name = 'catppuccin',
		priority = 1000
	},

	-- Bars and Lines
	{
		'SmiteshP/nvim-navic',
		event = 'FileType *',
		opts = {
			highlight = true
		}
	},

	-- Statusline
	{
		'nvim-lualine/lualine.nvim',
		dependencies = 'nvim-tree/nvim-web-devicons',
		opts = {
			options = {
				globalstatus = true,
				component_separators = { left = '', right = '' },
				section_separators = { left = '', right = '' },
				theme = 'catppuccin'
			},
			extensions = { 'aerial', 'lazy', 'man', 'nvim-tree', 'toggleterm' },
			inactive_sections = {},
			sections = {
				lualine_b = {
					{
						'diagnostics',
						symbols = { error = ' ', hint  = ' ', info  = ' ', warn  = ' ' }
					}
				},
				lualine_c = {},
				lualine_x = { 'location' },
				lualine_y = { 'filetype' },
				lualine_z = {
					{
						'filename',
						symbols = { modified = ' ', readonly = ' ' }
					}
				}
			}

		}
	},

	-- Tabline
	{
		'akinsho/bufferline.nvim',
		dependencies = { 'catppuccin', 'nvim-tree/nvim-web-devicons' },
		config = function() require 'bufferline'.setup {
			highlights = require 'catppuccin.groups.integrations.bufferline'.get(),
			options = {
				diagnostics = 'nvim_lsp',
				hover = {
					enabled = true,
					reveal = { 'close' }
				},
				separator_style = 'slant'
			}
		} end,
		init = function () vim.opt.mousemoveevent = true end
	},

	-- Cursorline
	{
		'echasnovski/mini.cursorword',
		config = function ()
			require 'mini.cursorword'.setup {
				delay = 0
			}

			vim.api.nvim_set_hl(0, 'MiniCursorword', { link = 'LspReferenceText' })
			vim.api.nvim_set_hl(0, 'MiniCursorwordCurrent', {})
		end,
		event = 'FileType *',
		opts = {
			delay = 500
		},
		version = false
		-- 'David-Kunz/spotlight',
		-- config = function ()
		-- 	require 'spotlight'.setup { highlight_at_cursor = false }
		--
		-- 	vim.api.nvim_create_autocmd('CursorMoved', { callback = require 'spotlight'.run })
		-- end,
		-- dependencies = 'nvim-treesitter/nvim-treesitter'
	},

	-- Startup
	-- {
	-- 	'nvimdev/dashboard-nvim',
	-- 	config = true,
	-- 	event = 'VimEnter'
	-- },

	-- Note Taking
	-- {
	-- 	'nvim-neorg/neorg',
	-- 	dependencies = {
	-- 		'hrsh7th/nvim-cmp',
	-- 		'nvim-treesitter/nvim-treesitter',
	-- 		'nvim-lua/plenary.nvim',
	-- 		{
	-- 			'vhyrro/luarocks.nvim',
	-- 			config = true,
	-- 			priority = 1000
	-- 		}
	-- 	},
	-- 	ft = 'norg',
	-- 	opts = {
	-- 		load = {
	-- 			['core.defaults'] = {
	-- 				config = {
	-- 					disable = { 'core.norg.esupport.hop', 'core.promo', 'core.tangle' }
	-- 				}
	-- 			},
	-- 			['core.completion'] = {
	-- 				config = {
	-- 					engine = 'nvim-cmp'
	-- 				}
	-- 			},
	-- 			['core.concealer'] = {
	-- 				config = {
	-- 					dim_code_blocks = {
	-- 						padding = { left = 1, right = 1 },
	-- 						width = 'content'
	-- 					}
	-- 				}
	-- 			}
	-- 		}
	-- 	}
	-- },

	-- Utility
	{
		'kevinhwang91/nvim-ufo',
		dependencies = { 'kevinhwang91/promise-async', 'nvim-treesitter/nvim-treesitter' },
		event = 'FileType *',
		init = function () vim.keymap.set('n', '<Space>', [[za]]) end,
		opts = {
			fold_virt_text_handler = function (virtual_text, line_number, end_line_number, width, truncate)
				local new_virtual_text = {}
				local suffix = (' 󰁂 %d '):format(end_line_number - line_number)
				local suffix_width = vim.fn.strdisplaywidth(suffix)
				local target_width = width - suffix_width
				local current_width = 0
				for _, chunk in ipairs(virtual_text) do
					local chunk_text = chunk[1]
					local chunk_width = vim.fn.strdisplaywidth(chunk_text)
					if target_width > current_width + chunk_width then
						table.insert(new_virtual_text, chunk)
					else
						chunk_text = truncate(chunk_text, target_width - current_width)
						local highlight_group = chunk[2]
						table.insert(new_virtual_text, { chunk_text, highlight_group })
						chunk_width = vim.fn.strdisplaywidth(chunk_text)
						if current_width + chunk_width < target_width then
							suffix = suffix .. (' '):rep(target_width - current_width - chunk_width)
						end
						break
					end
					current_width = current_width + chunk_width
				end
				table.insert(new_virtual_text, { suffix, 'MoreMsg' })
				return new_virtual_text
			end,
			provider_selector = function () return { 'treesitter', 'indent' } end
		}
	},

	-- Terminal Integration
	{
		'akinsho/toggleterm.nvim',
		keys = {
			{
				'<Leader>g',
				function () require 'toggleterm.terminal'.Terminal:new {
					cmd = 'lazygit',
					direction = 'float',
					float_opts = {
						winblend = 30
					}
				}:toggle() end
			},
			'<C-t>'
		},
		opts = { insert_mappings = false, open_mapping = [[<C-t>]] }
	},

	-- Motion
	{
		'phaazon/hop.nvim',
		branch = 'v2',
		config = true,
		keys = {
			{ '<Leader><Leader>', function () require 'hop'.hint_words() end, silent = true }
		}
	},

	-- Editing Support
	{
		'windwp/nvim-ts-autotag',
		config = true,
		ft = { 'html', 'javascript', 'jsx', 'php', 'svelte', 'tsx', 'typescript', 'vue', 'xml' }
	},
	{
		'windwp/nvim-autopairs',
		config = function ()
			require 'nvim-autopairs'.setup {
				disable_filetype = { 'markdown' },
				map_c_h = true,
				map_c_w = true
			}

			local pair = require 'nvim-autopairs'
			local rule = require 'nvim-autopairs.rule'

			-- TODO: add {-# #-} Haskell pair
			pair.add_rules {
				rule(' ', ' ')
					:with_pair(function (opts)
						return vim.tbl_contains({ '()', '[]', '{}' }, opts.line:sub(opts.col - 1, opts.col))
					end),
				rule('( ', ' )')
					:with_pair(function () return false end)
					:with_move(function (opts) return opts.prev_char:match '.%)' ~= nil end)
					:use_key ')',
				rule('[ ', ' ]') -- BUG: disable for Markdown (or if previous characters are ` -`)
					:with_pair(function () return false end)
					:with_move(function (opts) return opts.prev_char:match '.%}' ~= nil end)
					:use_key ']',
				rule('{ ', ' }')
					:with_pair(function () return false end)
					:with_move(function (opts) return opts.prev_char:match '.%}' ~= nil end)
					:use_key '}'
			}
		end,
		event = 'FileType *'
	},
	-- {
	-- 	'HiPhish/rainbow-delimiters.nvim',
	-- 	config = function ()
	-- 		local rainbow_delimiters = require 'rainbow-delimiters'
	--
	-- 		vim.g.rainbow_delimiters = {
	-- 			strategy = {
	-- 				[''] = rainbow_delimiters.strategy['global'],
	-- 				vim = rainbow_delimiters.strategy['local']
	-- 			},
	-- 			query = {
	-- 				[''] = 'rainbow-delimiters',
	-- 				lua = 'rainbow-blocks'
	-- 			},
	-- 			highlight = { 'RainbowDelimiterRed', 'RainbowDelimiterYellow', 'RainbowDelimiterBlue', 'RainbowDelimiterOrange', 'RainbowDelimiterGreen', 'RainbowDelimiterViolet', 'RainbowDelimiterCyan' }
	-- 		}
	-- 	end,
	-- 	dependencies = 'nvim-treesitter/nvim-treesitter'
	-- },

	{
		'folke/todo-comments.nvim',
		dependencies = 'nvim-lua/plenary.nvim',
		event = 'FileType *',
		opts = { signs = false }
	},

	-- Indent
	{
		-- FIX: migrate
		'lukas-reineke/indent-blankline.nvim',
		-- config = function () require 'ibl'.setup() end,
		event = 'FileType *',
		main = 'ibl',
		opts = {
			-- char = '▏', show_current_context = false
			exclude = {
				filetypes = {
					'dashboard'
				}
			},
			scope = {
				enabled = false
			}
		}
	},

	-- Misc
	{
		'edgedb/edgedb-vim',
		config = true,
		ft = 'edgedb'
	},
	-- {
	-- 	'gaoDean/autolist.nvim',
	-- 	config = function()
	-- 		require 'autolist'.setup()
	--
	-- 		vim.keymap.set('i', '<Tab>', [[<Cmd>AutolistTab<CR>]]) -- FIX: bug with ```
	-- 		vim.keymap.set('i', '<S-Tab>', [[<Cmd>AutolistShiftTab<CR> ]]) -- TODO: improve
	-- 		vim.keymap.set('i', '<CR>', [[<CR><Cmd>AutolistNewBullet<CR>]])
	-- 		vim.keymap.set('n', 'o', [[o<Cmd>AutolistNewBullet<CR>]])
	-- 		vim.keymap.set('n', 'O', [[O<Cmd>AutolistNewBulletBefore<CR>]])
	-- 		vim.keymap.set('n', 't', [[<Cmd>AutolistToggleCheckbox<CR><CR>]])
	-- 		vim.keymap.set('n', '>>', [[>><Cmd>AutolistRecalculate<CR>]])
	-- 		vim.keymap.set('n', '<<', [[<<<Cmd>AutolistRecalculate<CR>]])
	-- 		vim.keymap.set('n', 'dd', [[dd<Cmd>AutolistRecalculate<CR>]])
	-- 		vim.keymap.set('v', 'd', [[d<Cmd>AutolistRecalculate<CR>]])
	-- 	end,
	-- 	ft = { 'markdown', 'norg', 'plaintex', 'tex' }
	-- },
	{
		'lervag/vimtex',
		config = function ()
			vim.g.vimtex_view_method = 'zathura'
			vim.g.vimtex_syntax_conceal = {
				ligatures = false,
				sections = true
			}
		end,
		ft = { 'bib', 'plaintex', 'tex' }
	},
	{
		'luukvbaal/statuscol.nvim',
		config = function () require 'statuscol'.setup {
			relculright = true,
			segments = {
				{ text = { '%s' }, click = 'v:lua.ScSa' },
				{ text = { require 'statuscol.builtin'.lnumfunc }, click = 'v:lua.ScLa' },
				{ text = { ' ', require 'statuscol.builtin'.foldfunc, " " }, click = "v:lua.ScFa" }
			}
		} end,
		dependencies = 'kevinhwang91/nvim-ufo',
		event = 'FileType *',
		init = function ()
			vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
			vim.o.foldcolumn = '1'
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true
		end
	},
	{
		'ShinKage/idris2-nvim',
		config = true,
		dependencies = { 'neovim/nvim-lspconfig', 'MunifTanjim/nui.nvim' },
		ft = { 'idris2', 'ipkg' }
	},
	-- {
	-- 	'OXY2DEV/markview.nvim',
	-- 	branch = 'dev',
	-- 	dependencies = { 'nvim-tree/nvim-web-devicons', 'nvim-treesitter/nvim-treesitter' },
	-- 	ft = { 'markdown' },
	-- 	opts = {
	-- 		-- code_blocks = {
	-- 		-- 	language_names = {
	-- 		-- 		{ 'py', 'python' }
	-- 		-- 	},
	-- 		-- 	position = 'overlay',
	-- 		-- 	sign = true,
	-- 		-- 	sign_hl = nil,
	-- 		-- 	style = 'language'
	-- 		-- }
	-- 	}
	-- },
	{
		'nomnivore/ollama.nvim',
		cmd = { 'Ollama', 'OllamaModel', 'OllamaServe', 'OllamaServeStop' },
		dependencies = 'nvim-lua/plenary.nvim',
		opts = {
			model = 'llama3'
		}
	},
	{
		'ignamartinoli/blankspace',
		keys = {
			{ '<F2>', function () require 'blankspace'.Toggle() end, silent = true }
		}
	}
}
