{ config, lib, pkgs, ... }:
let
  opencodeWrapped = pkgs.writeShellScriptBin "opencode" ''
    set -euo pipefail

    # Find repo root; fall back to current directory
    if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
      :
    else
      repo_root="$(pwd -P)"
    fi

    # If the repo defines .opencode/, prefer it
    if [ -d "$repo_root/.opencode" ]; then
      export OPENCODE_CONFIG_DIR="$repo_root/.opencode"
    fi

    exec ${lib.getExe pkgs.opencode} "$@"
  '';
in
{
  programs.opencode = {
    enable = true;
    package = opencodeWrapped;

    # No global settings here. Keep global plugins in:
    # ~/.config/opencode/opencode.json
  };

  xdg.configFile."opencode/opencode.json" = {
    force = true;
    text = ''
      {
        "$schema": "https://opencode.ai/config.json",
        "tools": {
          "websearch": false,
          "grep": false,
          "glob": false,
          "mgrep": true
        }
      }
    '';
  };
}
