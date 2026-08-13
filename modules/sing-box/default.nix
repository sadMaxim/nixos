{
  config,
  pkgs,
  lib,
  ...
}:
let
  # sing-box 1.13.18 from the upstream glibc Linux amd64 release.
  sing-box = pkgs.callPackage ./pkgs/sing-box { };
in
{
  # Distinct option name to avoid colliding with anything nixpkgs
  # ships for sing-box (services.sing-box or similar).
  options.services.sing-box-upstream = {
    enable = lib.mkEnableOption ''
      sing-box 1.13.18 from the upstream Linux release, overriding
      the nixpkgs build. When enabled, the `sing-box` binary is
      available on $PATH system-wide.
    '';
  };

  config = lib.mkIf config.services.sing-box-upstream.enable {
    environment.systemPackages = [ sing-box ];
  };
}
