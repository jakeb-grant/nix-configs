{ pkgs, ... }:

{
  # Hyprland home-manager configuration

  # Hyprland configuration file
  wayland.windowManager.hyprland = {
    enable = true;

    # Enable systemd integration for better service management
    systemd.enable = true;

    # Enable XWayland for X11 app compatibility
    xwayland.enable = true;

    settings = {
      # Example basic configuration
      # Customize this based on your preferences

      "$mod" = "SUPER";

      # Monitor configuration
      monitor = [
        ",preferred,auto,1" # Auto-detect and use preferred resolution
      ];

      # Auto-start applications
      exec-once = [
        "nm-applet --indicator" # NetworkManager applet (WiFi secrets agent)
        "mako" # Notification daemon
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" # Polkit agent
      ];

      # Keybindings
      bind = [
        "$mod, RETURN, exec, ghostty"
        "$mod SHIFT, RETURN, exec, zeditor"
        "$mod, Q, killactive,"
        "$mod, M, exit,"
        "$mod, E, exec, thunar"
        "$mod, V, togglefloating,"
        "$mod, D, exec, rofi -show drun"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"

        # Screenshots
        ", Print, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        "SHIFT, Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Switch workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # Decoration
      decoration = {
        rounding = 5;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = false;
        };
        sensitivity = 0;
      };

      # Cursor configuration
      # NOTE: This is a universal Wayland setting, not GPU-specific
      # Disables hardware cursor plane (uses software rendering instead)
      # Necessary for many GPUs on Wayland, keeps config portable across hardware
      cursor = {
        no_hardware_cursors = true;
        default_monitor = "";
      };

      # Misc settings
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vfr = true; # Variable frame rate (saves power)
        vrr = 0; # VRR off (0), on (1), or fullscreen only (2)
      };
    };
  };

  # Waybar configuration
  programs.waybar = {
    enable = true;

    # Enable systemd integration for auto-start
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };

    # Basic configuration - customize as needed
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "network"
          "pulseaudio"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{id}";
        };

        clock = {
          format = "{:%Y-%m-%d %H:%M}";
        };

        battery = {
          format = "{capacity}% {icon}";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        network = {
          format-wifi = "{essid} ";
          format-disconnected = "Disconnected ";
        };

        pulseaudio = {
          format = "{volume}% {icon}";
          format-muted = "";
          format-icons = {
            default = [
              ""
              ""
              ""
            ];
          };
        };
      };
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(26, 27, 38, 0.9);
        color: #ffffff;
      }

      #workspaces button {
        padding: 0 5px;
        color: #ffffff;
      }

      #workspaces button.active {
        background-color: rgba(255, 255, 255, 0.2);
      }

      #clock, #battery, #network, #pulseaudio, #tray {
        padding: 0 10px;
      }
    '';
  };

  # Hyprland user packages
  home.packages = with pkgs; [
    # Terminal emulator (ghostty configured in desktop/common)
    # Alternatives: alacritty, foot, kitty

    # Application launcher
    rofi

    # Status bar (configured above via programs.waybar)
    # waybar is enabled via programs.waybar, not home.packages

    # Notification daemon
    mako
    libnotify

    # Screenshot utilities
    grim
    slurp

    # Clipboard manager
    wl-clipboard

    # Wallpaper daemon
    hyprpaper

    # Screen locker
    swaylock

    # File manager
    xfce.thunar

    # Network management applet
    networkmanagerapplet

    # Polkit authentication agent (for password prompts)
    polkit_gnome
  ];
}
