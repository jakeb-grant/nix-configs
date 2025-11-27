{
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  # Import theme from system config
  theme = osConfig.theme.colors;
  themeOpacity = osConfig.theme.opacity;
in
{
  # Common desktop application configurations
  # Shared across all desktop environments

  # GUI applications (require desktop environment)
  home.packages = with pkgs; [
    firefox # Web browser
    nil # Nix language server for Zed to use
    nixd # Nix language server for Zed to use
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [
      "svelte"
      "nix"
      "nvim-nightfox"
      "material-icon-theme"
    ];
    userSettings = {
      base_keymap = "VSCode";
      buffer_font_family = "JetBrainsMono Nerd Font";
      ui_font_family = "JetBrainsMono Nerd Font Propo";
      terminal = {
        font_family = "JetBrainsMono Nerd Font Mono";
      };
      theme = {
        mode = "system";
        dark = osConfig.theme.zed.theme;
        light = osConfig.theme.zed.theme;
      };
      # Theme overrides from centralized theme system
      theme_overrides = {
        "${osConfig.theme.zed.theme}" = osConfig.theme.zed.overrides;
      };
      icon_theme = {
        mode = "system";
        light = "Material Icon Theme";
        dark = "Material Icon Theme";
      };
      edit_predictions = {
        mode = "subtle";
      };
      features = {
        edit_prediction_provider = "zed";
      };
      # Tell Zed to use direnv and direnv can use a flake.nix environment
      load_direnv = "shell_hook";
      lsp = {
        nix = {
          binary = {
            path_lookup = true;
          };
        };
      };
    };
  };

  # Ghostty terminal emulator
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;

    settings = {
      # Font configuration (matching your Zed setup)
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;

      # Theme colors (using theme system instead of built-in theme)
      background = "${theme.bg}";
      foreground = "${theme.fg}";
      background-opacity = themeOpacity; # Uses theme system opacity value
      background-blur = true;

      # Window appearance
      window-padding-x = 10;
      window-padding-y = 10;

      # Performance
      shell-integration = "bash";
    };
  };

  # Firefox configuration
  home.sessionVariables =
    lib.mkIf
      (lib.elem (osConfig.desktop-environment.de or "none") [
        "plasma"
        "hyprland"
      ])
      {
        # Enable Wayland for Firefox (only for Wayland-capable DEs)
        MOZ_ENABLE_WAYLAND = "1";
      };
}
