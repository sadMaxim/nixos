{pkgs, ...}:
let
  # Build 99 plugin from GitHub
  _99-plugin = pkgs.vimUtils.buildVimPlugin {
    pname = "99-nvim";
    version = "2026-02-06";
    src = pkgs.fetchFromGitHub {
      owner = "ThePrimeagen";
      repo = "99";
      rev = "0fb3b8b2d032289ea7088a37161e1c50bdfccfa9";
      sha256 = "0c7pfdvkqv3izfklc98ka20f90lpn1j1w7xzp6gkp03rm1hxi7gc";
    };
    doCheck = false;
  };
  
  # Kitty provider lua code
  kittyProviderLua = pkgs.writeText "99-kitty-provider.lua" ''
    local BaseProvider = require("99.providers").OpenCodeProvider
    
    local KittySendTextProvider = setmetatable({}, { __index = BaseProvider })
    
    function KittySendTextProvider._build_command(_, query, request)
      local model = request.context.model
      local tmp_file = request.context.tmp_file
      
      -- Escape the query for shell safety
      local escaped_query = query:gsub('"', '\\\\"'):gsub("\n", "\\\\n")
      
      -- Create script that:
      -- 1. Sends query to kitty tab for visibility
      -- 2. Runs opencode to get response for 99
      -- 3. Writes response to temp file
      local script = string.format([[
        # Send to kitty tab for visibility (match by title "opencode")
        kitty @ --to unix:/tmp/kitty send-text --match title:opencode "%s" 2>/dev/null || true
        
        # Run opencode to get response for 99
        opencode run -m %s --print %s > %s 2>&1
      ]], 
        escaped_query,
        model,
        vim.fn.shellescape(query),
        tmp_file
      )
      
      return { "sh", "-c", script }
    end
    
    function KittySendTextProvider._get_provider_name()
      return "KittySendTextProvider"
    end
    
    return KittySendTextProvider
  '';
in
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
  extraPackages = with pkgs; [
    kitty # For 99 kitty provider integration
  ];

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
  
  extraConfigLua = ''
    -- 99 Plugin Setup with Kitty Provider
    local KittyProvider = dofile("${kittyProviderLua}")
    
    local _99 = require("99")
    _99.setup({
      logger = {
        level = _99.DEBUG,
        path = "/tmp/" .. vim.fs.basename(vim.uv.cwd()) .. ".99.debug",
        print_on_error = true,
      },
      provider = KittyProvider,
      model = "opencode/claude-sonnet-4-5",
      completion = {
        source = "cmp",
        custom_rules = {},
      },
      md_files = {
        "AGENT.md",
      },
    })
    
    -- 99 Keymaps
    vim.keymap.set("n", "<leader>9f", function()
      _99.fill_in_function()
    end, { desc = "99: Fill in function" })
    
    vim.keymap.set("v", "<leader>9v", function()
      _99.visual()
    end, { desc = "99: Visual selection" })
    
    vim.keymap.set("n", "<leader>9p", function()
      _99.fill_in_function_prompt()
    end, { desc = "99: Fill function with prompt" })
    
    vim.keymap.set("n", "<leader>9i", function()
      _99.info()
    end, { desc = "99: Info" })
    
    vim.keymap.set("n", "<leader>9l", function()
      _99.view_logs()
    end, { desc = "99: View logs" })
    
    vim.keymap.set("v", "<leader>9s", function()
      _99.stop_all_requests()
    end, { desc = "99: Stop all requests" })
    
    vim.keymap.set("n", "<leader>9r", function()
      _99.previous_requests_to_qfix()
    end, { desc = "99: Previous requests to quickfix" })
  '';

  extraConfigVim="
    set clipboard+=unnamedplus
    set tags+=./tags,tags,./.git/tags
  ";
  extraPlugins = with pkgs.vimPlugins; [
    purescript-vim
    _99-plugin
  ];

}
