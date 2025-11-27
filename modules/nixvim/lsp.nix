{ pkgs, ... }:
let
  flakePath = builtins.toString ../..;
in
{
  plugins.lsp = {
    enable = true;
    servers = {
      pyright.enable = true;
      nixd = {
        enable = true;
        settings = {
          nixpkgs = {
            expr = "import <nixpkgs> { }";
          };
          formatting.command = [
            (pkgs.lib.getExe pkgs.alejandra)
          ];
          options = {
            nixos = {
              expr = "(builtins.getFlake \"${flakePath}\").nixosConfigurations.nixos.options";
            };
          };
        };
      };
      purescriptls.enable = true;
      purescriptls.filetypes = ["dhall" "purescript"];
      purescriptls.package = null;

      rust_analyzer.enable = true;
      gopls.enable = true;

      # haskell
      # hls.enable = true;  # Enable HLS
      # hls.package = null; # Use the HLS from direnv (nix develop)
      # hls.cmd = [ "haskell-language-server" "--lsp" ]; # Ensure it runs from your environment
      # hls.autostart = true;  # Automatically start HLS
      svelte.enable = true;
      # aiken.enable = true;
      ts_ls.enable = true;
    };
  };



  plugins.lsp-format = {
    enable = true;
    lspServersToEnable = ["purescriptls"];
  };
}
