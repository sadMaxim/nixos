{ config, pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    themeFile = "gruvbox-dark-hard";

    font = {
      name = "Maple Mono";
      size = 17;
    };

      # action_alias kitty_scrollback_nvim kitten /nix/store/1dh8q81avy5x54hh5w76mq2sh9zl449i-vim-pack-dir/pack/myNeovimPackages/start/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py
    extraConfig = ''
      action_alias kitty_scrollback_nvim kitten ${pkgs.vimPlugins.kitty-scrollback-nvim}/python/kitty_scrollback_nvim.py
      listen_on unix:/tmp/kitty
      font_features MapleMono-Regular +ss01 +ss02 +ss04
      font_features MapleMono-Bold +ss01 +ss02 +ss04
      font_features MapleMono-Italic +ss01 +ss02 +ss04
      font_features MapleMono-Light +ss01 +ss02 +ss04
    '';

    settings = {
      allow_remote_control = "yes";
      # listen_on = "unix:/tmp/kitty";
      # shell_integration = "enabled";
      confirm_os_window_close = 0;
      background_opacity = "0.66";
      scrollback_lines = 10000;
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      window_padding_width = 5;
      
      ## Line wrapping
      scrollback_pager_history_size = 0;
      scrollback_fill_enlarged_window = true;

      ## clipboard 
      copy_on_select = "clipboard";

      ## Tabs
      tab_title_template = "{index}";
      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";
      tab_bar_style = "powerline";
      tab_powerline_style = "angled";
      active_tab_foreground = "#FBF1C7";
      active_tab_background = "#7C6F64";
      inactive_tab_foreground = "#FBF1C7";
      inactive_tab_background = "#3C3836";
    };

    keybindings = {
      ## Tabs
      "alt+t" = "new_tab_with_cwd";
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      "alt+5" = "goto_tab 5";

      ## Unbind
      "ctrl+-" = "change_font_size all -1.0";
      "ctrl++" = "change_font_size all +1.0";
      # Horizontal split (same directory)
      "alt+s" = "launch --cwd=current --location=hsplit";
      # Vertical split (same directory)
      "alt+v" = "launch --cwd=current --location=vsplit";
      "alt+h"  = "neighboring_window left";
      "alt+l" = "neighboring_window right";
      "alt+k"    = "neighboring_window up";
      "alt+j"  = "neighboring_window down";
      "f11" = "save_as_session --save-only --use-foreground-process --base-dir ~/.local/state last";
      "f12" = "goto_session ~/.local/state/last";

            

      

      
      # kitty-scrollback.nvim
      "alt+[ " = "kitty_scrollback_nvim";
      
      # Open opencode in new tab for 99 integration
      "alt+9" = "new_tab --tab-title opencode opencode";
      
    };
  };
}
