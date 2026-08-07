{
  config,
  pkgs,
  lib,
}:
let
  kmod = pkgs.callPackage ./pkgs/amneziawg-kmod {
    kernel = config.boot.kernelPackages.kernel;
  };
  tools = pkgs.callPackage ./pkgs/amneziawg-tools { };
in
{
  options.services.amneziawg-vdsina.enable = lib.mkEnableOption ''
    AmneziaWG tunnel to vdsina (138.16.162.74:51821), toggleable via NM as
    the "awg-vdsina" connection.
  '';

  config = lib.mkIf config.services.amneziawg-vdsina.enable {
    boot.extraModulePackages = [ kmod ];
    boot.kernelModules = [ "amneziawg" ];

    environment.systemPackages = [ tools ];

    # Install the dispatcher so NM can swap plain WG → amneziawg on toggle.
    environment.etc."NetworkManager/dispatcher.d/awg-vdsina".source =
      ./dispatcher.sh;
    environment.etc."NetworkManager/dispatcher.d/awg-vdsina".mode = "0755";

    # AWG server endpoint (UDP 51821)
    networking.firewall.allowedUDPPorts = [ 51821 ];

    # The secret-laden files (client config + NM connection) live in the
    # private devops repo at vdsina/amneziawg/laptop/. They are deployed
    # manually to /etc/ — see the deploy.sh script there.
  };
}