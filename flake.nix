{
  description = "nixos";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    # pip2nix.url ="github:nix-community/pip2nix"; 
    # ironbar.url = "github:nix-community/home-manager";
    # ironbar.inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./shell.nix
        ./modules
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      flake.herculesCI.ciSystems = [ "x86_64-linux" ];
    };
}
