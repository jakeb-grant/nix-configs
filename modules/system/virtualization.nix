{ pkgs, ... }:

{
  # Enable libvirtd for virt-manager
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # TPM emulation support
      ovmf = {
        enable = true; # UEFI support
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  # Enable USB redirection for VMs
  virtualisation.spiceUSBRedirection.enable = true;

  # Add virt-manager to system packages for polkit integration
  programs.virt-manager.enable = true;

  # Ensure libvirt default network starts automatically
  systemd.services.libvirtd.postStart = ''
    sleep 1
    ${pkgs.libvirt}/bin/virsh net-list --name | grep -q default || \
      ${pkgs.libvirt}/bin/virsh net-define ${pkgs.libvirt}/var/lib/libvirt/network/default.xml
    ${pkgs.libvirt}/bin/virsh net-list --name | grep -q default && \
      ${pkgs.libvirt}/bin/virsh net-autostart default
    ${pkgs.libvirt}/bin/virsh net-list --name | grep -q default && \
      ${pkgs.libvirt}/bin/virsh net-start default || true
  '';
}
