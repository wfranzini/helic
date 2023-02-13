self: { config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.helic;
in {
  options.services.helic = {
    enable = mkEnableOption "Clipboard Manager";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.helic;
      description = "The package to use for helic.";
    };
    name = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The instance name used for identifying cycles. Defaults to the host name.";
    };
    maxHistory = mkOption {
      type = types.nullOr types.ints.positive;
      default = 100;
      description = "The maximum number of yanks to store in memory.";
    };
    verbose = mkEnableOption "Increase the log level.";
    net = {
      port = mkOption {
        type = types.port;
        default = 9500;
        description = "The http server is used both for yanking and broadcast to other hosts.";
      };
      hosts = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "The network addresses of other helic instances that should be shared with.";
        example = literalExpression ["otherhost:9501"];
      };
      timeout = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Maximum time in milliseconds to wait for a connection to a remote host to be made.";
      };
    };
    tmux = {
      enable = mkEnableOption "Enable tmux integration";
      package = mkOption {
        type = types.package;
        default = pkgs.tmux;
        description = "The package to use for tmux. Defaults to `pkgs.tmux`.";
      };
    };
    x11 = {
      display = mkOption {
        type = types.str;
        default = ":0";
        description = "The X11 display to connect to if there is no active display in the environment.";
      };
    };
  };
  config = mkIf cfg.enable {
    home.packages = [cfg.package];
    home.file.".config/helic.yaml" = {
      onChange = "${pkgs.systemd}/bin/systemctl --user restart helic.service";
      text = ''
    ${if cfg.name == null then "" else "name: ${cfg.name}"}
    maxHistory: ${toString cfg.maxHistory}
    ${if cfg.verbose == null then "" else "verbose: ${if cfg.verbose then "true" else "false"}"}
    tmux:
      enable: ${if cfg.tmux.enable then "true" else "false"}
      ${if cfg.tmux.enable then "exe: ${cfg.tmux.package}/bin/tmux" else ""}
    net:
      port: ${toString cfg.net.port}
      hosts: [${concatMapStringsSep ", " (h: "'${h}'") cfg.net.hosts}]
      ${if cfg.net.timeout == null then "" else "timeout: ${toString cfg.net.timeout}"}
    x11:
      display: ${cfg.x11.display}
    '';
    };

    systemd.user.services.helic = {
      Unit = {
        Description = "Clipboard Manager";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        Restart = "always";
        ExecStart = "${cfg.package}/bin/hel listen";
      };
    };
  };
}
