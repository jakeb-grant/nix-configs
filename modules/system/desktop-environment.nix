{ lib, config, pkgs, ... }:

{
  # Desktop environment option module
  # This module only defines the option - actual imports happen in host configs

  options.desktop-environment = {
    enable = lib.mkEnableOption "enable desktop environment module";

    de = lib.mkOption {
      type = lib.types.enum [ "plasma" "hyprland" "none" ];
      default = "plasma";
      description = ''
        Desktop environment to use:
        - plasma: KDE Plasma 6 with SDDM
        - hyprland: Hyprland Wayland compositor
        - none: No desktop environment (server/minimal)

        Note: Set this option in your host config, then import the
        corresponding desktop modules:
        - modules/system/desktop/base.nix (always)
        - modules/system/desktop/plasma.nix (for Plasma)
        - modules/system/desktop/hyprland.nix (for Hyprland)
      '';
    };
  };

  # No config block - just the options
  # Hosts import the desktop modules directly
}
