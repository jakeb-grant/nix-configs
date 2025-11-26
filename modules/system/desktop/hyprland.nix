{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (config.desktop-environment.enable && config.desktop-environment.de == "hyprland") {
    # Hyprland Wayland Compositor
    programs.hyprland.enable = true;

    # Display manager options for Hyprland:
    # Option 1: TTY login (lightweight, login then run 'Hyprland')
    # Option 2: GDM (GNOME Display Manager)
    # Option 3: SDDM (can work with Wayland session)

    # Using TTY login by default (most common for Hyprland)
    # To use: login at TTY and run 'Hyprland'
    # Uncomment one of the following if you prefer a display manager:
    # services.xserver.displayManager.gdm.enable = true;
    # services.displayManager.sddm.enable = true;

    # Note: User packages (terminal, launcher, etc.) are managed via home-manager
    # See modules/home/desktop/hyprland/default.nix

    # XDG portal for screen sharing, file picker, etc. (system-level requirement)
    xdg.portal = {
      enable = true;
      wlr.enable = lib.mkForce false; # Hyprland has its own portal
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
    };

    # Hyprland-specific environment variables
    environment.sessionVariables = {
      # Enable Wayland for Electron apps (VSCode, Discord, etc.)
      NIXOS_OZONE_WL = "1";
    };
  };
}
