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
      # Keep Ctrl+j free for Neovim mappings.
      # Uses sesh/tv from your Home Manager profile PATH.
      bind-key -n M-j display-popup -w 80% -h 70% -E "sesh connect -s \"$(tv --source-command 'sesh list -t' --preview-command 'tmux list-windows -t {} && printf \\\"\\n\\\" && tmux capture-pane -ep -t {} | tail -40' --preview-size 60)\""

      # Alt+h / Alt+l: cycle through active tmux/sesh sessions without prefix.
      bind-key -n M-h switch-client -p
      bind-key -n M-l switch-client -n

    '';
  };
}
