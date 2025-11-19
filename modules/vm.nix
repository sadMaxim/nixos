# or local testing virtual machines
{ lib, modulesPath, ... }: {
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  services.getty.autologinUser = "root";
  
  # services.displayManager.autoLogin.enable = true;
  # services.displayManager.autoLogin.user = "root";
  
  users.users.root.initialPassword = "";
  
  # Virtual Machine configuration
  virtualisation = {
    graphics = true;
    forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];
  };
}
