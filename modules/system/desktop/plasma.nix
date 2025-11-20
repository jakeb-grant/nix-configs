{ config, pkgs, ... }:

{
  # KDE Plasma 6 Desktop Environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Note: Plasma packages are managed via home-manager
  # See modules/home/desktop/plasma/default.nix
  # Plasma 6 includes all essential apps (Dolphin, Konsole, Spectacle, etc.)
}
