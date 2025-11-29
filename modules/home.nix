{ config, pkgs, home-manager, nixvim, ironbar, ... }:
{
 
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  
  home-manager.users.maxim = { pkgs, ... }: {

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
     blueman
   ];
   

   imports = [ 
     ./hyprland.nix
     ./kitty.nix
     ./waybar
     ./tmux.nix
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
