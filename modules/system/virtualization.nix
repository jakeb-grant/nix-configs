{ pkgs, ... }:

{
  # Enable docker
  virtualisation.docker.enable = true;

  # Enable libvirtd for virt-manager
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true; # TPM emulation support
      # OVMF (UEFI) images are now available by default with QEMU
    };
  };

  # Enable USB redirection for VMs
  virtualisation.spiceUSBRedirection.enable = true;

  # Add virt-manager to system packages for polkit integration
  programs.virt-manager.enable = true;

  # Create and configure the default network
  systemd.services.libvirtd.postStart =
    let
      defaultNetworkXml = pkgs.writeText "default-network.xml" ''
        <network>
          <name>default</name>
          <forward mode='nat'/>
          <bridge name='virbr0' stp='on' delay='0'/>
          <ip address='192.168.122.1' netmask='255.255.255.0'>
            <dhcp>
              <range start='192.168.122.2' end='192.168.122.254'/>
            </dhcp>
          </ip>
        </network>
      '';
    in
    ''
      sleep 1
      # Check if default network exists, if not create it
      if ! ${pkgs.libvirt}/bin/virsh net-info default &>/dev/null; then
        ${pkgs.libvirt}/bin/virsh net-define ${defaultNetworkXml}
        ${pkgs.libvirt}/bin/virsh net-autostart default
        ${pkgs.libvirt}/bin/virsh net-start default
      fi
    '';
}
