{pkgs, ...}:
pkgs.resholve.mkDerivation rec {
  pname = "podcast-cli-app.sh";
  version = "0.1.0";

  src = ./src;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/man/man1
    ${pkgs.pandoc}/bin/pandoc -s -t man ./podcast_downloader.md -o $out/share/man/man1/podcast_downloader.1

    find ./bin -type f -exec install -vDm 755 {} $out/{} \;
    chmod +x $out/bin/*
  '';

  solutions = {
    default = {
      scripts = ["bin/podcast-cli-app.sh"];
      interpreter = "${pkgs.bash}/bin/bash";
      inputs = with pkgs; [
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

  # meta = with pkgs.lib; {
  #   homepage = "https://github.com/aelsabbahy/goss/blob/v${version}/extras/dgoss/README.md";
  #   description = "Convenience wrapper around goss that aims to bring the simplicity of goss to docker containers";
  #   license = licenses.asl20;
  #   platforms = platforms.linux;
  #   maintainers = with maintainers; [hyzual];
  # };
}
