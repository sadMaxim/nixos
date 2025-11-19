{ config, pkgs, home-manager, ... }:

{
 
  imports = [ home-manager.nixosModules.home-manager ];
  # home.username = "maxim";
  # home.homeDirectory = "/home/maxim";
  #
  # home.stateVersion = "24.05";
  #
  # programs.home-manager.enable = true;
  #
  # home.packages = with pkgs; [
  #   htop
  #   tree
  #   wget
  #   curl
  #   git
  #   vim
  # ];
  #
  # programs.git = {
  #   enable = true;
  #   userName = "Your Name";
  #   userEmail = "your.email@example.com";
  #   extraConfig = {
  #     init.defaultBranch = "main";
  #   };
  # };
  #
  # programs.bash = {
  #   enable = true;
  #   shellAliases = {
  #     ll = "ls -la";
  #     ".." = "cd ..";
  #     update = "sudo nixos-rebuild switch";
  #   };
  # };
  #
  # home.sessionVariables = {
  #   EDITOR = "vim";
  # };
  #
  # File management
  # home.file = {
  #   ".config/example".source = ./dotfiles/example;
  # };
}
