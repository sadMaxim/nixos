{ inputs, self, ... }:
{
  
  # flake.nixosModules.default = { config, ... }: {
  #    imports = [./system.nix ./home.nix];
  # };

  
  flake.nixosConfigurations =
    let
      # One module list, two profiles:
      #   nixos            -> the full configuration
      #   nixos-lightweight -> the same configuration without the nixvim and
      #                       llm-agents packages (see modules/home.nix)
      # The profile is handed to the modules through the `lightweight`
      # special argument.
      mkSystem = lightweight: inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs // { inherit inputs lightweight; };
        modules = [
          { nixpkgs.config.allowUnfree = true; }
          ../configuration.nix
          ./home.nix
          ./hostname-maps.nix
          ./ipv6-prefer.nix
          ./amneziawg-vdsina
          ./throne
          ./sing-box
        ];
      };
    in
    {
      nixos = mkSystem false;
      nixos-lightweight = mkSystem true;
    };

  perSystem = { system, pkgs, self', inputs', ... }:
    {
      packages.vm = (self.nixosConfigurations.nixos.extendModules {
        modules = [ ./vm.nix self.nixosModules.default];
      }).config.system.build.vm;
    };
}
