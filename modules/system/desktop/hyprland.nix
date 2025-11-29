{
  config,
  pkgs,
  lib,
  ...
}:

{
  config =
    lib.mkIf (config.desktop-environment.enable && config.desktop-environment.de == "hyprland")
      {
        # Hyprland Wayland Compositor
        programs.hyprland.enable = true;
        programs.hyprland.withUWSM = true; # Enable UWSM for proper systemd integration

        # Display manager: GDM (GNOME Display Manager - best Wayland support)
        services.displayManager.gdm.enable = true;
        services.displayManager.gdm.wayland = true;

        # GNOME Keyring for storing secrets (WiFi passwords, etc.)
        # Required for NetworkManager to remember WiFi passwords
        services.gnome.gnome-keyring.enable = true;

        # GVFS for virtual filesystem support (trash, network locations, etc.)
        # Needed for Nautilus and other GTK file managers
        services.gvfs.enable = true;

        # Enable auto-unlock of keyring on login
        security.pam.services.gdm.enableGnomeKeyring = true;
        security.pam.services.login.enableGnomeKeyring = true;
        security.pam.services.passwd.enableGnomeKeyring = true;

        # Note: User packages (terminal, launcher, etc.) are managed via home-manager
        # See modules/home/desktop/hyprland/default.nix

        # XDG portal for screen sharing, file picker, etc. (system-level requirement)
        xdg.portal = {
          enable = true;
          wlr.enable = lib.mkForce false; # Hyprland has its own portal
          extraPortals = with pkgs; [
            xdg-desktop-portal-hyprland
            xdg-desktop-portal-gtk
          ];
        };

        # Hyprland-specific environment variables
        environment.sessionVariables = {
          # Enable Wayland for Electron apps (VSCode, Discord, etc.)
          NIXOS_OZONE_WL = "1";
        };
      };
}
