{ config, pkgs, home-manager, nixvim, ironbar, nixpkgs-unstable, ... }:
{
 
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit nixpkgs-unstable; };
  
  home-manager.users.maxim = { pkgs, nixpkgs-unstable, ... }:
  let
    pgwebWrapped = pkgs.writeShellScriptBin "pgweb" ''
      set -euo pipefail
      url="''${PGWEB_URL:-postgres://maxim@/maxim?host=/run/postgresql}"
      exec ${pkgs.pgweb}/bin/pgweb \
        --bind 127.0.0.1 --listen 8081 \
        --url "$url" "$@"
    '';
  in {

   home.stateVersion = "25.05";
   home.file.".config/opencode/opencode.json".text = builtins.toJSON {
     "$schema" = "https://opencode.ai/config.json";
     plugin = [ "opencode-gemini-auth@latest" "opencode-openai-codex-auth@latest"];
   };
   home.packages = with pkgs; [
      # for ai agents
      nixpkgs-unstable.legacyPackages.${pkgs.system}.mgrep
     # Archive extraction utility
     unzip
     # Fast line-oriented regex search tool
     ripgrep
     # Terminal file manager
     yazi
     # Distributed version control system
     git
     # Tray applet for NetworkManager
     networkmanagerapplet
     # KDE Plasma file manager
     kdePackages.dolphin
     # Screen locker for Hyprland Wayland compositor
     hyprlock
     # Wayland clipboard utilities
     wl-clipboard
     # Keyboard-driven mouse control
     warpd
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
     # Process file descriptor lister
     lsof
     # Privacy-focused web browser
     brave
     # Age encryption tool
     age

     ##### ai
     # Custom tool for AI-assisted code generation/editing
     opencode
     # AI code completion tool
     codex
     # Command-line interface for the Gemini AI model
     gemini-cli

     ##### databases
     # Web-based PostgreSQL client
     pgwebWrapped

     ##### design
     # 3D creation suite
     blender
   ];
   

   imports = [ 
     ./hyprland.nix
     ./kitty.nix
     ./waybar
     ./tmux.nix
     ./programming.nix
     # ./ironbar.nix
     nixvim.homeModules.nixvim 
   ];
   


    # programs 
    programs = {
      bash.enable = true;
      kitty.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
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
