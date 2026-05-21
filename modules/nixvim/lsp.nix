{ pkgs, ... }:
let
  flakePath = builtins.toString ../..;
in
{
  plugins.lsp = {
    enable = true;
    servers = {
      pyright.enable = true;
      # pyright.package = null;
      nixd = {
        enable = true;
        settings = {
          nixpkgs.expr = "import <nixpkgs> { }";
          options = {
            nixos.expr = ''(builtins.getFlake "${flakePath}").nixosConfigurations.nixos.options'';
            home-manager.expr = ''(builtins.getFlake "${flakePath}").nixosConfigurations.nixos.options.home-manager.users.type.getSubOptions []'';
          };
        };
      };
      purescriptls.enable = true;
      purescriptls.filetypes = ["dhall" "purescript"];
      purescriptls.package = null;
      rust_analyzer = {
        enable = true;
        installCargo = true;
        installRustc = true;
      };
      gopls.enable = true;


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
