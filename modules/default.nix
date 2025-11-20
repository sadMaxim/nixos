{ inputs, self, ... }:
let 
  modules = [
   ./system.nix
  ];
in
{
  
  flake.nixosConfigurations = {
    nixos = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = inputs; 
      modules = [
        { nixpkgs.config.allowUnfree = true; }
        ./system.nix
        ./home.nix
      ];
    };
  };

  perSystem = { system, pkgs, self', inputs', ... }:
    {
      packages.vm = (self.nixosConfigurations.nixos.extendModules {
        modules = [ (import ./vm.nix) ];
      }).config.system.build.vm;
    };
}
