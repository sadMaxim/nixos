{ config, lib, pkgs, inputs, ... }:
let
  opencodeDefaultPackage = lib.attrByPath [ "packages" pkgs.system "default" ] null inputs.opencode;
  opencodeNamedPackage = lib.attrByPath [ "packages" pkgs.system "opencode" ] null inputs.opencode;
  opencodePackage =
    if opencodeDefaultPackage != null then
      opencodeDefaultPackage
    else if opencodeNamedPackage != null then
      opencodeNamedPackage
    else
      throw "opencode flake does not expose packages.${pkgs.system}.default or packages.${pkgs.system}.opencode";
  opencodePatchedPackage = opencodePackage.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace packages/script/src/index.ts \
        --replace-fail \
        "if (!semver.satisfies(process.versions.bun, expectedBunVersionRange)) {" \
        "if (false && !semver.satisfies(process.versions.bun, expectedBunVersionRange)) {"
    '';
  });

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

    exec ${lib.getExe opencodePatchedPackage} "$@"
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
