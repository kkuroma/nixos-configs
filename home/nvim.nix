{ pkgs, lib, ... }:
{
  programs.nixvim = {
    enable = true;

    opts = {
      number         = true;
      relativenumber = true;
      tabstop        = 2;
      shiftwidth     = 2;
      expandtab      = true;
      termguicolors  = true;
      scrolloff      = 8;
      signcolumn     = "yes";
      cursorline     = true;
      wrap           = false;
      splitright     = true;
      splitbelow     = true;
    };

    # base16-nvim (RRethy) loaded from noctalia-generated matugen.lua.
    # noctalia writes ~/.config/nvim/lua/matugen.lua and sends SIGUSR1 on color change.
    # pcall guards against first boot before noctalia has run.
    extraPlugins = [ pkgs.vimPlugins.base16-nvim ];
    extraConfigLua = ''
      pcall(function() require('matugen').setup() end)

      -- Open neo-tree sidebar when nvim is started with a directory argument.
      -- After opening, move focus right so there's always a main editing window
      -- alongside the sidebar — prevents files from replacing the tree.
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          local arg = vim.fn.argv(0)
          if arg and arg ~= "" and vim.fn.isdirectory(arg) == 1 then
            vim.cmd("cd " .. vim.fn.fnameescape(arg))
            require("neo-tree.command").execute({ action = "show", dir = arg })
            vim.cmd("wincmd l")
          end
        end,
      })
    '';

    plugins = {
      # Syntax / language support
      treesitter = {
        enable = true;
        settings.highlight.enable = true;
      };
      nix.enable = true;

      # Session persistence (folke/persistence.nvim)
      persistence.enable = true;

      # LSP
      lsp = {
        enable = true;
        servers = {
          nil_ls.enable      = true;   # Nix
          pyright.enable     = true;   # Python
          lua_ls.enable      = true;   # Lua
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc  = false;
          };
          ts_ls.enable       = true;   # TypeScript / JavaScript
          bashls.enable      = true;   # Bash
          texlab.enable      = true;   # LaTeX
          taplo.enable       = true;   # TOML
          yamlls.enable      = true;   # YAML
        };
      };

      # Completion (sources auto-enabled from active plugins)
      cmp = {
        enable            = true;
        autoEnableSources = true;
      };

      # Snippet engine (required by cmp-luasnip source)
      luasnip.enable = true;

      # Fuzzy finder
      telescope.enable    = true;
      web-devicons.enable = true;

      # Left-side file tree (LazyVim style)
      neo-tree = {
        enable = true;
        settings = {
          close_if_last_window = true;
          window = {
            position = "left";
            width    = 30;
            mappings = {
              "<cr>" = "open_drop";
              "o"    = "open_drop";
            };
          };
          filesystem.filtered_items = {
            hide_dotfiles   = false;
            hide_gitignored = true;
          };
        };
      };

      # Buffer-as-filesystem file manager (keeps oil for in-buffer edits)
      oil.enable = true;

      # Status line
      lualine.enable = true;

      # Indent guides
      indent-blankline.enable = true;

      # Auto-close brackets / quotes
      nvim-autopairs.enable = true;

      # LaTeX (compile on save, SyncTeX, preview)
      vimtex = {
        enable = true;
        texlivePackage = null;  # use system texlive from home/apps.nix
        settings.view_method = "zathura";
      };

      # Formatting (declarative formatters per filetype)
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            nix        = [ "nixfmt" ];
            python     = [ "black" ];
            lua        = [ "stylua" ];
            javascript = [ "prettier" ];
            typescript = [ "prettier" ];
            json       = [ "prettier" ];
            yaml       = [ "prettier" ];
            markdown   = [ "prettier" ];
          };
          format_on_save = {
            timeout_ms = 500;
            lsp_fallback = true;
          };
        };
      };

      # Git gutter signs
      gitsigns.enable = true;

      # Keybind discovery
      which-key.enable = true;

      # Auto-load direnv environments on directory change
      direnv.enable = true;
    };

    keymaps = [
      # Toggle neo-tree
      { key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; options.desc = "File tree"; }
      # Oil (buffer file manager)
      { key = "<leader>o"; action = "<cmd>Oil<cr>"; options.desc = "Oil file manager"; }
      # Telescope
      { key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; options.desc = "Find files"; }
      { key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>";  options.desc = "Live grep"; }
      { key = "<leader>fb"; action = "<cmd>Telescope buffers<cr>";    options.desc = "Buffers"; }
      { key = "<leader>fh"; action = "<cmd>Telescope help_tags<cr>";  options.desc = "Help tags"; }
      # LSP
      { key = "gd";  action = "<cmd>lua vim.lsp.buf.definition()<cr>";     options.desc = "Go to definition"; }
      { key = "gr";  action = "<cmd>lua vim.lsp.buf.references()<cr>";     options.desc = "References"; }
      { key = "K";   action = "<cmd>lua vim.lsp.buf.hover()<cr>";          options.desc = "Hover docs"; }
      { key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<cr>"; options.desc = "Code action"; }
      { key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<cr>";      options.desc = "Rename symbol"; }
    ];
  };

  # Placeholder so nvim doesn't error on first boot before noctalia has written matugen.lua
  home.activation.nvimMatugenFallback = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/nvim/lua/matugen.lua" ]; then
      mkdir -p "$HOME/.config/nvim/lua"
      printf 'local M = {}\nfunction M.setup() end\nreturn M\n' \
        > "$HOME/.config/nvim/lua/matugen.lua"
    fi
  '';
}
