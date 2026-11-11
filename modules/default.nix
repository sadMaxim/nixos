{ inputs, self, ... }:
{
  
  # flake.nixosModules.default = { config, ... }: {
  #    imports = [./system.nix ./home.nix];
  # };

  
  flake.nixosConfigurations =
    let
      # One module list, two profiles per host:
      #   <host>              -> the full configuration
      #   <host>-lightweight  -> the same configuration without the nixvim
      #                          and llm-agents packages (see modules/home.nix)
      #
      # The host module holds everything that is specific to the machine
      # (hardware configuration, LUKS devices, state version, graphics
      # driver, ...), the profile is handed to the modules through the
      # `lightweight` special argument.
      mkSystem = hostModule: lightweight: inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = inputs // { inherit inputs lightweight; };
        modules = [
          { nixpkgs.config.allowUnfree = true; }
          ../configuration.nix
          hostModule
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
      # Old host (Intel) — the machine this flake was written for.
      nixos = mkSystem ../hosts/old-host false;
      nixos-lightweight = mkSystem ../hosts/old-host true;
      # New laptop (AMD).
      nixos-new-laptop = mkSystem ../hosts/new-laptop false;
      nixos-new-laptop-lightweight = mkSystem ../hosts/new-laptop true;
    };

  perSystem = { system, pkgs, self', inputs', ... }:
    {
      packages.vm = (self.nixosConfigurations.nixos.extendModules {
        modules = [ ./vm.nix self.nixosModules.default];
      }).config.system.build.vm;
    };
}
