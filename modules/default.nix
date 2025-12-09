{ inputs, self, ... }:
{
  
  # flake.nixosModules.default = { config, ... }: {
  #    imports = [./system.nix ./home.nix];
  # };

  
  flake.nixosConfigurations = {
    nixos = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs; 
      modules = [
        { nixpkgs.config.allowUnfree = true; }
        ../configuration.nix
        ./home.nix
        ./hostname-maps.nix
      ];
    };
  };

  perSystem = { system, pkgs, self', inputs', ... }:
    {
      packages.vm = (self.nixosConfigurations.nixos.extendModules {
        modules = [ ./vm.nix self.nixosModules.default];
      }).config.system.build.vm;
    };
}
