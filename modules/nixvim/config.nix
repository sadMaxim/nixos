{pkgs, ...}:
{
  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };

  # Ensure leader is set early in case globals are applied too late for some plugins.
  extraConfigLuaPre = ''
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "
  '';

  plugins = {
    bufferline.enable = true;
    web-devicons.enable = true;
    treesitter = {
      enable = true;
      settings.highlight.enable = true;
    };
    direnv.enable = true;
    hop.enable = true;
    comment.enable = true;
    lualine.enable = true;
    diffview.enable = true;
    windsurf-nvim = {
      enable = true;
      settings = {
        virtual_text = {
          enable = true;
        };
        workspace_root.use_lsp = true;
      };
    };


    kitty-scrollback.enable = true;
    telescope.enable = true;
    fzf-lua.enable = true;

    nvim-tree = {
      enable = true;
      settings = {
        disable_netrw = true;
        git = {
          enable = true;
          timeout = 2000;
        };
      };
    };
    nvim-autopairs.enable = true;
    lazygit.enable = true;
    

  };



  highlightOverride = {
   Normal.bg = "none";
   NormalFloat.bg = "none";
   FloatBorder.bg = "none";
   NvimTreeNormal = { bg = "none"; };
   NvimTreeNormalNC = { bg = "none"; };
   NvimTreeEndOfBuffer = { bg = "none"; };
   EndOfBuffer = { bg = "none"; };
  };

  colorschemes.onedark.enable = true;

  keymaps = [
   {
    mode = "n"; 
    key = "HP";
    action = ":HopWord<CR>";
   }
   {
    mode = "n"; 
    key = "<C-j>";
    action = ":Telescope find_files<CR>";
   }
   {
    mode = "n"; 
    key = "<C-b>";
    action = ":Telescope buffers<CR>";
   }
   {
    mode = "n"; 
    key = "<C-g>";
    action = ":Telescope live_grep<CR>";
   }
   {
    mode = "n"; 
    key = "NF";
    action = ":NvimTreeFindFile<CR>";
   }
   {
    mode = "i"; 
    key = "jj";
    action = "<Esc>";
   }
   {
    mode = "n"; 
    key = "<C-N>";
    action = ":bnext<CR>";
   }
   {
    mode = "n"; 
    key = "<C-P>";
    action = ":bprev<CR>";
   }
   {
    mode = "n"; 
    key = "<Del>";
    action = ":bd!<CR>";
   }
   {
    mode = "n"; 
    key = "LG";
    action = ":LazyGit<CR>";
   }
   {
    mode = "n"; 
    key = "K";
    action = ":lua vim.lsp.buf.hover()<CR>";
   }
   {
    mode = "n"; 
    key = "gd";
    action = ":lua vim.lsp.buf.definition()<CR>";
   }
   {
    mode = "n"; 
    key = "act";
   action = ":lua vim.lsp.buf.code_action()<CR>";
   }

    {
      mode = "v";
      key = "<Tab>";
      action = ":lua vim.lsp.buf.code_action()<CR>";
    }
    {
      mode = "n";
      key = "<Tab>";
      action = ":lua vim.lsp.buf.code_action({ context = { only = { 'source' } } })<CR>";
    }
   # Windsurf keymaps
   
  ];

  globalOpts = {

    number=true;
    relativenumber=true;
    mouse="a";

    tabstop=2;
    shiftwidth=2;
    softtabstop=2;
    expandtab=true;

    clipboard = {
      # providers = {
      #   wl-copy.enable = true; # Wayland 
      #   xsel.enable = true; # For X11
      # };
      register = "unnamedplus";
    };

    undofile = true;
    cursorline = true;
    ruler = true;
    gdefault = true;
    scrolloff = 5;
  };
  extraConfigLuaPost="
    vim.opt.showtabline = 0
    -- capabilities.textDocument.completion.completionItem.snippetSupport = true
  ";
  extraConfigVim="
    set clipboard+=unnamedplus
    set tags+=./tags,tags,./.git/tags
  ";
  extraPlugins = with pkgs.vimPlugins; [
    purescript-vim 
  # completion-nvim
  ];

}
