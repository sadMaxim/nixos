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
      nixd.enable = true; 
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
