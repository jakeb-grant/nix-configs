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
    extensions = [ "catppuccin-blur" "svelte" ];
    userSettings = {
      base_keymap = "VSCode"
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
