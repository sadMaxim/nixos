{ pkgs, ... }:
{
 imports = [./cmp.nix ./lsp.nix (import ./config.nix {inherit pkgs;})];
}
