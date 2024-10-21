return require 'packer'.startup(function ()
	--------------------
	-- Plugin Manager --
	--------------------

	use 'wbthomason/packer.nvim'

	---------
	-- LSP --
	---------

	use {
		'neovim/nvim-lspconfig',
		after = 'mason-lspconfig.nvim',
		config = function () require 'lsp' end,
		requires = {
			'hrsh7th/cmp-nvim-lsp',
			{
				'williamboman/mason.nvim',
				config = function () require 'mason'.setup() end,
			},
			{
				'williamboman/mason-lspconfig.nvim',
				after = 'mason.nvim',
				config = function () require 'mason-lspconfig'.setup() end
			},
			'SmiteshP/nvim-navic'
		}
	}

	use {
		'kosayoda/nvim-lightbulb',
		after = 'nvim-lspconfig',
		config = function () require 'nvim-lightbulb'.setup {
			autocmd = { enabled = true }
		} end
	}

	-- use {
	-- 	'ray-x/lsp_signature.nvim',
	-- 	config = function () require 'lsp_signature'.setup { hint_prefix = ' ' } end,
	-- 	event = 'InsertEnter'
	-- }

	use {
		'smjonas/inc-rename.nvim',
		after = 'nvim-lspconfig',
		config = function () require 'inc_rename'.setup() end
	}

	use {
		'stevearc/aerial.nvim',
		config = function ()
			require 'aerial'.setup {
				layout = { min_width = 0.4 }
			}

			vim.keymap.set('n', '<C-a>', function () require 'aerial'.toggle() end)
		end,
		keys = '<C-a>'
	}

	use {
		'scalameta/nvim-metals',
		after = 'nvim-lspconfig',
		config = function ()
			vim.opt_global.completeopt = { 'menuone', 'noinsert', 'noselect' }
			vim.opt.shortmess:remove 'F'

			local meta = require 'metals'.bare_config()

			meta.settings = {
				excludedPackages = { 'akka.actor.typed.javadsl', 'com.github.swagger.akka.javadsl' },
				fallbackScalaVersion = '3.0.0',
				showImplicitArguments = true
			}

			meta.capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

			vim.api.nvim_create_autocmd('FileType', {
				pattern = { 'sbt', 'scala' },
				callback = function () require('metals').initialize_or_attach(meta) end
			})

			vim.keymap.set('n', 'ga', vim.lsp.buf.code_action)
			vim.keymap.set('n', 'gd', function () require 'telescope.builtin'.diagnostics() end)
			vim.keymap.set('n', 'gi', function () require 'telescope.builtin'.lsp_implementations() end)
			vim.keymap.set('n', 'gr', function () require 'telescope.builtin'.lsp_references() end)
			vim.keymap.set('n', 'gs', function () require 'telescope.builtin'.spell_suggest() end)
			vim.keymap.set('n', 'rn', [[:IncRename ]])
			vim.keymap.set('n', 'K', vim.lsp.buf.hover)
		end,
		ft = 'scala',
		requires = { 'nvim-lua/plenary.nvim' }
	}

	use {
		'ShinKage/idris2-nvim',
		config = function () require 'idris2'.setup({}) end,
		ft = 'idris2',
		requires = { 'neovim/nvim-lspconfig', 'MunifTanjim/nui.nvim' }
	}

	----------------
	-- Completion --
	----------------

	use {
		'hrsh7th/nvim-cmp',
		config = function ()
			local cmp = require 'cmp'
			local typ = require 'cmp.types'
			local snp = require 'luasnip'

			local has_words_before = function ()
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
			end

			cmp.setup {
				completion = { completeopt = 'menu,menuone,noselect' },
				formatting = {
					format = require 'lspkind'.cmp_format { maxwidth = 50, mode = 'symbol' }
				},
				mapping = cmp.mapping.preset.insert {
					['<Down>'] = cmp.mapping.close(),
					['<Up>'] = cmp.mapping.close(),
					['<CR>'] = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Replace },
					['<Tab>'] = cmp.mapping(function (fallback)
						if cmp.visible() then cmp.select_next_item()
						elseif snp.expand_or_jumpable() then snp.expand_or_jump()
						elseif has_words_before() then cmp.complete()
						else fallback() end
					end, { 'i', 's' }),
					['<S-Tab>'] = cmp.mapping(function (fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif snp.jumpable(-1) then
							snp.jump(-1)
						else
							fallback()
						end
					end, { 'i', 's' })
				},
				preselect = typ.cmp.PreselectMode.None,
				snippet = {
					expand = function (args)
						snp.lsp_expand(args.body)
					end
				},
				sources = {
					{ name = 'nvim_lsp' },
					{ name = 'nvim_lsp_signature_help' },
					{
						name = 'luasnip',
						option = { use_show_condition = false }
					},
					-- { name = 'neorg' },
					{ name = 'path' },
					{ name = 'buffer' }
				},
				window = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() }
			}

			require 'cmp'.event:on('confirm_done', require 'nvim-autopairs.completion.cmp'.on_confirm_done())
		end,
		event = 'InsertEnter',
		requires = {
			{ 'hrsh7th/cmp-path', after = 'nvim-cmp' },
			{ 'hrsh7th/cmp-nvim-lsp-signature-help', after = 'nvim-cmp' },
			{ 'onsails/lspkind-nvim', event = 'InsertEnter' },
			{ 'saadparwaiz1/cmp_luasnip', after = 'nvim-cmp' },
			{ 'L3MON4D3/LuaSnip', event = 'InsertEnter' }
		},
		setup = function ()
			-- FIX:
			vim.cmd [[PackerLoad LuaSnip]]
			vim.cmd [[PackerLoad nvim-autopairs]]
			vim.cmd [[PackerLoad lspkind-nvim]]
		end
	}

	------------
	-- Syntax --
	------------

	use {
		'nvim-treesitter/nvim-treesitter',
		config = function () require 'nvim-treesitter.configs'.setup {
			highlight = { enable = true },
			indent = { enable = true },
			rainbow = { enable = true, extended_mode = true, max_file_lines = nil }
		} end,
		requires = { 'mrjones2014/nvim-ts-rainbow', after = 'nvim-treesitter' }
	}

	use {
		'kylechui/nvim-surround',
		config = function () require 'nvim-surround'.setup() end
	}

	--------------------------
	-- Terminal Integration --
	--------------------------

	use {
		'akinsho/toggleterm.nvim',
		config = function ()
			require 'toggleterm'.setup {
				direction = 'float',
				insert_mappings = false,
				open_mapping = [[<C-t>]],
				shell = 'bash',
				float_opts = { border = 'curved', winblend = 15 }
			}

			vim.keymap.set('n', '<C-g>', function () require 'toggleterm.terminal'.Terminal:new { cmd = 'lazygit', direction = 'float', hidden = true }:toggle() end, { noremap = true, silent = true })
		end,
		keys = { '<C-g>', '<C-t>' }
	}

	------------------
	-- Fuzzy Finder --
	------------------

	use {
		'nvim-telescope/telescope.nvim',
		config = function ()
			require 'telescope'.setup {
				extensions = {
					fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true, case_mode = 'smart_case' },
					['ui-select'] = { require 'telescope.themes'.get_dropdown() }
				},
				vimgrep_argument = { 'rg', '--smart-case' }
			}

			require 'telescope'.load_extension 'fzf'
			require 'telescope'.load_extension 'ui-select'
		end,
		requires = {
			'nvim-lua/plenary.nvim',
			{ 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
			{ 'nvim-telescope/telescope-ui-select.nvim' }
		},
		setup = function ()
			vim.keymap.set('n', '<C-c>', [[:TodoTelescope <CR>]], { silent = true })
			vim.keymap.set('n', '<C-f>', function () require 'telescope.builtin'.live_grep() end, { silent = true })
		end
	}

	-----------
	-- Color --
	-----------

	use {
		'norcalli/nvim-colorizer.lua',
		config = function () require 'colorizer'.setup({ '*' }, { names = false }) end,
		ft = 'css'
	}

	-----------------
	-- Colorscheme --
	-----------------

	use {
		'catppuccin/nvim',
		as = 'catppuccin',
		config = function ()
			require 'catppuccin'.setup {
				compile = { enabled = true },
				flavour = 'macchiato',
				integrations = { aerial = true, hop = true, ts_rainbow = true }
			}

			require 'catppuccin'.load()
		end
	}

	-----------------
	-- Note taking --
	-----------------

	use {
		'nvim-neorg/neorg',
		after = 'nvim-treesitter',
		config = function ()
			vim.cmd [[PackerLoad LuaSnip]]
			vim.cmd [[PackerLoad lspkind-nvim]]
			vim.cmd [[PackerLoad nvim-autopairs]]
			vim.cmd [[PackerLoad nvim-cmp]]
			vim.cmd [[PackerLoad nvim-treesitter]]

			require 'neorg'.setup {
				load = {
					['core.defaults'] = {},
					['core.export'] = {},
					['core.export.markdown'] = {},
					['core.norg.completion'] = {
						config = { engine = 'nvim-cmp' }
					},
					['core.norg.concealer'] = {}
				}
			}

			vim.keymap.set('n', 'gs', function () require 'telescope.builtin'.spell_suggest() end)
		end,
		ft = 'norg',
		requires = { 'nvim-lua/plenary.nvim' },
	}

	-------------
	-- Utility --
	-------------

	-- use {
	-- 	'kevinhwang91/nvim-ufo',
	-- 	config = function ()
	-- 		require 'ufo'.setup()
 --
	-- 		vim.opt.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
	-- 		vim.opt.foldcolumn = '1'
	-- 		vim.opt.foldenable = true
	-- 		vim.opt.foldlevel = 10
	-- 	end,
	-- 	requires = 'kevinhwang91/promise-async',
	-- 	setup = function ()
	-- 		vim.keymap.set('n', '<S-f>', [[za]])
	-- 	end
	-- }

	-------------
	-- Tabline --
	-------------

	use {
		'akinsho/bufferline.nvim',
		after = 'catppuccin',
		config = function () require 'bufferline'.setup {
			options = {
				diagnostics = 'nvim_lsp',
				diagnostics_indicator = function (count, level) return ' ' .. (level:match 'error' and ' ' or ' ') .. count end,
				separator_style = 'slant'
			}
		} end,
		requires = 'nvim-tree/nvim-web-devicons',
		tag = '*'
	}

	----------------
	-- Statusline --
	----------------

	use {
		'nvim-lualine/lualine.nvim',
		after = 'catppuccin',
		config = function ()
			require 'lualine'.setup {
				extensions = { 'aerial', 'man', 'nvim-tree', 'toggleterm' },
				inactive_sections = {},
				options = {
					globalstatus = true,
					component_separators = { left = '', right = '' },
					section_separators = { left = '', right = '' }
				},
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
							symbols = { modified = ' ', readonly = ' ', }
						}
					}
				}
			}

			vim.opt.showmode = false
		end,
		requires = 'nvim-tree/nvim-web-devicons'
	}

	------------
	-- Indent --
	------------

	use {
		'lukas-reineke/indent-blankline.nvim',
		after = 'nvim-treesitter',
		config = function () require 'indent_blankline'.setup { char = '▏', show_current_context = true } end
	}

	-------------------
	-- File explorer --
	-------------------

	use {
		'nvim-tree/nvim-tree.lua',
		cmd = 'NvimTreeToggle',
		config = function () require 'nvim-tree'.setup {
			view = {
				mappings = {
					list = {
						{
							action = 'edit',
							key = { 'o', '<2-LeftMouse>', '<CR>', '<Space>' }
						},
						{ action = 'split', key = '<C-b>' },
						{ action = 'toggle_dotfiles', key = 'h' },
						{ action = 'cd', key = 'm' },
						{ action = '', key = '<C-e>' },
						{ action = '', key = '<C-x>' }
					}
				},
				signcolumn = 'no'
			},
			filters = { dotfiles = true },
			git = { enable = false }
		} end,
		requires = 'nvim-tree/nvim-web-devicons',
		setup = function () vim.keymap.set('n', '<C-e>', [[:NvimTreeToggle <CR>]], { silent = true }) end
	}

	-------------
	-- Comment --
	-------------

	use {
		'numToStr/Comment.nvim',
		config = function () require 'Comment'.setup() end,
		keys = { 'gb', 'gc' }
	}

	use {
		'folke/todo-comments.nvim',
		config = require 'todo-comments'.setup(),
		requires = 'nvim-lua/plenary.nvim'
	}

	------------
	-- Motion --
	------------

	use {
		'phaazon/hop.nvim',
		branch = 'v1',
		config = function ()
			require 'hop'.setup()

			vim.keymap.set('n', '<Leader><Leader>', function () require 'hop'.hint_words() end)
			vim.keymap.set('n', '<Leader>l', function () require 'hop'.hint_lines() end)
		end,
		keys = '<Leader>'
	}

	---------------------
	-- Editing Support --
	---------------------

	use {
		'windwp/nvim-autopairs',
		config = function ()
			require 'nvim-autopairs'.setup {
				disable_filetype = { 'markdown', 'TelescopePrompt' }
			}

			local pair = require 'nvim-autopairs'
			local rule = require 'nvim-autopairs.rule'
			local cond = require 'nvim-autopairs.conds'

			-- TODO:
			-- pair.get_rule('\'')[2].not_filetypes = { 'haskell' }
			-- pair.get_rule('\'')[2]:with_pair(cond.not_after_text(' '))

			pair.remove_rule('\'')

			pair.add_rules {
				rule(' ', ' ')
					:with_pair(function (opts)
						return vim.tbl_contains({ '()', '[]', '{}' }, opts.line:sub(opts.col - 1, opts.col))
					end),
				rule('( ', ' )')
					:with_pair(function () return false end)
					:with_move(function (opts) return opts.prev_char:match '.%)' ~= nil end)
					:use_key ')',
				rule('[ ', ' ]')
					:with_pair(function () return false end)
					:with_move(function (opts) return opts.prev_char:match '.%}' ~= nil end)
					:use_key ']',
				rule('{ ', ' }')
					:with_pair(function () return false end)
					:with_move(function (opts) return opts.prev_char:match '.%}' ~= nil end)
					:use_key '}',
				rule('$', '$', { 'plaintex', 'tex' })
					:with_pair(cond.not_after_regex '%%'),
				rule('\'', '\'')
					:with_pair(cond.not_filetypes { 'clojure', 'lisp', 'scheme' }),
				rule('|', '|', 'rust'),
				rule('\\(', '\\)', 'tex'),
				rule('\\[', '\\]', 'tex')
			}
		end,
		event = 'InsertEnter'
	}

	use {
		'gaoDean/autolist.nvim',
		config = function () require 'autolist'.setup() end,
		ft = { 'markdown', 'plaintex', 'tex', 'text' }
	}

	--------------
	-- Personal --
	--------------

	use {
		-- TODO: make Toggle work and add user command
		'ignamartinoli/blankspace',
		setup = function () vim.keymap.set('n', '<F2>', function () require 'blankspace'.Toggle() end, { silent = true }) end
	}
end)
