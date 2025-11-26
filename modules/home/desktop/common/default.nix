{
  pkgs,
  lib,
  osConfig,
  ...
}:

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
        dark = "Carbonfox - blurred";
        light = "Carbonfox - blurred";
      };
      # Override background opacity to match Ghostty (0.95 = 0xF2 in hex)
      theme_overrides = {
        "Carbonfox - blurred" = {
          background = "#161616F2";
        };
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

      # Theme
      theme = "Carbonfox";
      background-opacity = 0.95; # 0.0 (transparent) to 1.0 (opaque)
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
