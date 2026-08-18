{ pkgs, inputs, nixpkgs-unstable, lib, ... }:
let
  unstable = nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # All agents from llm-agents.nix
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # The OpenAI Codex subscription backend is served from chatgpt.com. Bun's
  # compiled fetch currently selects IPv4 even when IPv6 is preferred through
  # NODE_OPTIONS, so constrain this hostname at the libc resolver instead.
  # Other hosts used by Pi remain dual-stack.
  piIpv6ResolverSource = pkgs.writeText "pi-ipv6-chatgpt.c" ''
    #define _GNU_SOURCE
    #include <dlfcn.h>
    #include <netdb.h>
    #include <string.h>

    typedef int (*getaddrinfo_fn)(const char *, const char *,
                                 const struct addrinfo *, struct addrinfo **);

    int getaddrinfo(const char *node, const char *service,
                    const struct addrinfo *hints, struct addrinfo **result) {
      static getaddrinfo_fn real_getaddrinfo;
      struct addrinfo ipv6_hints;

      if (!real_getaddrinfo)
        real_getaddrinfo = (getaddrinfo_fn)dlsym(RTLD_NEXT, "getaddrinfo");

      if (node && strcmp(node, "chatgpt.com") == 0) {
        if (hints)
          ipv6_hints = *hints;
        else
          memset(&ipv6_hints, 0, sizeof(ipv6_hints));
        ipv6_hints.ai_family = AF_INET6;
        return real_getaddrinfo(node, service, &ipv6_hints, result);
      }

      return real_getaddrinfo(node, service, hints, result);
    }
  '';

  piIpv6Resolver = pkgs.runCommand "pi-ipv6-chatgpt" {
    nativeBuildInputs = [ pkgs.stdenv.cc ];
  } ''
    mkdir -p $out/lib
    $CC -shared -fPIC -O2 \
      -o $out/lib/ipv6-chatgpt.so ${piIpv6ResolverSource} -ldl
  '';

  piIpv6 = pkgs.symlinkJoin {
    name = "pi-ipv6";
    paths = [ agents.pi ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --prefix LD_PRELOAD : ${piIpv6Resolver}/lib/ipv6-chatgpt.so
    '';
  };

  mmxVersion = "1.0.16";
  mmxCli = pkgs.stdenv.mkDerivation {
    pname = "mmx-cli";
    version = mmxVersion;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/mmx-cli/-/mmx-cli-${mmxVersion}.tgz";
      sha256 = "sha256-GYu2D7ogus7bYLaAJy5dr/2HDx81a94oBN/n5BLint0=";
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

    # Coding agents from llm-agents.nix
    piIpv6             # Pi coding agent (chatgpt.com forced over IPv6)
    agents.claude-code # Anthropic Claude Code
    agents.codex       # OpenAI Codex
    agents.opencode    # OpenCode
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
