{
  config,
  pkgs,
  osConfig,
  ...
}:

let
  # Import theme colors from system config
  theme = osConfig.theme.colors;
in
{
  # Hyprland home-manager configuration

  # GTK configuration (for icon theme support in rofi)
  # NOTE: On first-time setup with existing GTK configs, you may need to:
  # 1. Back up existing files: mv ~/.config/gtk-{3,4}.0 ~/gtk-config-backup/
  # 2. Or add force flags (uncomment below) to overwrite:
  #    xdg.configFile."gtk-3.0/settings.ini".force = true;
  #    xdg.configFile."gtk-4.0/settings.ini".force = true;
  #    xdg.configFile."gtk-4.0/gtk.css".force = true;
  #    home.file.".gtkrc-2.0".force = true;

  gtk = {
    enable = true;
    theme = {
      name = osConfig.theme.gtk.themeName;
      package = pkgs.${osConfig.theme.gtk.themePackage};
    };
    iconTheme = {
      name = osConfig.theme.gtk.iconThemeName;
      package = pkgs.${osConfig.theme.gtk.iconThemePackage};
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3.extraCss = osConfig.theme.gtk.gtk3Css;
    gtk3.extraConfig = {
      enable-inspector-keybinding = true;
    };
    gtk4.extraCss = osConfig.theme.gtk.gtk4Css;
    # GTK4 doesn't support enable-inspector-keybinding (GTK3 only)
    # Inspector is always available in GTK4 with Ctrl+Shift+I/D
  };

  # Hide rofi-theme-selector from app launcher
  xdg.dataFile."applications/rofi-theme-selector.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Rofi Theme Selector
      NoDisplay=true
    '';
  };

  # Rofi configuration
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    font = "JetBrainsMono Nerd Font 12";
    terminal = "${pkgs.ghostty}/bin/ghostty";
  };

  # Rofi custom theme (uses theme system)
  # Rofi theme from centralized theme system
  home.file.".config/rofi/carbonfox.rasi" = {
    force = true;
    text = osConfig.theme.rofi.rasi;
  };

  # Set rofi theme
  xdg.configFile."rofi/config.rasi" = {
    force = true;
    text = ''
      configuration {
        modi: "drun,run,window";
        font: "JetBrainsMono Nerd Font 12";
        terminal: "${pkgs.ghostty}/bin/ghostty";
        show-icons: true;
        display-drun: "";
        display-run: "";
        display-window: "";
        drun-display-format: "{name}";
        icon-theme: "Papirus-Dark";
      }
      @theme "carbonfox"
    '';
  };

  # Hyprland configuration file
  wayland.windowManager.hyprland = {
    enable = true;

    # Disable systemd integration - conflicts with UWSM (as per Hyprland docs)
    # UWSM is enabled in system config via programs.hyprland.withUWSM
    #
    # DESIGN CHOICE: This is disabled universally (even on non-NVIDIA hardware)
    # to keep configuration consistent across different hardware profiles.
    # UWSM works fine on all hardware, and this avoids conditional logic.
    #
    # CONSEQUENCE: When systemd integration is disabled:
    # 1. Apps must be added to the exec-once block below (not systemd services)
    # 2. Programs with systemd options (like waybar) must have systemd.enable = false
    # 3. Apps won't auto-restart if they crash (must manually relaunch or restart Hyprland)
    systemd.enable = false;

    # Enable XWayland for X11 app compatibility
    xwayland.enable = true;

    settings = {
      # Example basic configuration
      # Customize this based on your preferences

      "$mod" = "SUPER";

      # Environment variables
      env = [
        "GSK_RENDERER,gl" # Fix GTK4 flickering (use GL renderer instead of Vulkan)
        "GDK_BACKEND, wayland, x11" # Fix backend
        "XCURSOR_THEME,Bibata-Modern-Classic" # Cursor theme
        "XCURSOR_SIZE,24" # Cursor size
      ];

      # Monitor configuration
      monitor = [
        ",preferred,auto,1" # Auto-detect and use preferred resolution
      ];

      # Auto-start applications
      exec-once = [
        "hyprpaper" # Wallpaper daemon
        "waybar" # Status bar (systemd integration incompatible with disabled Hyprland systemd)
        "nm-applet --indicator" # NetworkManager applet (WiFi secrets agent - runs in background)
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" # Polkit agent
        "hyprctl setcursor Bibata-Modern-Classic 24" # Set cursor theme
        "wl-paste --type text --watch cliphist store" # Clipboard history daemon (text)
        "wl-paste --type image --watch cliphist store" # Clipboard history daemon (images)
      ];

      # Keybindings
      bind = [
        "$mod, RETURN, exec, ghostty +new-window"
        "$mod SHIFT, RETURN, exec, zeditor"
        "$mod, Q, killactive,"
        "$mod, M, exit,"
        "$mod, E, exec, nautilus --new-window"
        "$mod, V, togglefloating,"
        "$mod, D, exec, rofi -show drun"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"

        # Screen lock
        "$mod, L, exec, swaylock"

        # Screenshots (automatically copied to clipboard)
        ", Print, exec, grim - | wl-copy && grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        "SHIFT, Print, exec, grim -g \"$(slurp)\" - | wl-copy && grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        # Screenshot to clipboard only (no file saved)
        "CTRL, Print, exec, grim - | wl-copy"
        "CTRL SHIFT, Print, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Clipboard history manager
        "$mod SHIFT, V, exec, cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy"

        # Color picker (hyprpicker copies hex to clipboard)
        "$mod SHIFT, C, exec, hyprpicker -a"

        # Laptop function keys (brightness & volume)
        # These keysyms only exist on laptops, harmless on desktops
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

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
        "col.active_border" = "${theme.accentBorder}";
        "col.inactive_border" = "${theme.borderInactive}";
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
          color = "${theme.shadowColor}";
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

      # Window rules
      windowrulev2 = [
        # Rofi should float and be centered
        "float, class:^(rofi)$"
        "center, class:^(rofi)$"
        "stayfocused, class:^(rofi)$"
        "dimaround, class:^(rofi)$"
      ];
    };
  };

  # Waybar configuration
  programs.waybar = {
    enable = true;

    # Disable systemd integration - hyprland-session.target doesn't exist
    # when Hyprland's systemd integration is disabled for UWSM
    systemd.enable = false;

    # Basic configuration - customize as needed
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        modules-left = [
          "clock"
          "hyprland/workspaces"
        ];
        modules-center = [ ];
        modules-right = [
          "cpu"
          "memory"
          "temperature"
          "disk"
          "backlight"
          "pulseaudio"
          "network"
          "battery"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "󰹟";
            "2" = "󰹟";
            "3" = "󰹟";
            "4" = "󰹟";
            "5" = "󰹟";
            "6" = "󰹟";
            "7" = "󰹟";
            "8" = "󰹟";
            "9" = "󰹟";
            default = "";
            urgent = "";
          };
        };

        cpu = {
          format = " {usage}%";
          tooltip = true;
          interval = 2;
          tooltip-format = "CPU: {usage}%\nLoad: {load}";
          on-click = "ghostty -e btop";
        };

        memory = {
          format = " {used:0.1f}GB ({percentage}%)";
          tooltip = true;
          interval = 5;
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB ({percentage}%)";
          on-click = "ghostty -e btop";
        };

        temperature = {
          format = " {temperatureC}°C";
          format-critical = " {temperatureC}°C";
          critical-threshold = 80;
          interval = 2;
          tooltip-format = "Temperature: {temperatureC}°C / {temperatureF}°F";
        };

        disk = {
          format = " {percentage_used}%";
          path = "/";
          interval = 30;
          tooltip-format = "Disk: {used} / {total} ({percentage_used}%)\nAvailable: {free}";
          on-click = "ghostty -e btop";
        };

        clock = {
          format = "{:%A, %b %d %I:%M %p}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            weeks-pos = "left";
            format = {
              months = "<span color='${theme.accent}'><b>{}</b></span>";
              days = "<span color='${theme.fg}'><b>{}</b></span>";
              weeks = "<span color='${theme.info}'><b>W{}</b></span>";
              weekdays = "<span color='${theme.warning}'><b>{}</b></span>";
              today = "<span color='${theme.error}'><b><u>{}</u></b></span>";
            };
          };
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [
            "󰂎" # 0-20% (empty)
            "󰁺" # 20-40% (low)
            "󰁻" # 40-60% (medium)
            "󰁼" # 60-80% (good)
            "󰁽" # 80-100% (full)
          ];
          format-charging = "󰂄 {capacity}%"; # Charging icon
          format-plugged = "󰚥 {capacity}%"; # Plugged icon
          format-full = "󰁹 {capacity}%"; # Full/charged icon
        };

        network = {
          format-wifi = "{icon} {essid}";
          format-ethernet = "󰈀 {ifname}";
          format-disconnected = "󰖪 Disconnected";
          format-icons = [
            "󰤯" # Weak signal
            "󰤟" # Fair signal
            "󰤢" # Good signal
            "󰤥" # Excellent signal
            "󰤨" # Full signal
          ];
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}: {ipaddr}";
          on-click = "rofi-network-manager";
        };

        backlight = {
          format = "{icon} {percent}%";
          format-icons = [
            "󱩏" # 0-20%
            "󱩑" # 20-40%
            "󱩓" # 40-60%
            "󱩕" # 60-80%
            "󰛨" # 80-100%
          ];
          tooltip-format = "Brightness: {percent}%";
          on-scroll-up = "brightnessctl set +5%";
          on-scroll-down = "brightnessctl set 5%-";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰖁 {volume}%";
          format-icons = {
            default = [
              "󰕿" # Low volume (0-33%)
              "󰖀" # Medium volume (34-66%)
              "󰕾" # High volume (67-100%)
            ];
          };
          max-volume = 100;
          scroll-step = 1;
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
      };
    };
    # Waybar CSS from centralized theme system
    style = osConfig.theme.waybar.css;
  };

  # Hyprpaper configuration (wallpaper daemon)
  home.file.".config/hypr/hyprpaper.conf" = {
    force = true;
    text = ''
      # Preload all wallpapers for dynamic switching
      preload = ${config.home.homeDirectory}/nix-configs/wallpapers/violet-lake.png
      preload = ${config.home.homeDirectory}/nix-configs/wallpapers/safe_landing_horizontal.jpg
      preload = ${config.home.homeDirectory}/nix-configs/wallpapers/courtside-sunset.png
      preload = ${config.home.homeDirectory}/nix-configs/wallpapers/everforest.jpg
      preload = ${config.home.homeDirectory}/nix-configs/wallpapers/forest-jade.jpg
      preload = ${config.home.homeDirectory}/nix-configs/wallpapers/pastel-window.png

      # Set default wallpaper for all monitors
      # Format: wallpaper = monitor,path
      # Empty monitor name = apply to all monitors
      wallpaper = ,${config.home.homeDirectory}/nix-configs/wallpapers/violet-lake.png

      # Disable splash text
      splash = false

      # Enable IPC for dynamic wallpaper switching
      ipc = on
    '';
  };

  # Mako notification daemon configuration
  services.mako = {
    enable = true;

    # Urgency-specific styling using criteria
    extraConfig = ''
      [urgency=low]
      border-color=${theme.accent}
      default-timeout=3000

      [urgency=normal]
      border-color=${theme.accent}
      default-timeout=5000

      [urgency=critical]
      border-color=${theme.error}
      background-color=${theme.bg}
      default-timeout=0
    '';

    settings = {
      # Default notification style
      font = "JetBrainsMono Nerd Font 11";
      width = 350;
      height = 150;
      margin = "10";
      padding = "15";
      border-size = 2;
      border-radius = 8;

      # Carbonfox colors
      background-color = theme.bgAlt;
      text-color = theme.fg;
      border-color = theme.border;

      # Progress bar color
      progress-color = "over ${theme.accent}";

      # Icon settings
      icons = true;
      max-icon-size = 48;
      icon-location = "left";

      # Behavior
      default-timeout = 5000; # 5 seconds
      ignore-timeout = false;
      max-visible = 5;
      sort = "-time"; # Sort by time, newest first
      layer = "overlay"; # Show above other windows
      anchor = "top-right";

      # Grouped notifications
      group-by = "app-name,summary";

      # Actions
      actions = true;
      history = true;
      max-history = 100;

      # Format
      format = "<b>%s</b>\\n%b";

      # Click behavior
      on-button-left = "dismiss";
      on-button-middle = "none";
      on-button-right = "dismiss-all";
      on-touch = "dismiss";
    };
  };

  # Hyprland user packages
  home.packages = with pkgs; [
    # Terminal emulator (ghostty configured in desktop/common)
    # Alternatives: alacritty, foot, kitty

    # Application launcher (rofi configured via programs.rofi above)
    rofi-network-manager # Rofi-based WiFi/network manager
    papirus-icon-theme # Icon theme for rofi

    # Status bar (configured above via programs.waybar)
    # waybar is enabled via programs.waybar, not home.packages

    # Notification daemon (mako configured via services.mako above)
    libnotify # Command-line tool to send notifications

    # Screenshot utilities
    grim
    slurp
    hyprpicker

    # Clipboard manager
    wl-clipboard # Basic clipboard utilities (wl-copy, wl-paste)
    cliphist # Clipboard history manager

    # Wallpaper daemon
    hyprpaper

    # Screen locker
    swaylock

    # Brightness control (laptop function keys)
    brightnessctl

    # File manager
    nautilus

    # Network management applet
    networkmanagerapplet

    # Polkit authentication agent (for password prompts)
    polkit_gnome
  ];
}
