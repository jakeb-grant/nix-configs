{ lib, config, ... }:

let
  cfg = config.user-preferences;
in
{
  options.user-preferences = {
    enable = lib.mkEnableOption "user preferences module";

    userName = lib.mkOption {
      type = lib.types.str;
      default = "jacob";
      description = "Primary username for the system";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "jacob";
      description = "Full name/description for the user account";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = "America/Denver";
      description = "System timezone";
      example = "America/New_York";
    };

    desktopEnvironment = lib.mkOption {
      type = lib.types.enum [
        "plasma"
        "hyprland"
      ];
      default = "hyprland";
      description = ''
        Desktop environment choice:
        - plasma: KDE Plasma 6 with SDDM
        - hyprland: Hyprland Wayland compositor
      '';
    };

    gitEmail = lib.mkOption {
      type = lib.types.str;
      default = "86214494+jakeb-grant@users.noreply.github.com";
      description = "Email address for git configuration";
    };

    gitName = lib.mkOption {
      type = lib.types.str;
      default = "jacob";
      description = "Name to use for git commits";
    };
  };

  config = lib.mkIf cfg.enable {
    # Apply system timezone
    time.timeZone = cfg.timezone;

    # Forward preferences to main-user module
    main-user = {
      enable = true;
      userName = cfg.userName;
      description = cfg.fullName;
      gitEmail = cfg.gitEmail;
      gitName = cfg.gitName;
    };

    # Forward desktop environment preference
    desktop-environment = {
      enable = true;
      de = cfg.desktopEnvironment;
    };
  };
}
