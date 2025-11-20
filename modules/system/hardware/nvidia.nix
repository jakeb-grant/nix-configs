{ config, pkgs, ... }:

{
  # Enable NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Use the proprietary NVIDIA driver
    # Set to true for open-source kernel module (beta, for RTX 16xx and newer)
    open = false;

    # Enable the NVIDIA settings menu
    nvidiaSettings = true;

    # Use the latest production driver package
    # For specific versions: config.boot.kernelPackages.nvidiaPackages.legacy_470
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is required for Wayland compositors (Hyprland, Sway, etc.)
    modesetting.enable = true;

    # Power management (improves stability and reduces power consumption)
    powerManagement.enable = true;
    # Fine-grained power management (turn off GPU when not in use)
    # Experimental, may cause sleep/suspend issues
    powerManagement.finegrained = false;
  };

  # Hardware acceleration (OpenGL, Vulkan)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit applications (games, Wine, Steam)

    extraPackages = with pkgs; [
      nvidia-vaapi-driver  # VA-API support for NVIDIA
      vaapiVdpau           # VDPAU backend for VA-API
      libvdpau-va-gl       # VDPAU driver with VA-GL backend
    ];
  };

  # Environment variables for Wayland/Hyprland compatibility
  environment.sessionVariables = {
    # NVIDIA-specific Wayland environment variables
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # Wayland cursor fix for NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1";

    # Enable NVIDIA GPU for Electron apps (VSCode, Discord, etc.)
    NIXOS_OZONE_WL = "1";
  };

  # Kernel parameters for NVIDIA
  boot.kernelParams = [
    # Enable DRM kernel mode setting
    "nvidia-drm.modeset=1"
    # Preserve video memory after suspend (helps with suspend/resume)
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];
}
