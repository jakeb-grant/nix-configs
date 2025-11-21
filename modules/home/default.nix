{ config, pkgs, lib, ... }:

{
  # Configure home-manager using main-user module
  home-manager.users.${config.main-user.userName} = { pkgs, osConfig, ... }: {
    imports = [
      ./programs/shell.nix
      ./programs/git.nix
    ] ++ lib.optionals (osConfig.desktop-environment.enable or false) [
      ./desktop/common
    ] ++ lib.optionals ((osConfig.desktop-environment.de or "none") == "plasma") [
      ./desktop/plasma
    ] ++ lib.optionals ((osConfig.desktop-environment.de or "none") == "hyprland") [
      ./desktop/hyprland
    ];

    # Home Manager version
    home.stateVersion = "25.05";

    # User packages (CLI tools only, GUI apps in desktop/common)
    home.packages = with pkgs; [
      # Terminal utilities
      ripgrep
      fd
      bat
      eza
      fzf
      tmux

      # Terminal-based development tools
      gh        # github cli
      fnm       # fast node manager

      # System monitoring
      btop
    ];

    programs.claude-code = {
      enable = true;
      mcpServers = {
        svelte = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@sveltejs/mcp"
          ];
        };
      };
    };

    # Session variables
    home.sessionVariables = {
      EDITOR = "zed-editor";
    };

    # Note: Unfree packages are allowed system-wide in modules/system/core.nix
  };
}
