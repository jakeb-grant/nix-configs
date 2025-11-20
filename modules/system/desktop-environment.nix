{ lib, config, pkgs, ... }:

{
  # Desktop environment option module
  # This module only defines the option - actual imports happen in host configs

  options.desktop-environment = {
    enable = lib.mkEnableOption "enable desktop environment module";

    de = lib.mkOption {
      type = lib.types.enum [ "plasma" "hyprland" ];
      default = "plasma";
      description = ''
        Desktop environment to use:
        - plasma: KDE Plasma 6 with SDDM
        - hyprland: Hyprland Wayland compositor

        Note: This option is automatically set from secrets.nix in host configs.
        The desktop environment choice in secrets.nix controls both:
        1. Which desktop modules are imported (via lib.optionals in host config)
        2. The value of this option (single source of truth)

        To change desktop environment, edit secrets.nix in your host directory
        or re-run setup.sh.
      '';
    };
  };

  # No config block - just the options
  # Hosts import the desktop modules directly
}
