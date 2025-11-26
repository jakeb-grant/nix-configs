{ config, pkgs, ... }:

{
  # Enable Intel and NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Early KMS: Load modules in initramfs for early display initialization
  # IMPORTANT: i915 must load BEFORE nvidia modules on hybrid graphics
  # This prevents compositor restart issues and app stalling
  boot.initrd.kernelModules = [
    "i915"              # Intel iGPU - LOAD FIRST
    "nvidia"            # NVIDIA driver
    "nvidia_modeset"    # NVIDIA modesetting
    "nvidia_uvm"        # NVIDIA Unified Memory
    "nvidia_drm"        # NVIDIA DRM (Direct Rendering Manager)
  ];

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
    # DISABLED: Adds NVreg_PreserveVideoMemoryAllocations which causes compositor restart issues
    # Re-enable if you need suspend/resume to work and compositor restart works without it
    powerManagement.enable = false;
    # Fine-grained power management (turns off NVIDIA GPU when not in use)
    # This saves battery but may cause issues with some applications
    # DISABLED: Causes Hyprland to freeze on re-login after exit
    powerManagement.finegrained = false;

    # NVIDIA Prime configuration for hybrid graphics
    prime = {
      # Offload mode: Intel by default, NVIDIA on-demand
      # Use 'nvidia-offload <command>' to run apps on NVIDIA
      offload = {
        enable = true;
        enableOffloadCmd = true; # Provides 'nvidia-offload' command
      };

      # Alternative: Sync mode (always use NVIDIA, display through Intel)
      # Better performance but worse battery life
      # Uncomment to use sync mode instead:
      # sync.enable = true;

      # Bus IDs - CRITICAL: These must match your hardware
      # Find yours with: lspci | grep -E "VGA|3D"
      # Convert format: "00:02.0" -> "PCI:0:2:0"
      intelBusId = "PCI:0:2:0"; # Intel UHD Graphics 630
      nvidiaBusId = "PCI:1:0:0"; # NVIDIA GTX 1050 Ti Mobile

      # If you have issues, you may need to force Intel iGPU:
      # reverseSync.enable = true;
    };
  };

  # Hardware acceleration (OpenGL, Vulkan)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # For 32-bit applications (games, Wine, Steam)

    extraPackages = with pkgs; [
      # Intel drivers
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older, but more compatible)
      libva-vdpau-driver
      libvdpau-va-gl

      # NVIDIA drivers
      nvidia-vaapi-driver
    ];
  };

  # Environment variables for NVIDIA hybrid graphics
  environment.sessionVariables = {
    # Use Intel for VA-API by default (since we're in offload mode)
    # NVIDIA will be used via nvidia-offload command when needed
    LIBVA_DRIVER_NAME = "iHD"; # Intel iHD driver (newer)
    # Fallback: "i965" for older Intel GPUs

    # GLX vendor library for NVIDIA (doesn't interfere with Intel rendering)
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # Wayland cursor fix - needed for both Intel and NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Kernel parameters
  boot.kernelParams = [
    # Enable DRM kernel mode setting for NVIDIA
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    # Preserve video memory after suspend
    # DISABLED: Can cause issues with compositor restarts (Hyprland exit/re-login)
    # "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # Optional: Create aliases for running apps on NVIDIA
  # These will be available in your shell after rebuilding
  environment.shellAliases = {
    # Examples of using NVIDIA for specific applications
    # "nvidia-steam" = "nvidia-offload steam";
    # "nvidia-games" = "nvidia-offload";
  };
}
