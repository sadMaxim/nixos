# Host module for the new laptop (AMD).
#
# Everything that is specific to this machine lives here:
#
#   * the hardware configuration (generated on the machine itself and kept
#     next to this module),
#   * the UUID of the encrypted swap container,
#   * the state version,
#   * the SSH server, which the machine is reached with,
#   * the AMD specific graphics settings.
#
# The shared `configuration.nix` is hardware agnostic, so the same module
# list can be used for every host of this flake.
{ config, lib, pkgs, lightweight ? false, ... }:
{
  # Include the results of the hardware scan of this host.
  imports =
    [ ./hardware-configuration.nix ]
    # The lightweight profile of this host uses the official NixOS cache
    # only (see the module for the details).
    ++ lib.optionals lightweight [ ./lightweight-cache.nix ];

  # Encrypted swap container of this host.
  boot.initrd.luks.devices."luks-bf4de334-d747-4933-bf9b-172871d96ef5".device =
    "/dev/disk/by-uuid/bf4de334-d747-4933-bf9b-172871d96ef5";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on this system were taken.  It is defined per host, because the
  # shared configuration must not define it (that would conflict with
  # the host modules).
  system.stateVersion = "25.05";

  # The machine is administered over the network: SSH is reachable from the
  # LAN and password authentication is allowed, like in the configuration
  # the machine is currently running.
  #
  # `mkForce` is used because other modules (modules/phone-control.nix)
  # define the same options with a keys-only policy; the policy of the
  # host wins here.
  services.openssh = {
    enable = true;
    openFirewall = lib.mkForce true;
    settings.PasswordAuthentication = lib.mkForce true;
  };

  # AMD graphics: mesa ships the radeonsi VA-API driver.  The Intel
  # specific driver and the `iHD` driver name live in the module of the
  # old host.
  hardware.graphics.extraPackages = with pkgs; [ mesa ];
}
