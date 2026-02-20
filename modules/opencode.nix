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

  opencodeConfigText = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "plugin": [
        "opencode-antigravity-auth@latest",
        "opencode-openai-codex-auth",
        "@noodlbox/opencode-plugin"
      ],
      "tools": {
        "websearch": false,
        "grep": false,
        "glob": false,
        "mgrep": true
      }
    }
  '';

  opencodeConfigTemplate = pkgs.writeText "opencode.json" opencodeConfigText;

  opencodeWrapped = pkgs.writeShellScriptBin "opencode" ''
    set -euo pipefail

    # Find repo root; fall back to current directory
    if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
      :
    else
      repo_root="$(pwd -P)"
    fi

    # If the repo defines .opencode/opencode.json, prefer it
    if [ -f "$repo_root/.opencode/opencode.json" ]; then
      export OPENCODE_CONFIG_DIR="$repo_root/.opencode"
    fi

    # Antigravity auth can print status lines while OpenCode redraws the TUI,
    # which shows up as visual artifacts. Keep plugin logs quiet by default.
    : "''${OPENCODE_ANTIGRAVITY_QUIET:=1}"
    export OPENCODE_ANTIGRAVITY_QUIET

    has_port=false
    port_value=""
    first_positional=""
    info_only=false
    prev=""
    for arg in "$@"; do
      if [ "$prev" = "--port" ]; then
        has_port=true
        port_value="$arg"
        prev=""
        break
      fi
      case "$arg" in
        -h|--help|-v|--version)
          info_only=true
          ;;
        --port=*)
          has_port=true
          port_value="''${arg#--port=}"
          break
          ;;
        --*)
          prev="$arg"
          continue
          ;;
        -*)
          continue
          ;;
        *)
          if [ -z "$first_positional" ]; then
            first_positional="$arg"
          fi
          ;;
      esac
      prev=""
    done

    # Keep subcommands (auth, models, run, etc.) untouched. Inject --port
    # only for the default TUI command, where first positional arg is either
    # absent or treated as [project].
    is_subcommand=false
    case "$first_positional" in
      completion|acp|mcp|attach|run|debug|auth|agent|upgrade|uninstall|serve|web|models|stats|export|import|github|pr|session|db)
        is_subcommand=true
        ;;
    esac

    # Ensure every repo has a local opencode port for nvim integration.
    # If caller didn't pass --port, pick a currently free one.
    if [ "$has_port" = false ] && [ "$is_subcommand" = false ] && [ "$info_only" = false ]; then
      is_port_in_use() {
        local p="$1"
        if command -v ss >/dev/null 2>&1; then
          ss -ltn "( sport = :$p )" 2>/dev/null | grep -q ":$p"
          return $?
        fi
        if command -v lsof >/dev/null 2>&1; then
          lsof -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1
          return $?
        fi
        return 1
      }

      for _ in $(seq 1 200); do
        candidate="$((20000 + (RANDOM % 30000)))"
        if ! is_port_in_use "$candidate"; then
          port_value="$candidate"
          break
        fi
      done

      if [ -z "$port_value" ]; then
        repo_hash="$(printf '%s' "$repo_root" | cksum | cut -d' ' -f1)"
        port_value="$((20000 + (repo_hash % 20000)))"
      fi

      set -- --port "$port_value" "$@"
    fi

    if [ -n "$port_value" ]; then
      mkdir -p "$repo_root/.opencode"
      printf '%s\n' "$port_value" > "$repo_root/.opencode/nvim-port"
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

  home.activation.ensureMutableOpencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="$HOME/.config/opencode"
    config_file="$config_dir/opencode.json"

    mkdir -p "$config_dir"

    if [ -L "$config_file" ]; then
      target="$(readlink -f "$config_file" || true)"
      case "$target" in
        /nix/store/*)
          rm -f "$config_file"
          ;;
      esac
    fi

    if [ ! -f "$config_file" ]; then
      install -m 0644 "${opencodeConfigTemplate}" "$config_file"
    fi
  '';
}
