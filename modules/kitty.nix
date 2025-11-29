{ ... }:
{
  programs.kitty = {
    enable = true;
    themeFile = "gruvbox-dark-hard";

    font = {
      name = "Maple Mono";
      size = 16;
    };

    extraConfig = ''
      font_features MapleMono-Regular +ss01 +ss02 +ss04
      font_features MapleMono-Bold +ss01 +ss02 +ss04
      font_features MapleMono-Italic +ss01 +ss02 +ss04
      font_features MapleMono-Light +ss01 +ss02 +ss04
    '';

    settings = {
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
      "alt+t" = "new_tab";
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      "alt+5" = "goto_tab 5";

      ## Unbind
      "ctrl+-" = "change_font_size all -1.0";
      "ctrl++" = "change_font_size all +1.0";
      # Horizontal split (left/right)
      # "alt+s" = "launch --location=hsplit";
      # Vertical split (top/bottom)
      "alt+v" = "launch --location=vsplit";
      "alt+h"  = "neighboring_window left";
      "alt+l" = "neighboring_window right";
      "alt+k"    = "neighboring_window up";
      "alt+j"  = "neighboring_window down";
      # enter keyboard selection mode
      # "alt+]" = "selection_toggle";
      # "ctrl+shift+s" = "selection_toggle";


    };
  };
}
