# or local testing virtual machines
{ lib, modulesPath, ... }: {
  imports = [ 
  "${modulesPath}/virtualisation/qemu-vm.nix"

  ];

  services.getty.autologinUser = "root";
  
  # Set a simple password for root: "root"
  users.users.root.password = "root";
  
  # Virtual Machine configuration
  virtualisation = {
    graphics = true;
  };
}
