# The lightweight profile of the new laptop uses the official NixOS binary
# cache only.
#
# The shared configuration (configuration.nix) configures the official
# cache plus the third-party caches (nix-community, numtide, hyprland);
# on this host the lightweight profile replaces that list with the
# official cache and its public key, so nothing from the other caches is
# substituted.  `mkForce` is needed because the shared configuration
# defines the same options.
#
# The full profile of this host (`nixos-new-laptop`) keeps the caches of
# the shared configuration.
{ config, lib, ... }:
{
  nix.settings = {
    substituters = lib.mkForce [
      "https://cache.nixos.org/"
    ];
    trusted-substituters = lib.mkForce [
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = lib.mkForce [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
}
