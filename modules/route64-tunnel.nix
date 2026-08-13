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

    parentDevice = mkOption {
      type = types.str;
      default = "wlp58s0";
      description = ''
        Physical interface the SIT tunnel attaches to (e.g. your Wi-Fi
        NIC). NM requires an explicit parent for `ip-tunnel` profiles
        because it can't auto-pick one — without this, activation fails
        with "Failed to find a compatible device for this connection".
      '';
      example = "wlp58s0";
    };

    apiKeyFile = mkOption {
      # String, not path: flake eval is pure and won't accept absolute
      # paths like /home/maxim/...; storing as a string keeps the value
      # inert until activation, where systemd LoadCredential reads the
      # actual file by path.
      type = types.str;
      description = ''
        Path to a file containing the Route64 API key (single line, no
        trailing newline required). Read at runtime via systemd
        LoadCredential — the key never enters any committed nix file.
        Required when enable = true.
      '';
      example = "/home/maxim/secrets/ROUTE64";
    };
  };

  config = mkIf cfg.enable {
    # SIT (6in4) tunnel via NetworkManager's ip-tunnel connection type.
    # In nixpkgs ≥24.11 this moved from `connectionFiles.<name>.contents`
    # (a raw string) to `ensureProfiles.profiles.<name>`, a typed attrset
    # with freeform INI under the hood. The only mandatory declared keys
    # are `connection.id` and `connection.type`; everything else is
    # passed through to the NM keyfile verbatim.
    networking.networkmanager.ensureProfiles.profiles."route64-ipv6" = {
      connection = {
        id = "route64-ipv6";
        uuid = "c1b7f0c4-1f7e-4b3e-9a4f-2e6d8a4f7c2a";
        type = "ip-tunnel";
        interface-name = "route64-ipv6";
        autoconnect = "true";
        autoconnect-priority = "10";
      };
      ip-tunnel = {
        # NM keyfile expects an integer mode (see NMKeyfileReadTunnelMode):
        #   0 = ipip, 1 = gre, 2 = sit, 3 = isatap, 4 = vti, 5 = vti6.
        # For IPv6-in-IPv4 SIT (the Route64 protocol) we need mode=2.
        # Earlier "4" was parsed as int 4 = isatap, "sit" was rejected
        # as not-an-integer.
        mode = 2;
        local = cfg.clientIPv4;
        remote = cfg.serverIPv4;
        ttl = 255;
        # Parent device: NM needs an explicit binding for ip-tunnel
        # profiles because it can't infer one. Default = wlp58s0
        # (override via networking.route64-tunnel.parentDevice). This
        # key lives in the [ip-tunnel] section, not [connection] —
        # see https://networkmanager.dev/docs/api/1.52.0/settings-ip-tunnel.html
        parent = cfg.parentDevice;
      };
      ipv6 = {
        method = "manual";
        addresses = "${cfg.clientIPv6}/64";
        gateway = cfg.serverIPv6;
      };
      ipv4 = {
        method = "disabled";
      };
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
