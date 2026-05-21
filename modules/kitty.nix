{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    themeFile = "gruvbox-dark-hard";

    font = {
      name = "Maple Mono";
      size = 17;
    };

    extraConfig = ''
      action_alias kitty_scrollback_nvim kitten ${pkgs.vimPlugins.kitty-scrollback-nvim}/python/kitty_scrollback_nvim.py
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

      ## Clipboard
      copy_on_select = "clipboard";
    };

    keybindings = {
      "ctrl+-" = "change_font_size all -1.0";
      "ctrl++" = "change_font_size all +1.0";

      # kitty-scrollback.nvim
      "alt+[ " = "kitty_scrollback_nvim";
    };
  };
}
