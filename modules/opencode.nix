{ ... }:
{
  programs.opencode = {
    enable = true;
    settings = {
      "$schema" = "https://opencode.ai/config.json";
      plugin = [ "opencode-gemini-auth@latest" "opencode-openai-codex-auth@latest" "opencode-antigravity-auth@latest" ];
    };
  };
}
