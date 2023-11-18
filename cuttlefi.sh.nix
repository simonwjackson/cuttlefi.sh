{pkgs, ...}:
pkgs.resholve.mkDerivation rec {
  pname = "cuttlefi.sh";
  version = "0.1.0";

  src = ./src;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/man/man1
    ${pkgs.pandoc}/bin/pandoc -s -t man ./cuttlefi.sh.1.md -o $out/share/man/man1/cuttlefish.1

    find ./bin -type f -exec install -vDm 755 {} $out/{} \;
    chmod +x $out/bin/**/*.sh
  '';

  solutions = {
    default = {
      scripts = [
        "bin/*.sh"
      ];
      interpreter = "${pkgs.bash}/bin/bash";
      inputs = with pkgs; [
        "${placeholder "out"}/bin"

        xmlstarlet
        yq
        wget
        coreutils-full
        gawk
        gnugrep
        docopts
        findutils
        gnused
      ];
      execer = [
        "cannot:${pkgs.yq}/bin/yq"
        "cannot:${pkgs.wget}/bin/wget"
        "cannot:${pkgs.docopts}/bin/docopts.sh"
        "cannot:${pkgs.docopts}/bin/docopts"
      ];
    };
  };
}
