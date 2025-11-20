{ config, pkgs, ... }:

{
  # Configure home-manager using main-user module
  home-manager.users.${config.main-user.userName} = { pkgs, ... }: {
    imports = [
      ./programs/shell.nix
      ./programs/git.nix
    ];

    # Home Manager version
    home.stateVersion = "25.05";

    # User packages
    home.packages = with pkgs; [
      # Terminal utilities
      ripgrep
      fd
      bat
      eza
      fzf
      tmux

      # Development tools
      neovim
      vscode

      # Web browser
      firefox

      # File manager (included with KDE Plasma, but can be explicitly added)
      kdePackages.dolphin

      # System monitoring
      btop
    ];

    # Session variables
    home.sessionVariables = {
      EDITOR = "vim";
    };

    # Note: Unfree packages are allowed system-wide in modules/system/core.nix
  };
}
