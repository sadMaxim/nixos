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
      settings = {
        highlight.enable = true;
        indent.enable = true;
        ensure_installed = [ "python" "lua" "typescript" "javascript" "nix" ];
      };
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
    snacks = {
      enable = true;
      settings = {
        terminal.enabled = true;
        input.enabled = true;
        select.enabled = true;
      };
    };
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
     key = "diff";
     action = ":lua local view = require('diffview.lib').get_current_view(); if view then vim.cmd('DiffviewClose') else vim.cmd('DiffviewOpen') end<CR>";
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
    # OpenCode keymaps
    {
      mode = "n";
      key = "code";
      action = "<cmd>lua _G.opencode_toggle()<CR>";
      options = { silent = true; desc = "OpenCode Toggle"; };
    }
    {
      mode = "n";
      key = "ask";
      action = "<cmd>lua _G.opencode_ask()<CR>";
      options = { silent = true; desc = "OpenCode Ask"; };
    }
    {
      mode = "n";
      key = "rev";
      action = "<cmd>lua _G.opencode_review()<CR>";
      options = { silent = true; desc = "OpenCode Review"; };
    }
    {
      mode = "n";
      key = "sea";
      action = "<cmd>lua _G.opencode_search()<CR>";
      options = { silent = true; desc = "OpenCode Research"; };
    }
    {
      mode = "v";
      key = "ask";
      action = "<cmd>lua _G.opencode_ask()<CR>";
      options = { silent = true; desc = "OpenCode Ask (Visual)"; };
    }
    {
      mode = "n";
      key = "this";
      action = "<cmd>lua _G.opencode_ask()<CR>";
      options = { silent = true; desc = "OpenCode Ask (this)"; };
    }
    {
      mode = "v";
      key = "this";
      action = "<cmd>lua _G.opencode_ask()<CR>";
      options = { silent = true; desc = "OpenCode Ask (this visual)"; };
    }
    {
      mode = "v";
      key = "rev";
      action = "<cmd>lua _G.opencode_review()<CR>";
      options = { silent = true; desc = "OpenCode Review (Visual)"; };
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
  extraConfigLuaPost = ''
    vim.opt.showtabline = 0
    -- capabilities.textDocument.completion.completionItem.snippetSupport = true

    local function kitty_cmd_prefix()
      local socket = vim.env.KITTY_LISTEN_ON or ""
      if socket == "" then
        local sockets = vim.fn.glob("/tmp/kitty*", true, true)
        if #sockets > 0 then
          socket = "unix:" .. sockets[1]
        end
      end

      local cmd_prefix = "kitty @ "
      if socket ~= "" then
        cmd_prefix = cmd_prefix .. "--to " .. socket .. " "
      end
      return cmd_prefix
    end

    local function read_repo_port()
      local port_file = vim.fs.find(".opencode/nvim-port", {
        upward = true,
        path = vim.fn.getcwd(),
        type = "file",
      })[1]

      if not port_file then
        return nil, "No .opencode/nvim-port file found. Start opencode in this repo first."
      end

      local lines = vim.fn.readfile(port_file)
      local port = tonumber(lines[1] or "")
      if not port then
        return nil, "Invalid port in " .. port_file
      end

      return port
    end

    local function sync_opencode_port()
      local port, err = read_repo_port()
      if not port then
        return nil, err
      end

      require("opencode.config").opts.port = port
      return port
    end

    local function is_port_open(port)
      local ok, chan = pcall(vim.fn.sockconnect, "tcp", ("127.0.0.1:%d"):format(port), { rpc = false, timeout = 200 })
      if ok and chan and chan ~= 0 then
        pcall(vim.fn.chanclose, chan)
        return true
      end
      return false
    end

    local kitty_provider = {
      name = 'kitty',
      start = function()
        local port, err = sync_opencode_port()
        if not port then
          vim.notify(err, vim.log.levels.WARN, { title = "opencode" })
          return
        end

        if is_port_open(port) then
          return
        end

        local cmd_prefix = kitty_cmd_prefix()
        local focused = os.execute(cmd_prefix .. 'focus-tab --match title:opencode >/dev/null 2>&1')
        if focused then
          os.execute(cmd_prefix .. 'send-text --match title:opencode ' .. vim.fn.shellescape('opencode --port ' .. port .. '\r') .. ' >/dev/null 2>&1')
          return
        end

        local cwd = vim.fn.getcwd()
        os.execute(
          cmd_prefix
            .. 'launch --type=tab --tab-title=opencode --cwd='
            .. vim.fn.shellescape(cwd)
            .. ' opencode --port '
            .. port
            .. ' >/dev/null 2>&1 &'
        )
      end,
    }
    kitty_provider.toggle = function() kitty_provider.start() end
    kitty_provider.show = function()
      os.execute(kitty_cmd_prefix() .. 'focus-tab --match title:opencode >/dev/null 2>&1')
    end
    kitty_provider.health = function()
      if vim.fn.executable('kitty') == 0 then
        return '`kitty` is not available in PATH.'
      end
      return true
    end

    local opencode_config = require('opencode.config')
    opencode_config.provider = kitty_provider

    _G.opencode_toggle = function()
      local _, err = sync_opencode_port()
      if err then
        vim.notify(err, vim.log.levels.WARN, { title = "opencode" })
        return
      end
      require('opencode').toggle()
    end

    _G.opencode_ask = function(default)
      local _, err = sync_opencode_port()
      if err then
        vim.notify(err, vim.log.levels.WARN, { title = "opencode" })
        return
      end
      require('opencode').ask(default)
    end

    _G.opencode_review = function()
      local _, err = sync_opencode_port()
      if err then
        vim.notify(err, vim.log.levels.WARN, { title = "opencode" })
        return
      end
      require('opencode').prompt('review', { submit = true })
    end

    _G.opencode_search = function()
      _G.opencode_ask('Research: ')
    end
  '';
  
  extraConfigVim="
    set clipboard+=unnamedplus
    set tags+=./tags,tags,./.git/tags
  ";
  extraPlugins = with pkgs.vimPlugins; [
    purescript-vim
    opencode-nvim
  ];

}
