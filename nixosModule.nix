{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.cuttlefish;
in {
  options.services.cuttlefish = {
    enable = lib.mkEnableOption "Cuttlefish service";

    package = lib.mkOption {
      type = lib.types.str;
      description = "Cuttlefi.sh package";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Cuttlefish configuration settings.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "Interval for the Cuttlefish service to run.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.cuttlefish];

    systemd.services.cuttlefish = {
      description = "Cuttlefish Podcast Downloader";
      wantedBy = ["multi-user.target"];
      path = [pkgs.cuttlefish];

      serviceConfig = {
        ExecStart = let
          jsonConfig = builtins.toJSON cfg.settings;
          jsonConfigFile = pkgs.writeText "config.yml" jsonConfig;
        in "${pkgs.cuttlefish}/bin/cuttlefish --config <(${pkgs.yq}/bin/yq eval -P '${jsonConfigFile}/config.yml') sync";
        Restart = "on-failure";
      };

      script = let
        configFile = pkgs.writeText "cuttlefish-config.yml" yamlConfig;
      in ''
      '';

      timers.cuttlefish = {
        description = "Cuttlefish Sync Timer";
        partOf = ["cuttlefish.service"];
        wantedBy = ["timers.target"];
        timerConfig.OnCalendar = cfg.interval;
      };
    };
  };
}
