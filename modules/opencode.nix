{ config, lib, pkgs, ... }:
let
  opencodeWrapped = pkgs.writeShellScriptBin "opencode" ''
    repo_root="$PWD"
    if [ -n "''${1-}" ] && [ -d "$1" ]; then
      repo_root="$1"
    fi
    config_source="$repo_root/.opencode"
    config_target="$HOME/.config/opencode"

    if [ -d "$config_source" ]; then
      mkdir -p "$config_target"
      for source_path in "$config_source"/*; do
        if [ -e "$source_path" ]; then
          target_path="$config_target/$(basename "$source_path")"
          ln -sfn "$source_path" "$target_path"
        fi
      done
    fi

    exec ${lib.getExe pkgs.opencode} "$@"
  '';
in
{
  programs.opencode = {
    enable = true;
    package = opencodeWrapped;
    settings = {
      "$schema" = "https://opencode.ai/config.json";
      plugin = [ "opencode-gemini-auth@latest" "opencode-openai-codex-auth@latest" "opencode-antigravity-auth@latest" ];
      tools = {
        "project-info" = true;
      };
      agent = {
        "docs-writer" = {
          description = "Writes and maintains project documentation";
          mode = "subagent";
          tools = {
            bash = false;
          };
          prompt = ''
You are a technical writer. Create clear, comprehensive documentation.
Focus on:
- Clear explanations
- Proper structure
- Code examples
- User-friendly language
'';
        };
        "security-auditor" = {
          description = "Performs security audits and identifies vulnerabilities";
          mode = "subagent";
          tools = {
            write = false;
            edit = false;
          };
          prompt = ''
You are a security expert. Focus on identifying potential security issues.
Look for:
- Input validation vulnerabilities
- Authentication and authorization flaws
- Data exposure risks
- Dependency vulnerabilities
- Configuration security issues
'';
        };
      };
    };
  };

}
