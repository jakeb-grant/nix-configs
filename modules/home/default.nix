{ config, pkgs, ... }:

{
  # Configure home-manager
  home-manager.users.user = { pkgs, ... }: {  # Change 'user' to your username
    imports = [
      ./programs/shell.nix
      ./programs/git.nix
    ];

    # Home Manager version
    home.stateVersion = "24.05";

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

      # File manager
      dolphin

      # System monitoring
      btop
    ];

    # Session variables
    home.sessionVariables = {
      EDITOR = "vim";
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
  };
}
