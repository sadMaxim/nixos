{ ... }:
{
  programs.tmux = {
    enable = true;

    extraConfig = ''
      # Use vi keys in copy mode
      setw -g mode-keys vi

      # Enable mouse (optional but recommended)
      set -g mouse on

      # Make y yank selection (vim-style)
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      # Visual mode (vim-like)
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi V send -X select-line

      # Allow Enter to copy selection
      bind -T copy-mode-vi Enter send -X copy-selection-and-cancel

      # Recommended: use RGB + kitty terminal integration
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-kitty:RGB"

      # Nice: big scrollback
      set -g history-limit 100000
    '';
  };
}
