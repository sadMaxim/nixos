{ lib, pkgs, modulesPath, ... }:
{
  imports = [];

  # time.timeZone = "Europe/Paris";
  # i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.05";

  programs.hyprland.enable = true;

  environment.systemPackages = [
    pkgs.htop
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";


  security.sudo.wheelNeedsPassword = false; 
  services.xserver = {
    enable = true;
  };

  # Define user maxim
  users.users.maxim = {
    isNormalUser = true;
    home = "/home/maxim";
    description = "maxim";
    extraGroups = [ "wheel" "networkmanager" ];
    password = "maxim"; # Simple password for testing
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://hyprland.cachix.org"
        "https://ghostty.cachix.org"
        "https://vicinae.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
  };

}
