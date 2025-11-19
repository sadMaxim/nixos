{ lib, pkgs, modulesPath, ... }:
{
  imports = [
    # "${modulesPath}/virtualisation/digital-ocean-config.nix" 
  ];

  boot.initrd.kernelModules = [ "nvme" ];
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];

  boot.loader.grub.device = "/dev/vda";

  fileSystems."/" = {
    device = lib.mkForce "/dev/vda1";
    fsType = "ext4";
  };

  system.stateVersion = "25.05";

  environment.systemPackages = [
    pkgs.htop
  ];

  services.xserver.enable = true;

}
