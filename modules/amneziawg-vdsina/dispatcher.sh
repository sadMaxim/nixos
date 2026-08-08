#!/bin/sh
# /etc/NetworkManager/dispatcher.d/awg-vdsina
#
# NM ships a `wireguard` connection type that uses the stock `wireguard.ko`
# module. That module doesn't understand AmneziaWG's obfuscation params
# (Jc/Jmin/Jmax/S1/S2/H1-H4) and so the handshake will fail against our
# v3.0 server.
#
# Workaround: when NM brings the `awg-vdsina` interface up, it creates a
# plain wireguard.ko interface. We delete it and bring up the real
# amneziawg.ko interface with the same name via awg-quick. NM is happy
# because the interface name and IP plan match.
#
# Config lookup (must match the `vdsina` wrapper in modules/bin/):
#   1. $VDSINA_CONF
#   2. $XDG_CONFIG_HOME/vdsina/awg-vdsina.conf
#   3. /etc/amneziawg/awg-vdsina.conf
#
# Installed automatically by the NixOS module; do not edit by hand — edit
# ../../../amneziawg-vdsina/dispatcher.sh in the nixos repo instead.
set -eu

IFACE=awg-vdsina

if [ "$IFACE" != "${1:-}" ]; then
  exit 0
fi

# Pick the config (same precedence as the `vdsina` wrapper).
pick_conf() {
  if [ -n "${VDSINA_CONF:-}" ] && [ -f "$VDSINA_CONF" ]; then
    echo "$VDSINA_CONF"; return 0
  fi
  XDG="${XDG_CONFIG_HOME:-/root/.config}"
  if [ -f "$XDG/vdsina/awg-vdsina.conf" ]; then
    echo "$XDG/vdsina/awg-vdsina.conf"; return 0
  fi
  if [ -f "/etc/amneziawg/awg-vdsina.conf" ]; then
    echo "/etc/amneziawg/awg-vdsina.conf"; return 0
  fi
  return 1
}

case "${2:-}" in
  up|connectivity-change)
    # NM just created a plain wireguard.ko interface. Swap it for AWG.
    ip link delete "$IFACE" 2>/dev/null || true
    if CONF=$(pick_conf); then
      awg-quick up "$CONF"
    else
      echo "awg-vdsina dispatcher: no config found (set VDSINA_CONF or place config at ~/.config/vdsina/awg-vdsina.conf or /etc/amneziawg/awg-vdsina.conf)" >&2
      exit 1
    fi
    ;;
  down|pre-down)
    if CONF=$(pick_conf 2>/dev/null); then
      awg-quick down "$CONF" 2>/dev/null || true
    fi
    ;;
esac