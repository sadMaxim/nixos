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
{ config, lib, pkgs, inputs, lightweight ? false, ... }:
let
  # The shared Neovim configuration.  It is imported here (and not read from
  # `config`, which would be a recursive reference) so that the completion
  # providers can be filtered without copying the whole configuration.
  sharedNixvim = import ../../modules/nixvim/cmp.nix;

  # Tabnine and Codeium are not used on this ThinkPad: their completion
  # sources are dropped, every other provider (nvim_lsp, luasnip, buffer,
  # nvim_lua, path) stays untouched.
  cmpSources = lib.filter (s: !(s.name == "codeium" || s.name == "cmp_tabnine"))
    sharedNixvim.plugins.cmp.settings.sources;

  # The icon table of the shared configuration maps the kinds of the removed
  # providers as well; those two entries are dropped with them.
  cmpFormat = lib.concatStringsSep "\n" (lib.filter
    (line: !(lib.hasInfix "Codeium" line || lib.hasInfix "TabNine" line))
    (lib.splitString "\n" sharedNixvim.plugins.cmp.settings.formatting.format));
in
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

  # The lightweight profile of this host installs the complete llm-agents
  # package set of modules/agents.nix (Pi with the IPv6-only wrapper,
  # Claude Code, Codex, OpenCode and mmx) — see the `allAgents` switch in
  # modules/default.nix.  The plain upstream `pi` package is deliberately
  # not added here: it would collide with the wrapped `pi` of that module.

  home-manager.users.maxim = lib.optionalAttrs (!lightweight) {
    programs.nixvim = {
      plugins.cmp-tabnine.enable = lib.mkForce false;
      plugins.codeium-nvim.enable = lib.mkForce false;
      plugins.codeium-vim.enable = lib.mkForce false;
      plugins.cmp.settings.sources = lib.mkForce cmpSources;
      plugins.cmp.settings.formatting.format = lib.mkForce cmpFormat;
    };
  };

  # AMD graphics: mesa ships the radeonsi VA-API driver.  The Intel
  # specific driver and the `iHD` driver name live in the module of the
  # old host.
  hardware.graphics.extraPackages = with pkgs; [ mesa ];
}
