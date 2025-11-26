{ pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager = {
    enable = true;
    # Ensure WiFi is enabled
    wifi.powersave = false; # Disable WiFi power saving (can cause disconnects)
  };

  # Alternative: WiFi via wpa_supplicant (conflicts with NetworkManager)
  # networking.wireless.enable = true;

  # Network proxy configuration
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Timezone and locale
  time.timeZone = "America/Denver"; # Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # User account is now configured via modules/system/user.nix
  # See host configuration files for main-user settings

  # Enable sudo
  security.sudo.wheelNeedsPassword = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    zip
  ];

  # Additional programs
  programs.nix-ld.enable = true; # Enable dynamic library resolution for LSPs and other tools
  # programs.mtr.enable = true;  # Network diagnostic tool
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Allow unfree packages system-wide
  nixpkgs.config.allowUnfree = true;

  # Remote access
  services.openssh.enable = true;

  # Firewall configuration
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;  # Disable firewall entirely

  # Auto upgrade
  system.autoUpgrade.enable = false; # Set to true for automatic updates

  # NixOS version
  system.stateVersion = "25.05"; # Don't change this after initial install
}
