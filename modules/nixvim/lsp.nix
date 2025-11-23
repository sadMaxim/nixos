{
    plugins.lsp = {
      enable = true;
      servers = {
        pyright.enable = true;
        pyright.package = null;

        # nixd.enable = true;

        purescriptls.enable = true;
        purescriptls.package = null;
        purescriptls.filetypes = ["dhall" "purescript"];

        rust_analyzer.enable = true;
        rust_analyzer.installRustc = false;
        rust_analyzer.installCargo = false;

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
