{ config, pkgs, home-manager, nixvim, ... }:
{
 
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  
  home-manager.users.maxim = { pkgs, ... }: {

   nixpkgs.config.allowUnfree = true;
   home.stateVersion = "25.05";
   home.packages = with pkgs; [
     windsurf
     unzip
     ripgrep
     yazi
     git
   ];

   imports = [ 
     ./hyprland.nix
     ./kitty.nix
     ./waybar
     ./tmux.nix
     nixvim.homeManagerModules.nixvim 
   ];
   
   

    # programs 
    programs = {
      bash.enable = true;
      kitty.enable = true;
      git = {
       enable = true;
       settings.user.email = "dresvynnikov@gmail.com";
       settings.user.name = "sadMaxim";
      };

      nixvim = (import ./nixvim {inherit pkgs;}) // {
        defaultEditor = true;
        nixpkgs.useGlobalPackages = true;
        enable = true;
      };

    };
    

  };
}
