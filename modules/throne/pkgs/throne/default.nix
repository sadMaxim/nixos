{
  lib,
  stdenv,
  fetchurl,
  binutils,
  zstd,
  makeWrapper,
  wrapGAppsHook3,
  autoPatchelfHook,
  xkeyboardconfig,
  fontconfig,
  freetype,
  glib,
  gtk3,
  libglvnd,
  libxcb,
  libxkbcommon,
  wayland,
  krb5,
  xcbutilcursor,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  qt6,
}:

# Throne (formerly nekoray) is a Qt-based GUI proxy client. Upstream
# publishes Linux builds as a Debian package containing its own copy of
# Qt6 and the Throne binary + ThroneCore (setuid wrapper for TUN mode).
# We extract the .deb and symlink the binary into $out/bin, then wrap
# it so its bundled Qt libs are picked up via LD_LIBRARY_PATH.
#
# Latest release is fetched from GitHub; SHA256 is pinned to the
# upstream tarball hash for reproducibility.
#
# Reference: https://github.com/throneproj/Throne
stdenv.mkDerivation {
  pname = "throne";
  version = "1.2.4";

  src = fetchurl {
    url = "https://github.com/throneproj/Throne/releases/download/1.2.4/Throne-1.2.4-debian-amd64.deb";
    sha256 = "e79840cf59cb9506261190769595776c31b7798093e5f5b2ca9d1dd17be910e0";
  };

  nativeBuildInputs = [
    binutils     # for `ar` (deb extraction)
    zstd         # data.tar.zst
    makeWrapper
    wrapGAppsHook3
    autoPatchelfHook
  ];

  # Throne ships its own bundled Qt6 in usr/lib/, so autoPatchelfHook
  # should mostly no-op — but Qt dlopens a handful of xcb helpers,
  # krb5, and Wayland shell plugins at runtime. Provide them here so
  # autoPatchelf can resolve the .so's AND so the wrapper's
  # LD_LIBRARY_PATH points at the real paths at runtime.
  buildInputs = [
    xkeyboardconfig
    fontconfig
    freetype
    glib
    gtk3
    libglvnd
    libxcb
    libxkbcommon
    wayland
    # Qt6 dlopens these via plugins/xcb / QtNetwork:
    krb5                     # libgssapi_krb5.so.2
    xcbutilcursor            # libxcb-cursor.so.0
    xcbutilimage             # libxcb-image.so.0
    xcbutilkeysyms           # libxcb-keysyms.so.1
    xcbutilrenderutil        # libxcb-render-util.so.0
    xcbutilwm                # libxcb-icccm.so.4
    # Throne's bundled Wayland shell integration plugin links against
    # libQt6WlShellIntegration.so.6 from the system Qt6 module. Provide
    # it here so autoPatchelf can resolve it; dontWrapQtApps below
    # prevents wrapQtAppsHook from injecting system-Qt6 paths into
    # our wrapper (which would shadow the bundled Qt6 in opt/Throne).
    qt6.qtwayland
  ];

  # Throne ships its OWN bundled Qt6 inside the .deb — we don't want
  # Nix's wrapQtAppsHook to inject system-Qt6 paths and shadow it.
  # Tell Nix we handle Qt wrapping manually (via wrapProgram + the
  # bundled usr/lib LD_LIBRARY_PATH entry in installPhase).
  dontWrapQtApps = true;

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack

    # .deb is an `ar` archive containing data.tar.zst
    ar x "$src"
    tar --use-compress-program=unzstd -xf data.tar.zst

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # The .deb installs everything under /opt/Throne/ — copy the whole
    # tree so the bundled Qt libs, plugins, icons, and binary stay
    # together (Throne looks for its sibling usr/lib and usr/plugins
    # relative to its argv[0]).
    mkdir -p "$out/opt"
    cp -r opt/Throne "$out/opt/Throne"

    # Symlink the main binary to /bin so `throne` is on $PATH.
    mkdir -p "$out/bin"
    ln -s "$out/opt/Throne/Throne" "$out/bin/throne"

    # Wrap so GTK/Qt picks up system theme/icons AND so the dlopen'd
    # xcb/krb5/wayland libs above are on LD_LIBRARY_PATH at runtime.
    # wrapGAppsHook3 sets up the GIO modules; we add the missing Qt
    # deps and the bundled usr/lib path (so the bundled Qt wins for
    # libs that ship with the .deb).
    wrapProgram "$out/bin/throne" \
      --prefix LD_LIBRARY_PATH : "$out/opt/Throne/usr/lib" \
      --prefix QT_PLUGIN_PATH : "$out/opt/Throne/usr/plugins" \
      --prefix QT_QPA_PLATFORM_PLUGIN_PATH : "$out/opt/Throne/usr/plugins/platforms" \
      --prefix XDG_DATA_DIRS : "$out/share" \
      --suffix PATH : "$out/opt/Throne"

    runHook postInstall
  '';

  # autoPatchelfHook walks $out/bin and patches every ELF. Our bin
  # entry is a symlink to $out/opt/Throne/Throne — autoPatchelf
  # dereferences symlinks, so the actual binary gets patched. No
  # extra config needed here.
  autoPatchelf = true;

  meta = with lib; {
    description = "Throne — Qt-based GUI proxy client (formerly nekoray), backed by sing-box";
    longDescription = ''
      Throne is the maintained successor to nekoray. Imports VLESS,
      Shadowsocks, Trojan and similar links; ships an embedded sing-box
      core that supports XHTTP. Replaces the upstream-deprecated
      nekoray-bin in nixpkgs.
    '';
    homepage = "https://github.com/throneproj/Throne";
    license = licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = [ ];
  };
}
