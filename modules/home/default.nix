{ config, pkgs, lib, ... }:

{
  # Configure home-manager using main-user module
  home-manager.users.${config.main-user.userName} = { pkgs, osConfig, ... }: {
    imports = [
      ./programs/shell.nix
      ./programs/git.nix
    ] ++ lib.optionals (osConfig.desktop-environment.enable or false) [
      ./desktop/common
    ] ++ lib.optionals ((osConfig.desktop-environment.de or "none") == "plasma") [
      ./desktop/plasma
    ] ++ lib.optionals ((osConfig.desktop-environment.de or "none") == "hyprland") [
      ./desktop/hyprland
    ];

    # Home Manager version
    home.stateVersion = "25.05";

    # User packages (CLI tools only, GUI apps in desktop/common)
    home.packages = with pkgs; [
      # Terminal utilities
      ripgrep
      fd
      bat
      eza
      fzf
      tmux

      # Terminal-based development tools
      neovim

      # System monitoring
      btop
    ];

    # Session variables
    home.sessionVariables = {
      EDITOR = "vim";
    } // lib.optionalAttrs
      (lib.elem (osConfig.desktop-environment.de or "none") ["plasma" "hyprland"]) {
      # Enable Wayland for Firefox (only for Wayland-capable DEs)
      MOZ_ENABLE_WAYLAND = "1";
    };

    # Note: Unfree packages are allowed system-wide in modules/system/core.nix
  };
}
