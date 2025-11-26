{ config, pkgs, ... }:

{
  # Enable X11 windowing system
  # Note: Even Wayland compositors often need this for X11 app compatibility
  services.xserver.enable = true;

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with PipeWire
  services.pulseaudio.enable = false;
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

  # Polkit for privilege escalation (required for NetworkManager, etc.)
  security.polkit.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];
}
