{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
}:
stdenv.mkDerivation {
  pname = "amneziawg-kmod";
  version = "3.0.20260805";

  src = fetchFromGitHub {
    owner = "amnezia-vpn";
    repo = "amneziawg-linux-kernel-module";
    rev = "ce163101dbcddfb64631f5fea52252ea836372b5";
    hash = "sha256-KHSnfeEVOVrvdPlgUtH1H2g9huu73UPjt6gHAcHMDBM=";
  };

  sourceRoot = "source/src";
  hardeningDisable = [ "pic" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildFlags = [
    "apply-patches"
    "module"
  ];

  makeFlags = [
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ] ++ lib.optional (lib.versionAtLeast kernel.version "5.6") "KERNEL_SOURCE_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/source";

  enableParallelBuilding = true;

  installFlags = [
    "DEPMOD=true"
    "INSTALL_MOD_PATH=${placeholder "out"}"
  ];

  meta = {
    description = "AmneziaWG v3.0 kernel module (built against current NixOS kernel)";
    longDescription = ''
      Out-of-tree build of amneziawg.ko from
      https://github.com/amnezia-vpn/amneziawg-linux-kernel-module.

      v3.0 is NOT wire-compatible with the v1.x/v2.x versions in nixpkgs'
      `linuxPackages.amneziawg`. Required to talk to the v3.0 server we
      run on vdsina (138.16.162.74:51821).
    '';
    license = lib.licenses.gpl2;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}