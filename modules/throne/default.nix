{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Built from upstream Throne 1.2.4 .deb — overrides the older
  # nixpkgs build. See ./pkgs/throne/default.nix for the derivation.
  throne = pkgs.callPackage ./pkgs/throne { };
in
{
  # We deliberately don't use `programs.throne.*` — nixpkgs 25.11 ships
  # its own programs/throne.nix that declares that option. Adding our
  # own `programs.throne.enable` collides with it. Use a distinct
  # option name so the two modules can coexist.
  options.services.throne-upstream = {
    enable = lib.mkEnableOption ''
      Throne 1.2.4 from the upstream .deb (modules/throne/pkgs/throne/),
      pinning past the older nixpkgs build. When enabled, the `throne`
      binary is added to systemPackages and appears on $PATH for all
      users.
    '';
  };

  config = lib.mkIf config.services.throne-upstream.enable {
    environment.systemPackages = [ throne ];
  };
}
