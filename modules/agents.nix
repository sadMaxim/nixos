{ pkgs, inputs, nixpkgs-unstable, lib, ... }:
let
  unstable = nixpkgs-unstable.legacyPackages.${pkgs.system};

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
    mmxCli

    # Coding agents from llm-agents.nix (pi only; codex disabled per user request)
    agents.pi          # Pi coding agent
    # agents.codex       # OpenAI Codex (disabled)
  ];

  # home.file.".codex/config.toml".text = '' (disabled per user request)
  #   #:schema https://developers.openai.com/codex/config-schema.json
  #   approval_policy = "on-request"
  #   sandbox_mode = "workspace-write"
  #   web_search = "cached"
  #   [features]
  #   shell_tool = true
  #   unified_exec = true
  # '';

  # home.file=".codex/AGENTS.md".text = '' (disabled per user request)
  #   # Tooling Preferences
  #   For local codebase discovery, use `rg "<query>" [path]` first. If `rg`
  #   fails or is unavailable, fall back to standard search tools.
  #   For current external information, use Codex's native web search.
  # '';

  # Note: Run 'mmx auth login --api-key sk-cp-xxxxx' after install to configure API key
}
