{ config, pkgs, lib, ... }:

{
  # Enable Intel and NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Use the proprietary NVIDIA driver
    # Set to true for open-source kernel module (beta, for RTX 16xx and newer)
    open = false;

    # Enable the NVIDIA settings menu
    nvidiaSettings = true;

    # Use the latest production driver package
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is required for Wayland compositors (Hyprland, Sway, etc.)
    modesetting.enable = true;

    # Power management (important for laptops)
    powerManagement.enable = true;
    # Fine-grained power management (turns off NVIDIA GPU when not in use)
    # This saves battery but may cause issues with some applications
    powerManagement.finegrained = true;

    # NVIDIA Prime configuration for hybrid graphics
    prime = {
      # Offload mode: Intel by default, NVIDIA on-demand
      # Use 'nvidia-offload <command>' to run apps on NVIDIA
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Provides 'nvidia-offload' command
      };

      # Alternative: Sync mode (always use NVIDIA, display through Intel)
      # Better performance but worse battery life
      # Uncomment to use sync mode instead:
      # sync.enable = true;

      # Bus IDs - CRITICAL: These must match your hardware
      # Find yours with: lspci | grep -E "VGA|3D"
      # Convert format: "00:02.0" -> "PCI:0:2:0"
      intelBusId = "PCI:0:2:0";    # Intel UHD Graphics 630
      nvidiaBusId = "PCI:1:0:0";   # NVIDIA GTX 1050 Ti Mobile

      # If you have issues, you may need to force Intel iGPU:
      # reverseSync.enable = true;
    };
  };

  # Hardware acceleration (OpenGL, Vulkan)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit applications (games, Wine, Steam)

    extraPackages = with pkgs; [
      # Intel drivers
      intel-media-driver    # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver   # LIBVA_DRIVER_NAME=i965 (older, but more compatible)
      libva-vdpau-driver
      libvdpau-va-gl

      # NVIDIA drivers
      nvidia-vaapi-driver
    ];
  };

  # Environment variables for hybrid graphics
  environment.sessionVariables = {
    # Use Intel for most things (better battery)
    # NVIDIA will be used when running 'nvidia-offload <command>'

    # Wayland cursor fix for NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1";

    # Enable GPU acceleration for Electron apps (VSCode, Discord, etc.)
    NIXOS_OZONE_WL = "1";
  };

  # Kernel parameters
  boot.kernelParams = [
    # Enable DRM kernel mode setting for NVIDIA
    "nvidia-drm.modeset=1"
    # Preserve video memory after suspend
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # Optional: Create aliases for running apps on NVIDIA
  # These will be available in your shell after rebuilding
  environment.shellAliases = {
    # Examples of using NVIDIA for specific applications
    # "nvidia-steam" = "nvidia-offload steam";
    # "nvidia-games" = "nvidia-offload";
  };
}
