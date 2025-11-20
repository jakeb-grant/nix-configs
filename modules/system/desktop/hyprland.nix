{ config, pkgs, ... }:

{
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

  # Essential Wayland/Hyprland packages
  environment.systemPackages = with pkgs; [
    # Terminal emulator (choose one or multiple)
    kitty
    # alacritty
    # foot

    # Application launcher
    rofi-wayland
    # wofi

    # Status bar
    waybar

    # Notification daemon
    mako
    libnotify

    # Screenshot utilities
    grim
    slurp

    # Clipboard manager
    wl-clipboard

    # Wallpaper daemon
    hyprpaper
    # swaybg

    # Screen locker
    swaylock

    # File manager
    xfce.thunar

    # Network management
    networkmanagerapplet
  ];

  # XDG portal for screen sharing, file picker, etc.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Hyprland-specific environment variables
  environment.sessionVariables = {
    # Enable Wayland for Electron apps (VSCode, Discord, etc.)
    NIXOS_OZONE_WL = "1";

    # NVIDIA-specific (uncomment if using NVIDIA)
    # WLR_NO_HARDWARE_CURSORS = "1";
  };
}
