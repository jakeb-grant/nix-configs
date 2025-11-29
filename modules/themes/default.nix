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

    isDark = lib.mkOption {
      type = lib.types.bool;
      description = "Whether this is a dark theme";
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
      themeName = lib.mkOption {
        type = lib.types.str;
        description = "Base GTK theme name to use";
        readOnly = true;
      };

      themePackage = lib.mkOption {
        type = lib.types.str;
        description = "Package name providing the GTK theme";
        readOnly = true;
      };

      iconThemeName = lib.mkOption {
        type = lib.types.str;
        description = "GTK icon theme name to use";
        readOnly = true;
      };

      iconThemePackage = lib.mkOption {
        type = lib.types.str;
        description = "Package name providing the icon theme";
        readOnly = true;
      };

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

    firefox = {
      userChrome = lib.mkOption {
        type = lib.types.str;
        description = "Firefox userChrome.css for UI theming";
        readOnly = true;
      };

      userContent = lib.mkOption {
        type = lib.types.str;
        description = "Firefox userContent.css for web content theming";
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
