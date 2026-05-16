{ config, lib, pkgs, inputs, home-manager, nixpkgs-unstable, ... }:
{
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup";
  home-manager.extraSpecialArgs = { inherit nixpkgs-unstable inputs; };
  
  home-manager.users.maxim = { pkgs, nixpkgs-unstable, inputs, ... }:
  let
    unstable = nixpkgs-unstable.legacyPackages.${pkgs.system};
    pgwebWrapped = pkgs.writeShellScriptBin "pgweb" ''
      set -euo pipefail
      url="''${PGWEB_URL:-postgres://maxim@/maxim?host=/run/postgresql}"
      exec ${pkgs.pgweb}/bin/pgweb \
        --bind 127.0.0.1 --listen 8081 \
        --url "$url" "$@"
    '';
    pychessWrapped = pkgs.symlinkJoin {
      name = "pychess";
      paths = [ pkgs.pychess ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/pychess \
          --prefix PATH : ${lib.makeBinPath [ pkgs.stockfish ]}
      '';
    };
    sshUtils = pkgs.writeShellApplication {
      name = "ssh_utils";
      runtimeInputs = [
        pkgs.git
        pkgs.inotify-tools
        pkgs.openssh
        pkgs.python3
        pkgs.rsync
      ];
      text = ''
        exec ${pkgs.python3}/bin/python ${./ssh_utils.py} "$@"
      '';
    };
  in {

     home.stateVersion = "25.05";

    # Groq API key is loaded at shell startup from ~/secrets/GROQ_WHISPER.

   home.packages = with pkgs; [
     # Archive extraction utility
     unzip
     # Fast line-oriented regex search tool
     ripgrep
     # Terminal file manager
     yazi
     # Distributed version control system
     git
      # Chess engine
      stockfish
      # Wayland-native chess GUI
      pychessWrapped
      # Tray applet for NetworkManager
      networkmanagerapplet
     # Replacement for Dolphin (GNOME Files)
     nautilus
     adwaita-icon-theme  # Essential for icons to work "out of the box"
     # Screen locker for Hyprland Wayland compositor
     hyprlock
     # Wayland clipboard utilities
     wl-clipboard
     # Keyboard-driven pointer tool for Wayland
     wl-kbptr
     # PulseAudio/PipeWire volume control utility
     pwvucontrol
     # Command-line utility to control screen brightness
     brightnessctl
     # DDC/CI control for monitors
     ddcutil
     # DMI table decoder for hardware information
     dmidecode
      # JavaScript runtime environment
      nodejs
       # Haskell Hoogle search CLI
       pkgs.haskellPackages.hoogle
       # Process file descriptor lister
      lsof
      # RunPod command-line interface
      runpodctl
      # Privacy-focused web browser
      brave
     # Desktop Telegram client
     telegram-desktop
        # Age encryption tool
        age
      # Image manipulation tool
      imagemagick

      ##### ai
      # Groq Whisper STT - speech to text via Groq API (OpenAI-compatible)
      (pkgs.writeShellScriptBin "whisper-grok" ''
        set -euo pipefail
        API_KEY="''${GROQ_API_KEY:-}"
        if [ -z "$API_KEY" ]; then
          echo "Error: GROQ_API_KEY environment variable not set" >&2
          echo "Set it with: export GROQ_API_KEY=your_key" >&2
          exit 1
        fi
        MODEL="''${2:-whisper-large-v3-turbo}"
        curl -s https://api.groq.com/v1/audio/transcriptions \
          -H "Authorization: Bearer $API_KEY" \
          -F "model=$MODEL" \
          -F "file=@$1"
      '')

      ##### ai

      ##### databases
      # Web-based PostgreSQL client
      pgwebWrapped

      ##### ssh tools
      sshUtils

     ##### design
     # 3D creation suite
     blender
     # Wayland screenshot tools
     grim
     slurp
     xvfb-run
    ];
   

   imports = [ 
     ./hyprland.nix
     ./kitty.nix
     ./waybar
     ./tmux.nix
     ./programming.nix
     ./agents.nix
      inputs.nixvim.homeModules.nixvim 
   ];
   


    # programs 
    programs = {
      bash = {
        enable = true;
        # Source Groq API key from secrets file at shell startup
        profileExtra = ''
          # Groq Whisper API key
          if [ -f "''${HOME}/secrets/GROQ_WHISPER" ]; then
            export GROQ_API_KEY="$(cat "''${HOME}/secrets/GROQ_WHISPER")"
          fi
        '';
      };
      kitty.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      vscode = {
        enable = true;
        profiles.default.extensions = with pkgs.vscode-extensions; [
          saoudrizwan.claude-dev
        ];
      };
      # git
      git = {
       enable = true;
       settings.user.email = "dresvynnikov@gmail.com";
       settings.user.name = "sadMaxim";
       settings.credential.helper = "store";
      };

      nixvim = (import ./nixvim {inherit pkgs;}) // {
        defaultEditor = true;
        nixpkgs.useGlobalPackages = true;
        enable = true;
      };

    };
    

  };
}
