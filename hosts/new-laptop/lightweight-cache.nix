# The lightweight profile of the new laptop uses the official NixOS binary
# cache plus the Numtide cache.
#
# The Numtide cache is where the llm-agents.nix packages are pre-built, so
# it is what makes the agent set of the lightweight profile installable
# without building every agent locally.
#
# The shared configuration (configuration.nix) configures the official
# cache plus the third-party caches (nix-community, numtide, hyprland);
# on this host the lightweight profile replaces that list with the two
# caches above and their public keys, so nothing from the other caches is
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
      "https://cache.numtide.com"
    ];
    trusted-substituters = lib.mkForce [
      "https://cache.nixos.org/"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = lib.mkForce [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
}
