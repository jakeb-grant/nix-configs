{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable = lib.mkEnableOption "enable user module";

    userName = lib.mkOption {
      default = "mainuser";
      description = "Username for the main user account";
      type = lib.types.str;
    };

    description = lib.mkOption {
      default = "Main User";
      description = "Full name or description of the user";
      type = lib.types.str;
    };

    gitEmail = lib.mkOption {
      default = "";
      description = "Email address for git configuration";
      type = lib.types.str;
    };

    gitName = lib.mkOption {
      default = "";
      description = "Full name for git commits (defaults to description if empty)";
      type = lib.types.str;
    };

    shell = lib.mkOption {
      default = pkgs.bash;
      description = "Default shell for the user";
      type = lib.types.package;
    };

    extraGroups = lib.mkOption {
      default = [
        "networkmanager"
        "wheel"
        "video"
        "audio"
        "libvirtd"
        "docker"
      ];
      description = "Additional groups for the user";
      type = lib.types.listOf lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    # Create the user account
    users.users.${cfg.userName} = {
      isNormalUser = true;
      description = cfg.description;
      shell = cfg.shell;
      extraGroups = cfg.extraGroups;
      # To set password after install: passwd ${cfg.userName}
    };
  };
}
