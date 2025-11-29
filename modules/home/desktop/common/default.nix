{
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  # Import theme from system config
  theme = osConfig.theme.colors;
  themeOpacity = osConfig.theme.opacity;
in
{
  # Common desktop application configurations
  # Shared across all desktop environments

  # GUI applications (require desktop environment)
  home.packages = with pkgs; [
    nil # Nix language server for Zed to use
    nixd # Nix language server for Zed to use
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [
      "svelte"
      "nix"
      "nvim-nightfox"
      "material-icon-theme"
    ];
    userSettings = {
      base_keymap = "VSCode";
      buffer_font_family = "JetBrainsMono Nerd Font";
      ui_font_family = "JetBrainsMono Nerd Font Propo";
      terminal = {
        font_family = "JetBrainsMono Nerd Font Mono";
      };
      theme = {
        mode = "system";
        dark = osConfig.theme.zed.theme;
        light = osConfig.theme.zed.theme;
      };
      # Theme overrides from centralized theme system
      theme_overrides = {
        "${osConfig.theme.zed.theme}" = osConfig.theme.zed.overrides;
      };
      icon_theme = {
        mode = "system";
        light = "Material Icon Theme";
        dark = "Material Icon Theme";
      };
      edit_predictions = {
        mode = "subtle";
      };
      features = {
        edit_prediction_provider = "zed";
      };
      # Tell Zed to use direnv and direnv can use a flake.nix environment
      load_direnv = "shell_hook";
      lsp = {
        nix = {
          binary = {
            path_lookup = true;
          };
        };
      };
    };
  };

  # Ghostty terminal emulator
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;

    settings = {
      # Font configuration (matching your Zed setup)
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12;

      # Theme colors (using theme system instead of built-in theme)
      background = "${theme.bg}";
      foreground = "${theme.fg}";
      background-opacity = themeOpacity; # Uses theme system opacity value
      background-blur = true;

      # Window appearance
      window-padding-x = 10;
      window-padding-y = 10;

      # Performance
      shell-integration = "bash";
    };
  };

  # btop system monitor
  programs.btop = {
    enable = true;
    settings = {
      # Color theme (using Carbonfox colors)
      color_theme = "carbonfox";
      theme_background = false; # Use terminal background

      # General settings
      vim_keys = false;
      rounded_corners = true;
      graph_symbol = "braille";
      shown_boxes = "cpu mem net proc";
      update_ms = 2000;
      proc_sorting = "cpu lazy";
      proc_tree = false;

      # CPU
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";

      # Memory
      mem_graphs = true;

      # Network
      net_auto = true;
      net_sync = true;
    };
  };

  # btop custom theme file
  home.file.".config/btop/themes/carbonfox.theme" = {
    force = true;
    text = ''
      # Carbonfox theme for btop
      # Main background, empty for terminal default
      theme[main_bg]="${theme.bg}"

      # Main text color
      theme[main_fg]="${theme.fg}"

      # Title color for boxes
      theme[title]="${theme.accent}"

      # Highlight color for keyboard shortcuts
      theme[hi_fg]="${theme.accent}"

      # Background color of selected items
      theme[selected_bg]="${theme.bgAlt}"

      # Foreground color of selected items
      theme[selected_fg]="${theme.accent}"

      # Color of inactive/disabled text
      theme[inactive_fg]="${theme.fgAlt}"

      # Color of text appearing on top of graphs
      theme[graph_text]="${theme.fg}"

      # Misc colors for processes box
      theme[proc_misc]="${theme.accent}"

      # CPU box outline color
      theme[cpu_box]="${theme.info}"

      # Memory/disks box outline color
      theme[mem_box]="${theme.info}"

      # Net up/down box outline color
      theme[net_box]="${theme.accent}"

      # Processes box outline color
      theme[proc_box]="${theme.info}"

      # Box divider line color
      theme[div_line]="${theme.border}"

      # Temperature graph colors (cool to hot)
      theme[temp_start]="${theme.accent}"
      theme[temp_mid]="${theme.warning}"
      theme[temp_end]="${theme.error}"

      # CPU graph colors
      theme[cpu_start]="${theme.info}"
      theme[cpu_mid]="${theme.info}"
      theme[cpu_end]="${theme.info}"

      # Memory graph colors
      theme[mem_start]="${theme.info}"
      theme[mem_mid]="${theme.info}"
      theme[mem_end]="${theme.info}"

      # Network upload graph colors
      theme[net_start]="${theme.accent}"
      theme[net_mid]="${theme.accent}"
      theme[net_end]="${theme.accent}"
    '';
  };

  # Force overwrite Firefox profiles.ini
  home.file.".mozilla/firefox/profiles.ini".force = true;

  # Firefox configuration
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      isDefault = true;
      name = "default";

      # Declarative bookmarks
      bookmarks = {
        force = true;
        settings = [
          {
            name = "Toolbar";
            toolbar = true;
            bookmarks = [
              {
                name = "NixOS";
                bookmarks = [
                  {
                    name = "NixOS Search";
                    url = "https://search.nixos.org";
                  }
                  {
                    name = "Home Manager Options";
                    url = "https://home-manager-options.extranix.com";
                  }
                  {
                    name = "NixOS Wiki";
                    url = "https://wiki.nixos.org";
                  }
                  {
                    name = "Nix Pills";
                    url = "https://nixos.org/guides/nix-pills";
                  }
                ];
              }
              {
                name = "Dev Tools";
                bookmarks = [
                  {
                    name = "GitHub";
                    url = "https://github.com";
                  }
                  {
                    name = "MDN Web Docs";
                    url = "https://developer.mozilla.org";
                  }
                  {
                    name = "DevDocs";
                    url = "https://devdocs.io";
                  }
                ];
              }
            ];
          }
        ];
      };

      # Firefox preferences (about:config)
      settings = {
        # Enable userChrome.css and userContent.css
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Dark mode preferences (from theme system)
        # Commented out to let websites show their defaults (usually light mode)
        # Uncomment to tell websites you prefer dark mode
        # "ui.systemUsesDarkTheme" = if osConfig.theme.isDark then 1 else 0;
        "browser.theme.dark-private-windows" = osConfig.theme.isDark;

        # Always show bookmarks toolbar
        "browser.toolbars.bookmarks.visibility" = "always";

        # Privacy and security
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;

        # Performance
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;

        # Smooth scrolling
        "general.smoothScroll" = true;

        # Disable pocket
        "extensions.pocket.enabled" = false;

        # New tab page
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      };

      # Custom UI styling (userChrome.css)
      userChrome = osConfig.theme.firefox.userChrome or "";

      # Custom web content styling (userContent.css)
      userContent = osConfig.theme.firefox.userContent or "";
    };
  };

}
