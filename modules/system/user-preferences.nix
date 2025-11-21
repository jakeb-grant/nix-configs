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
      default = "jacob grant";
      description = "Full name/description for the user account";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      default = "America/Denver";
      description = "System timezone";
      example = "America/New_York";
    };

    desktopEnvironment = lib.mkOption {
      type = lib.types.enum [ "plasma" "hyprland" ];
      default = "plasma";
      description = ''
        Desktop environment choice:
        - plasma: KDE Plasma 6 with SDDM
        - hyprland: Hyprland Wayland compositor
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Apply system timezone
    time.timeZone = cfg.timezone;

    # Forward preferences to main-user module
    # Note: email and gitName are still configured separately (from secrets for now)
    main-user = {
      enable = true;
      userName = cfg.userName;
      description = cfg.fullName;
    };

    # Forward desktop environment preference
    desktop-environment = {
      enable = true;
      de = cfg.desktopEnvironment;
    };
  };
}
