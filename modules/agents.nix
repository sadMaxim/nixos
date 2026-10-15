{ pkgs, inputs, nixpkgs-unstable, lib, ... }:
let
  unstable = nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # All agents from llm-agents.nix
  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # Pi runs as a dynamically linked Bun executable. Intercept connect(2) so
  # IPv4 fallback connections are rejected while IPv6 and local Unix sockets
  # continue to work normally.
  piIpv6OnlySource = pkgs.writeText "pi-ipv6-only.c" ''
    #define _GNU_SOURCE
    #include <dlfcn.h>
    #include <errno.h>
    #include <sys/socket.h>

    typedef int (*connect_fn)(int, const struct sockaddr *, socklen_t);

    int connect(int socket, const struct sockaddr *address,
                socklen_t address_len) {
      static connect_fn real_connect;

      if (address && address->sa_family == AF_INET) {
        errno = ENETUNREACH;
        return -1;
      }

      if (!real_connect)
        real_connect = (connect_fn)dlsym(RTLD_NEXT, "connect");

      return real_connect(socket, address, address_len);
    }
  '';

  piIpv6Only = pkgs.runCommand "pi-ipv6-only" {
    nativeBuildInputs = [ pkgs.stdenv.cc ];
  } ''
    mkdir -p $out/lib
    $CC -shared -fPIC -O2 \
      -o $out/lib/ipv6-only.so ${piIpv6OnlySource} -ldl
  '';

  piIpv6 = pkgs.symlinkJoin {
    name = "pi-ipv6";
    paths = [ agents.pi ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --set NODE_OPTIONS --dns-result-order=ipv6first \
        --prefix LD_PRELOAD : ${piIpv6Only}/lib/ipv6-only.so
    '';
  };

  mmxVersion = "1.0.22";
  mmxCli = pkgs.stdenv.mkDerivation {
    pname = "mmx-cli";
    version = mmxVersion;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/mmx-cli/-/mmx-cli-${mmxVersion}.tgz";
      sha256 = "sha256-I3dwo0Xp0J5XvvUUAtMPRU8iD0epEMkGMMJ7YzrJv2Y=";
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
    piIpv6             # Pi coding agent (IPv4 connections prohibited)
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
