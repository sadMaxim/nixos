# Route64.org 6in4 (SIT) IPv6 tunnel — Stockholm POP.
#
# Status check:  curl --proxy socks5h://127.0.0.1:1080 \
#                   https://manager.route64.org/api/<KEY>/tunnelbroker/34263/remote/79.165.38.189
#
# Why this exists: gives this laptop a global IPv6 so it can reach
# v6-only hosts (e.g. Timeweb Cloud box 2a03:6f00:a::2:b58c) and bypass
# Russian DPI for v6-capable services (YouTube, Meta, etc.) — the
# Russian ISP sees only IP proto 41 to Route64, never the inner v6.
#
# Bring-up:
#   1. The tunnel was created in manager.route64.org → #34263 (Stockholm).
#   2. `sudo nixos-rebuild switch`.
#   3. `route64-status` should show `route64-ipv6` UP with 2a11:6c7:f30:2f::2/64
#      and a default v6 route via 2a11:6c7:f30:2f::1.
#   4. `curl -6 https://api64.ipify.org` returns a v6 (Route64's egress).
#   5. `route64-heartbeat.timer` keeps Route64's view of our v4 fresh every 5 min.
#
# When our ISP rotates our v4, the heartbeat detects the new IP via
# api.ipify.org and pushes it to Route64; the tunnel self-heals within
# one heartbeat period.
#
# Secrets:
#   `apiKeyFile` is read at runtime via systemd's LoadCredential — the
#   key never appears in any nix file (which are committed to a public
#   GitHub repo). Default points to /home/maxim/secrets/ROUTE64.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.networking.route64-tunnel;
  inherit (lib) mkEnableOption mkOption types mkIf default;

  # systemd LoadCredential makes the contents of this path available at
  # $CREDENTIALS_DIRECTORY/api-key at runtime, owned by the service's UID,
  # not world-readable.
  apiKeyCredName = "api-key";
in
{
  options.networking.route64-tunnel = {
    enable = mkEnableOption "Route64.org free IPv6 SIT tunnel";

    serverIPv4 = mkOption {
      type = types.str;
      description = "Route64 tunnel server IPv4 (Stockholm POP).";
      example = "192.67.33.15";
    };

    serverIPv6 = mkOption {
      type = types.str;
      description = "Route64 server-side IPv6 (their side of the tunnel).";
      example = "2a11:6c7:f30:2f::1";
    };

    clientIPv6 = mkOption {
      type = types.str;
      description = "Our client-side IPv6 (our side of the tunnel).";
      example = "2a11:6c7:f30:2f::2";
    };

    routedPrefix = mkOption {
      type = types.str;
      description = "Routed /64 (or /56) subnet Route64 announces for us.";
      example = "2a11:6c7:f30:2f::/64";
    };

    clientIPv4 = mkOption {
      type = types.str;
      description = "Our public IPv4 — what Route64 has registered.";
      example = "79.165.38.189";
    };

    tunnelId = mkOption {
      type = types.str;
      description = "Route64 tunnel ID (numeric). Visible in the URL, not secret.";
      example = "34263";
    };

    apiKeyFile = mkOption {
      type = types.path;
      description = "Path to a file containing the Route64 API key (single line, no trailing newline required). Read at runtime via systemd LoadCredential — the key never enters any committed nix file.";
      default = /home/maxim/secrets/ROUTE64;
      example = "/home/maxim/secrets/ROUTE64";
    };
  };

  config = mkIf cfg.enable {
    # SIT (6in4) tunnel via NetworkManager's ip-tunnel connection type.
    networking.networkmanager.connectionFiles."route64-ipv6" = {
      permissions = "";
      contents = ''
        [connection]
        id=route64-ipv6
        uuid=c1b7f0c4-1f7e-4b3e-9a4f-2e6d8a4f7c2a
        type=ip-tunnel
        interface-name=route64-ipv6
        autoconnect=true
        autoconnect-priority=10

        [ip-tunnel]
        mode=4
        local=${cfg.clientIPv4}
        remote=${cfg.serverIPv4}
        ttl=255

        [ipv6]
        method=manual
        addresses=${cfg.clientIPv6}/64
        gateway=${cfg.serverIPv6}

        [ipv4]
        method=disabled
      '';
    };

    # Heartbeat: re-assert our current v4 to Route64 every 5 min so the
    # tunnel survives ISP rotations. The API key is loaded from
    # cfg.apiKeyFile via systemd LoadCredential — never appears in any
    # committed file. We fetch api.ipify.org to learn our current
    # public v4.
    systemd.services.route64-heartbeat = {
      description = "Route64 tunnel endpoint heartbeat";
      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;
        CacheDirectory = "route64-tunnel";
        LoadCredential = "${apiKeyCredName}:${cfg.apiKeyFile}";
      };
      script = ''
        set -euo pipefail
        MY_IP=$(${pkgs.curl}/bin/curl -fsS --max-time 10 https://api.ipify.org) || { echo "could not detect public v4"; exit 0; }
        KEY=$(cat "$CREDENTIALS_DIRECTORY/${apiKeyCredName}")
        ${pkgs.curl}/bin/curl -fsS \
          -o "$CACHE_DIRECTORY/last-status" \
          -w 'my_ip=%{remote_ip} status=%{http_code}\n' \
          "https://manager.route64.org/api/$KEY/tunnelbroker/${cfg.tunnelId}/remote/$MY_IP" \
          || true
      '';
    };

    systemd.timers.route64-heartbeat = {
      description = "Route64 heartbeat (every 5 min)";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
        RandomizedDelaySec = "30s";
      };
    };

    # Friendly status command: `route64-status` shows the tunnel state.
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "route64-status" ''
        echo "== tunnel interface =="
        ${pkgs.iproute2}/bin/ip -6 addr show dev route64-ipv6 2>/dev/null \
          || { echo "route64-ipv6 not up"; exit 1; }
        echo
        echo "== default route =="
        ${pkgs.iproute2}/bin/ip -6 route show default
        echo
        echo "== heartbeat =="
        ${pkgs.systemd}/bin/systemctl --no-pager status route64-heartbeat.timer route64-heartbeat.service || true
        echo
        echo "== reachability (v6 DNS, v6 IP echo) =="
        ${pkgs.curl}/bin/curl -fsS --max-time 5 https://api64.ipify.org && echo
        ${pkgs.iputils}/bin/ping -6 -c 2 -W 3 ${cfg.serverIPv6} 2>&1 | tail -4 || true
      '')
    ];
  };
}
