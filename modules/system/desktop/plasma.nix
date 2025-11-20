{ config, pkgs, ... }:

{
  # KDE Plasma 6 Desktop Environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Plasma-specific packages (optional, Plasma 6 includes most essentials)
  environment.systemPackages = with pkgs; [
    # Add any extra Plasma apps you want here
    # kdePackages.kate
    # kdePackages.konsole
    # kdePackages.dolphin (already included with Plasma 6)
  ];
}
