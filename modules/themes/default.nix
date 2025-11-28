{ lib, config, ... }:

{
  options.theme = {
    enable = lib.mkEnableOption "theme system";

    selected = lib.mkOption {
      type = lib.types.enum [ "carbonfox" ];
      default = "carbonfox";
      description = ''
        Selected theme for the desktop environment.
        Currently available themes:
        - carbonfox: Dark theme with carbon black background and cyan accents
      '';
    };

    colors = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = "Theme color definitions";
      readOnly = true;
    };

    opacity = lib.mkOption {
      type = lib.types.float;
      description = "Global opacity value for transparent elements";
      readOnly = true;
    };

    zed = {
      theme = lib.mkOption {
        type = lib.types.str;
        description = "Zed editor theme name to use";
        readOnly = true;
      };

      overrides = lib.mkOption {
        type = lib.types.attrs;
        description = "Zed editor theme overrides";
        readOnly = true;
      };
    };

    gtk = {
      gtk3Css = lib.mkOption {
        type = lib.types.str;
        description = "GTK3 CSS theme overrides";
        readOnly = true;
      };

      gtk4Css = lib.mkOption {
        type = lib.types.str;
        description = "GTK4 CSS theme overrides";
        readOnly = true;
      };
    };

    waybar = {
      css = lib.mkOption {
        type = lib.types.str;
        description = "Waybar CSS styling";
        readOnly = true;
      };
    };

    rofi = {
      rasi = lib.mkOption {
        type = lib.types.str;
        description = "Rofi theme configuration (RASI format)";
        readOnly = true;
      };
    };
  };

  config = lib.mkIf config.theme.enable {
    # Import the selected theme
    theme = lib.mkMerge [
      (lib.mkIf (config.theme.selected == "carbonfox") (import ./carbonfox.nix))
    ];
  };
}
