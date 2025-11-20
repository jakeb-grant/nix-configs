{ config, pkgs, osConfig, lib, ... }:

let
  # Access main-user config from system configuration
  mainUser = osConfig.main-user;
  # Use gitName if set, otherwise fall back to description
  gitUserName = if mainUser.gitName != "" then mainUser.gitName else mainUser.description;
in
{
  programs.git = {
    enable = true;

    userName = gitUserName;
    userEmail = mainUser.email;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "vim";
    };
  };
}
