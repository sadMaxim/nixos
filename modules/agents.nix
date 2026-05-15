{ pkgs, inputs, nixpkgs-unstable, lib, ... }:
let
  unstable = nixpkgs-unstable.legacyPackages.${pkgs.system};
  mgrepVersion = "0.1.12";
  mgrepSrc = unstable.fetchFromGitHub {
    owner = "mixedbread-ai";
    repo = "mgrep";
    tag = "v${mgrepVersion}";
    hash = "sha256-Tm5bOrYcV4LF7W3TxSBObnwVdFfBZPXpYbOKDyvuRAQ=";
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

  # All agents from llm-agents.nix
  agents = inputs.llm-agents.packages.${pkgs.system};

  mmxVersion = "1.0.12";
  mmxCli = pkgs.stdenv.mkDerivation {
    pname = "mmx-cli";
    version = mmxVersion;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/mmx-cli/-/mmx-cli-${mmxVersion}.tgz";
      sha256 = "sha256-oA9dOLUcVN1j1S3aDMp7/r6O+IGk3rabAw1bOd34dc0=";
    };
    nativeBuildInputs = [ pkgs.bun ];
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      echo "#!${pkgs.bash}/bin/bash" > $out/bin/mmx
      echo "exec ${pkgs.bun}/bin/bun $out/lib/node_modules/mmx-cli/dist/mmx.mjs \"\$@\"" >> $out/bin/mmx
      chmod +x $out/bin/mmx
      mkdir -p $out/lib/node_modules
      cp -R . $out/lib/node_modules/mmx-cli
      runHook postInstall
    '';
  };
in
{
  home.packages = [
    # for ai agents
    mgrepLatest
    mmxCli

    # All coding agents from llm-agents.nix
    agents.pi          # Pi coding agent
    agents.codex       # OpenAI Codex
    agents.claude-code # Anthropic Claude Code
    agents.opencode    # OpenCode agent
    agents.gemini-cli  # Google Gemini CLI
  ];

  home.file.".codex/config.toml".text = ''
    #:schema https://developers.openai.com/codex/config-schema.json

    approval_policy = "on-request"
    sandbox_mode = "workspace-write"
    web_search = "cached"

    [mcp_servers.mgrep]
    command = "${mgrepLatest}/bin/mgrep"
    args = ["mcp"]

    [features]
    shell_tool = true
    unified_exec = true
  '';

  home.file.".codex/AGENTS.md".text = ''
    # Tooling Preferences

    Prefer `mgrep` for search when it is available. Use natural-language
    queries that describe what you are looking for.

    For local codebase discovery, use `mgrep "<query>" [path]` first. If `mgrep`
    fails or is unavailable, fall back to `rg` and other standard search tools.

    For current external information, use `mgrep --web --answer "<query>"`
    first. If that fails or is unavailable, fall back to Codex's native web
    search when it is enabled.
  '';

  # Note: Run 'mmx auth login --api-key sk-cp-xxxxx' after install to configure API key
}
