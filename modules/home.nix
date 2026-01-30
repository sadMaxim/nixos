{ config, pkgs, home-manager, nixvim, ironbar, ... }:
{
 
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  
  home-manager.users.maxim = { pkgs, ... }:
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
   home.packages = with pkgs; [
     unzip
     ripgrep
     yazi
     git
     networkmanagerapplet
     # udiskie
     kdePackages.dolphin
     hyprlock
     windsurf
     wl-clipboard
     gemini-cli
     codex
     warpd
     pwvucontrol
     brightnessctl
     ddcutil
     dmidecode
     nodejs
     brave
     age
     # databases
     pgwebWrapped
     # design
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
