{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  scriptName = "cuttlefi.sh";
  cfg = config.services.${scriptName};
in {
  options.services.${scriptName} = {
    enable = mkEnableOption "podcast downloader script";

    syncInterval = mkOption {
      type = types.str;
      default = "30m";
      description = "How often to run sync";
    };

    configPath = mkOption {
      type = types.str;
      # default = "/etc/${scriptName}/config.yaml";
      description = "Path to the YAML configuration file containing podcast subscriptions.";
    };

    saveDir = mkOption {
      type = types.str;
      # default = "/var/lib/${scriptName}/episodes";
      description = "Directory to save the podcast episodes.";
    };

    logsDir = mkOption {
      type = types.str;
      # default = "/var/log/${scriptName}";
      description = "Directory to save download logs.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xmlstarlet
      yq
      wget
      coreutils # for md5sum and other basic tools
    ];

    systemd.services.${scriptName} = {
      description = "Podcast Downloader Service";
      wantedBy = ["multi-user.target"];
      path = with pkgs; [xmlstarlet yq wget coreutils];
      serviceConfig = {
        ExecStart = pkgs."cuttlefi.sh";
        User = "nobody";
        Group = "nogroup";
      };
      unitConfig.Documentation = "man:podcast-downloader(8)";
      startInterval = cfg.${scriptName}.syncInterval;
    };

    # Ensure the directories exist and set the appropriate permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.saveDir} 0755 nobody nogroup - -"
      "d ${cfg.logsDir} 0755 nobody nogroup - -"
    ];
  };
}
