{ pkgs, ... }:
{
  imports = [
    ./cmp.nix
    (import ./lsp.nix { inherit pkgs; })
    (import ./config.nix { inherit pkgs; })
  ];
}
