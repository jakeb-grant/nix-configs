{ config, pkgs, ... }:

{
  # Common desktop application configurations
  # Shared across all desktop environments

  # GUI applications (require desktop environment)
  home.packages = with pkgs; [
    # Web browser
    firefox

    # Development tools
    vscode
  ];

  # Future: Add shared GUI application configs here
  # For example:
  # programs.vscode = { ... };
  # programs.firefox = { ... };
}
