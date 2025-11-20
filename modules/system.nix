{ lib, pkgs, modulesPath, ... }:
{
  imports = [];

  # boot.initrd.kernelModules = [ "nvme" ];
  # boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  #
  # boot.loader.grub.device = "/dev/vda";
  #
  # fileSystems."/" = {
  #   device = lib.mkForce "/dev/vda1";
  #   fsType = "ext4";
  # };

  system.stateVersion = "25.05";

  programs.hyprland.enable = true;

  environment.systemPackages = [
    pkgs.htop
  ];
  environment.sessionVariables.NIXOS_OZONE_WL = "1";


  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false; # No password required for sudo

  # Define user maxim
  users.users.maxim = {
    isNormalUser = true;
    home = "/home/maxim";
    description = "maxim";
    extraGroups = [ "wheel" "networkmanager" ];
    password = "maxim"; # Simple password for testing
  };

}
