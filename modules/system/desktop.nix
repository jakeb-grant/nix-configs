{ config, pkgs, ... }:

{
  # Enable X11 windowing system
  services.xserver.enable = true;

  # Enable KDE Plasma Desktop Environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Alternative: Hyprland (uncomment to use instead of KDE)
  # programs.hyprland.enable = true;
  # services.xserver.displayManager.gdm.enable = true;

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with PipeWire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;  # Uncomment for JACK applications
  };

  # Enable touchpad support (laptop)
  services.libinput.enable = true;

  # Printing support
  services.printing.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    jetbrains-mono
  ];
}
