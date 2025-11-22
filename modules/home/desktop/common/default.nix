{ config, pkgs, lib, osConfig, ... }:

{
  # Common desktop application configurations
  # Shared across all desktop environments

  # GUI applications (require desktop environment)
  home.packages = with pkgs; [
    # Web browser
    firefox
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [ "svelte" "nix" "nvim-nightfox" "material-icon-theme" ];
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
      lsp = {
        nix = {
          binary = {
            path_lookup = true;
          };
        };
      };
    };
  };

  # Firefox configuration
  home.sessionVariables = lib.mkIf
    (lib.elem (osConfig.desktop-environment.de or "none") ["plasma" "hyprland"]) {
    # Enable Wayland for Firefox (only for Wayland-capable DEs)
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Future: Add shared GUI application configs here
  # For example:
  # programs.vscode = { ... };
  # programs.firefox = { ... };
}
