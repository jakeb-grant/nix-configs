{ config, pkgs, ... }:

{
  # Bash configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -alh";
      ls = "eza";
      cat = "bat";
      grep = "rg";
      find = "fd";

      # NixOS shortcuts
      rebuild-desktop = "sudo nixos-rebuild switch --flake /home/user/nix-configs#desktop";
      rebuild-laptop = "sudo nixos-rebuild switch --flake /home/user/nix-configs#laptop";
      update-flake = "cd /home/user/nix-configs && nix flake update";
    };

    initExtra = ''
      # Custom prompt
      PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    '';
  };

  # Starship prompt (alternative to custom PS1)
  # programs.starship = {
  #   enable = true;
  #   settings = {
  #     add_newline = false;
  #   };
  # };
}
