{ ... }:
{
  programs.opencode = {
    enable = true;
    settings = {
      "$schema" = "https://opencode.ai/config.json";
      plugin = [ "opencode-gemini-auth@latest" "opencode-openai-codex-auth@latest" "opencode-antigravity-auth@latest" ];
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

  home.file.".config/opencode/tools/project-info.ts".text = builtins.readFile ./opencode-project-info.ts;

  home.file.".config/opencode/tools/math-add.ts".text = builtins.readFile ./opencode-math-add.ts;
}
