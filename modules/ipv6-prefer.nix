# Prefer IPv6 over IPv4 for outbound connections made through getaddrinfo
# (curl, wget, Node's dns.lookup, etc.).
#
# Why: when a destination advertises both A and AAAA records, RFC 6724
# destination-address selection decides which address the caller tries first.
# Rule 5 (matching outgoing interface) can flip the default ordering toward
# IPv4 when the IPv4 source rides a "closer" path than the IPv6 one — which
# is what was sending the agent's HTTPS calls over an IPv4 egress that
# OpenAI/Cloudflare was geo-blocking, while a parallel browser on the same
# host reached the same service over IPv6.
#
# Tightening the precedence values forces IPv6 ahead of IPv4-mapped IPv6
# regardless of interface match. NODE_OPTIONS pins Node's result ordering to
# `verbatim`, which delegates to gai.conf — Node ≤16 defaults to `ipv4first`
# and would otherwise bypass this change.
#
# This module deliberately contains no secrets. Verify with:
#   getent ahosts chatgpt.com                 # IPv6 first
#   node -e 'require("https").get("https://chatgpt.com",
#             r => console.log(r.socket.remoteAddress))'  # contains ':'
{ config, lib, pkgs, ... }:

{
  environment.etc."gai.conf".text = ''
    # Override RFC 6724 defaults so getaddrinfo returns IPv6 first.
    # Higher precedence value wins.
    precedence ::1/128        50
    precedence ::/0           40
    precedence ::ffff:0:0/96  10
  '';

  environment.sessionVariables = {
    # Pin DNS result order across Node versions.
    # Node ≤16 defaults to ipv4first; ≥17 to verbatim.
    NODE_OPTIONS = "--dns-result-order=verbatim";
  };
}