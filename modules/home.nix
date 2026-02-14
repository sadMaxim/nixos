{ config, lib, pkgs, inputs, home-manager, nixpkgs-unstable, ... }:
{
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = { inherit nixpkgs-unstable inputs; };
  
  home-manager.users.maxim = { pkgs, nixpkgs-unstable, inputs, ... }:
  let
    unstable = nixpkgs-unstable.legacyPackages.${pkgs.system};
    mgrepVersion = "0.1.10";
    mgrepSrc = unstable.fetchFromGitHub {
      owner = "mixedbread-ai";
      repo = "mgrep";
      tag = "v${mgrepVersion}";
      hash = "sha256-Njs0h2Roqm9xK8TV7BqrR5EwpK+ONNl3ct1fHU0UZEY=";
    };
    mgrepPnpmDeps = unstable.fetchPnpmDeps {
      pname = "mgrep";
      version = mgrepVersion;
      src = mgrepSrc;
      fetcherVersion = 2;
      hash = "sha256-qNsYMp25OAbbv+K7qvNRB+7QzzrgtrKQkUoe9IMIR5c=";
    };
    mgrepLatest = unstable.mgrep.overrideAttrs (_: {
      version = mgrepVersion;
      src = mgrepSrc;
      pnpmDeps = mgrepPnpmDeps;
    });
    nodePackages = pkgs.nodePackages_latest or pkgs.nodePackages;
    codexVersion = "0.101.0";
    codexSrc = pkgs.fetchFromGitHub {
      owner = "openai";
      repo = "codex";
      rev = "rust-v${codexVersion}";
      hash = "sha256-m2Jq7fbSXQ/O3bNBr6zbnQERhk2FZXb+AlGZsHn8GuQ=";
    };
    codexPnpmDeps = pkgs.fetchPnpmDeps {
      pname = "codex-cli";
      version = codexVersion;
      src = codexSrc;
      fetcherVersion = 2;
      hash = "sha256-kYUiPS+HoZb07wf4zn0xr61pHAAgVmkYTvmwOBXGVJI=";
    };
    codexPlatform =
      if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then
        {
          moduleName = "codex-linux-x64";
          tarballSuffix = "linux-x64";
        }
      else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then
        {
          moduleName = "codex-linux-arm64";
          tarballSuffix = "linux-arm64";
        }
      else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isx86_64 then
        {
          moduleName = "codex-darwin-x64";
          tarballSuffix = "darwin-x64";
        }
      else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
        {
          moduleName = "codex-darwin-arm64";
          tarballSuffix = "darwin-arm64";
        }
      else
        throw "Unsupported platform for codex-cli";
    codexPlatformSrc = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@openai/codex/-/" +
        "codex-${codexVersion}-${codexPlatform.tarballSuffix}.tgz";
      hash = "sha256-Z7Of6kE/g6hWv0EuBL8Bj3/KQASvxhewcSsiOuxtmV4=";
    };
    codexCli = if nodePackages ? "@openai/codex" then
      nodePackages."@openai/codex"
    else
      pkgs.stdenv.mkDerivation {
        pname = "codex-cli";
        version = codexVersion;
        src = codexSrc;
        pnpmDeps = codexPnpmDeps;
        nativeBuildInputs = [
          pkgs.nodejs
          pkgs.pnpm
          pkgs.pnpmConfigHook
          pkgs.makeWrapper
        ];
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out/libexec/codex-cli
          cp -R codex-cli/* $out/libexec/codex-cli/
          mkdir -p $out/libexec/codex-cli/node_modules/@openai/${codexPlatform.moduleName}
          tar -xzf ${codexPlatformSrc} \
            -C $out/libexec/codex-cli/node_modules/@openai/${codexPlatform.moduleName} \
            --strip-components=1
          mkdir -p $out/bin
          makeWrapper ${pkgs.nodejs}/bin/node $out/bin/codex \
            --add-flags "$out/libexec/codex-cli/bin/codex.js"
          runHook postInstall
        '';
      };
    pgwebWrapped = pkgs.writeShellScriptBin "pgweb" ''
      set -euo pipefail
      url="''${PGWEB_URL:-postgres://maxim@/maxim?host=/run/postgresql}"
      exec ${pkgs.pgweb}/bin/pgweb \
        --bind 127.0.0.1 --listen 8081 \
        --url "$url" "$@"
    '';
  in {

   home.stateVersion = "25.05";

   home.packages = with pkgs; [
      # for ai agents
      mgrepLatest
     # Archive extraction utility
     unzip
     # Fast line-oriented regex search tool
     ripgrep
     # Terminal file manager
     yazi
     # Distributed version control system
     git
     # Tray applet for NetworkManager
     networkmanagerapplet
     # Replacement for Dolphin (GNOME Files)
     nautilus
     adwaita-icon-theme  # Essential for icons to work "out of the box"
     # Screen locker for Hyprland Wayland compositor
     hyprlock
     # Wayland clipboard utilities
     wl-clipboard
     # Keyboard-driven pointer tool for Wayland
     wl-kbptr
     # PulseAudio/PipeWire volume control utility
     pwvucontrol
     # Command-line utility to control screen brightness
     brightnessctl
     # DDC/CI control for monitors
     ddcutil
     # DMI table decoder for hardware information
     dmidecode
     # JavaScript runtime environment
     nodejs
     # Process file descriptor lister
     lsof
     # Privacy-focused web browser
     brave
     # Age encryption tool
     age

     ##### ai
     # Custom tool for AI-assisted code generation/editing
      # AI code completion tool
      codexCli
     # Command-line interface for the Gemini AI model
     gemini-cli

     ##### databases
     # Web-based PostgreSQL client
     pgwebWrapped

     ##### design
     # 3D creation suite
     blender
     # Wayland screenshot tools
     grim
     slurp
   ];
   

   imports = [ 
     ./hyprland.nix
     ./kitty.nix
     ./waybar
     ./tmux.nix
     ./programming.nix
     ./opencode.nix
      inputs.nixvim.homeModules.nixvim 
   ];
   


    # programs 
    programs = {
      bash.enable = true;
      kitty.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      # git
      git = {
       enable = true;
       settings.user.email = "dresvynnikov@gmail.com";
       settings.user.name = "sadMaxim";
       settings.credential.helper = "store";
      };

      nixvim = (import ./nixvim {inherit pkgs;}) // {
        defaultEditor = true;
        nixpkgs.useGlobalPackages = true;
        enable = true;
      };

    };
    

  };
}
