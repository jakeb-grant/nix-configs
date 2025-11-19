{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user.name = "Your Name";  # Change this
      user.email = "your.email@example.com";  # Change this
    };
}
