{ pkgs, ... }:
{
  programs.bash.initExtra = ''
    export LD_LIBRARY_PATH="${pkgs.zlib}/lib:$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"
  '';

  home.file.".npmrc".text = ''
    ignore-scripts=true
    fund=false
    audit=false
    package-lock-only=true
  '';


  home.packages = [
     pkgs.python313
     pkgs.nodejs

    # (pkgs.python313.withPackages (ps: [
    #   ps.pip
    #   ps.torch
    #   ps.transformers
    #   ps.numpy
    #   ps.sqlitedict
    #   ps.pytz
    #   ps.py-cpuinfo
    #   ps.hjson
    #   ps.zstandard
    #   ps.xxhash
    #   ps.wcwidth
    #   ps.ujson
    #   ps.tzdata
    #   ps.typing-inspection
    #   ps.threadpoolctl
    #   ps.tcolorpy
    #   ps.tabulate
    #   ps.sentencepiece
    #   ps.scipy
    #   ps.python-dateutil
    # ]))
  ];
  
}
