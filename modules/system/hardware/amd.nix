{ config, pkgs, ... }:

{
  # AMD GPU drivers
  services.xserver.videoDrivers = [ "amdgpu" ];

  # OpenGL/Vulkan support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit applications (games, Wine)

    extraPackages = with pkgs; [
      amdvlk         # Vulkan driver
      rocmPackages.clr.icd  # OpenCL
    ];

    # For 32-bit applications
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  # AMD-specific kernel parameters
  boot.kernelParams = [ "amdgpu.gpu_recovery=1" ];
}
