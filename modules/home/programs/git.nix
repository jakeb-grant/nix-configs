{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    extraConfig = {
      user.name = "Your Name";  # Change this
      user.email = "your.email@example.com";  # Change this

      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "vim";

      # Aliases
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };

    # Delta for better diffs
    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = false;
      };
    };
  };
}
