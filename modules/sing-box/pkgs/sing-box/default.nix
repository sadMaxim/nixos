{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  steam-run,
}:
# sing-box — universal proxy platform (the same core Throne uses).
# Pinned to upstream's latest glibc-linked Linux amd64 build. Bump
# `version` + `sha256` together when updating.
#
# Reference: https://github.com/SagerNet/sing-box
stdenv.mkDerivation {
  pname = "sing-box";
  version = "1.13.18";

  src = fetchurl {
    url = "https://github.com/SagerNet/sing-box/releases/download/v1.13.18/sing-box-1.13.18-linux-amd64-glibc.tar.gz";
    sha256 = "b5c973890cf171a42512baaec6f21939f1b75b87551f335344986fd6041916d9";
  };

  dontConfigure = true;
  dontBuild = true;
  dontStrip = false;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec" "$out/share/doc/sing-box"
    # The archive unpacks to a single directory named after the tarball.
    install -m755 sing-box-*/sing-box "$out/libexec/sing-box.bin"
    install -m644 sing-box-*/LICENSE "$out/share/doc/sing-box/LICENSE"

    # Wrap with steam-run: NixOS can't load generic-linux ELF directly,
    # so we hand the binary to steam-run, which supplies a glibc ld.so
    # and the standard library paths the upstream build links against.
    # Putting the wrapper script in $out/bin/sing-box keeps the
    # `sing-box run -c ...` UX unchanged. Note: heredoc is unquoted
    # so Nix interpolates ${stdenv.shell}, ${steam-run}/..., and $out
    # into the wrapper at build time.
    cat > "$out/bin/sing-box" <<EOF
    #!${stdenv.shell}
    exec ${steam-run}/bin/steam-run $out/libexec/sing-box.bin "\$@"
    EOF
    chmod +x "$out/bin/sing-box"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Universal proxy platform — same core that powers Throne";
    longDescription = ''
      sing-box is a universal proxy platform supporting VLESS, VMess,
      Shadowsocks, Trojan, Hysteria, NaïveProxy, WireGuard and many
      other protocols. The same engine used by Throne (formerly
      nekoray). Pinned to v1.13.18 (latest release 2026-08-09).
    '';
    homepage = "https://sing-box.sagernet.org";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = [ ];
    mainProgram = "sing-box";
  };
}
