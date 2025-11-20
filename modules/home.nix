{ config, pkgs, home-manager, nixvim, ... }:
{
 
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  
  home-manager.users.maxim = { pkgs, ... }: {
   imports = [ 
     ./hyprland.nix
     nixvim.homeManagerModules.nixvim 
   ];
   
   nixpkgs.config.allowUnfree = true;
   nixpkgs.config.allowUnfreePredicate = (_:true);
   
   home.packages = with pkgs; [
     wofi
   ];
   home.stateVersion = "25.05";

    # programs 
    programs = {
      bash.enable = true;
      kitty.enable = true;
      git = {
       enable = true;
       settings.user.email = "dresvynnikov@gmail.com";
       settings.user.name = "sadMaxim";
      };

      # nixvim = (import ./nixvim {inherit pkgs;}) // {
      #   enable = true;
      # };

    };
    

  };
}
