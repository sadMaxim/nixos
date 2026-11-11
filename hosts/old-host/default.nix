# Host module for the original desktop (Intel) machine.
#
# Everything that is specific to this machine lives here:
#
#   * the hardware configuration (imported from the repository root, which
#     is where the generated `hardware-configuration.nix` of this host is
#     kept — see the note at the top of that file),
#   * the UUID of the encrypted swap container,
#   * the state version,
#   * the Intel specific graphics settings.
#
# The shared `configuration.nix` is hardware agnostic, so the same module
# list can be used for every host of this flake.
{ config, lib, pkgs, ... }:
{
  # Include the results of the hardware scan of this host.
  imports = [ ../../hardware-configuration.nix ];

  # Encrypted swap container of this host.
  boot.initrd.luks.devices."luks-67f943c7-079c-472e-9335-0d315c671c40".device =
    "/dev/disk/by-uuid/67f943c7-079c-472e-9335-0d315c671c40";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on this system were taken.  It is defined per host, because the
  # shared configuration must not define it (that would conflict with
  # the host modules).
  system.stateVersion = "25.05";

  # Kaby Lake Iris Plus 640: hardware H.264/HEVC decoding for Moonlight.
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
}
