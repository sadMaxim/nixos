{ config, lib, pkgs, ... }:
let
  opencodeWrapped = pkgs.writeShellScriptBin "opencode" ''
    repo_root="$(pwd -P)"
    if [ -n "''${1-}" ] && [ -d "$1" ]; then
      repo_root="$(cd "$1" && pwd -P)"
    fi
    tool_source="$repo_root/.opencode/tool"
    if [ ! -d "$tool_source" ] && [ -d "$repo_root/.opencode/tools" ]; then
      tool_source="$repo_root/.opencode/tools"
    fi
    config_dir="$HOME/.config/opencode"
    tool_target="$config_dir/tool"

    # Clean up all symlinks in global config before linking new tools.
    if [ -d "$config_dir" ]; then
      find "$config_dir" -mindepth 1 -type l -exec rm -f {} +
    fi

    if [ -d "$tool_source" ]; then
      mkdir -p "$config_dir"
      ln -sfn "$tool_source" "$tool_target"
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
