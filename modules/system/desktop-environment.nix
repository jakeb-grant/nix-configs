{ lib, config, pkgs, ... }:

let
  cfg = config.desktop-environment;
in
{
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
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Always import base configuration
    imports = [
      ./desktop/base.nix
    ] ++ lib.optionals (cfg.de == "plasma") [
      ./desktop/plasma.nix
    ] ++ lib.optionals (cfg.de == "hyprland") [
      ./desktop/hyprland.nix
    ];
  };
}
