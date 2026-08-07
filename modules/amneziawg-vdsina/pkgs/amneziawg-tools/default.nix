{
  lib,
  stdenv,
  fetchFromGitHub,
  bash,
  pkg-config,
  makeWrapper,
  iproute2,
  iptables,
  procps,
}:
stdenv.mkDerivation {
  pname = "amneziawg-tools";
  version = "3.0.20260805";

  src = fetchFromGitHub {
    owner = "amnezia-vpn";
    repo = "amneziawg-tools";
    rev = "9f70177d204d5be66c5b043518a57b7d62b3f9d1";
    hash = "sha256-eVi+pYUv0EgCEpIGcR5ISl3NI/VOgR2m9FPRYDIKw2o=";
  };

  sourceRoot = "source/src";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bash ];

  makeFlags = [
    "DESTDIR=${placeholder "out"}"
    "PREFIX=/"
    "WITH_BASHCOMPLETION=yes"
    "WITH_SYSTEMDUNITS=yes"
    "WITH_WGQUICK=yes"
  ];

  postFixup = ''
    for f in $out/bin/*; do
      wrapProgram "$f" \
        --prefix PATH : ${lib.makeBinPath [ procps iproute2 iptables ]}
    done
  '';

  meta = {
    description = "AmneziaWG v3.0 userspace tools (awg, awg-quick)";
    license = lib.licenses.gpl2;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}