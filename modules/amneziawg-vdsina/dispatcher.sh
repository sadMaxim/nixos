#!/bin/sh
# /etc/NetworkManager/dispatcher.d/awg-vdsina
#
# NM ships a `wireguard` connection type that uses the stock `wireguard.ko`
# module. That module doesn't understand AmneziaWG's obfuscation params
# (Jc/Jmin/Jmax/S1/S2/H1-H4) and so the handshake will fail against our
# v3.0 server.
#
# Workaround: when NM brings the `awg-vdsina` interface up, it creates a
# plain wireguard.ko interface. We immediately delete it and bring up the
# real amneziawg.ko interface with the same name via awg-quick. NM is happy
# because the interface name and IP plan match.
#
# When NM brings the interface down, we tear down the AWG interface first.
#
# Installed automatically by the NixOS module; do not edit by hand — edit
# ../../../amneziawg-vdsina/dispatcher.sh in the nixos repo instead.
set -eu

CONF=/etc/amneziawg/awg-vdsina.conf
IFACE=awg-vdsina

if [ "$IFACE" != "${1:-}" ]; then
  exit 0
fi

case "${2:-}" in
  up|connectivity-change)
    # NM just created a plain wireguard.ko interface. Swap it for AWG.
    ip link delete "$IFACE" 2>/dev/null || true
    awg-quick up "$CONF"
    ;;
  down|pre-down)
    awg-quick down "$CONF" 2>/dev/null || true
    ;;
esac