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

      # Let terminal apps (including pi) distinguish modified keys
      set -g extended-keys on
      set -g extended-keys-format csi-u

      # Recommended: use RGB + kitty terminal integration
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-kitty:RGB"

      # Let terminal graphics protocols pass through tmux (needed by image.nvim/kitty backend)
      set -g allow-passthrough on

      # Nice: big scrollback
      set -g history-limit 100000

      # Alt+j: popup television picker for existing tmux sessions via sesh.
      # Enter connects, Ctrl-d kills, Ctrl-r smart-renames all sessions.
      # Keep Ctrl+j free for Neovim mappings.
      bind-key -n M-j display-popup -w 80% -h 70% -E "sesh-tv"

      # Alt+n: create/switch to a smart session for the current pane path.
      # Git repos are named repo@branch; other dirs use their basename.
      bind-key -n M-n run-shell "sc '#{pane_current_path}'"

      # Alt+h: jump to the last-used tmux session (MRU toggle).
      # Alt+l: cycle to the next active tmux/sesh session.
      bind-key -n M-h switch-client -l
      bind-key -n M-l switch-client -n

    '';
  };
}
