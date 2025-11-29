let
  # Helper to convert hex color to RGB values
  hexToRgb =
    hex:
    let
      # Remove # if present
      cleanHex = builtins.substring (if builtins.substring 0 1 hex == "#" then 1 else 0) 6 hex;
      # Convert hex pairs to decimal
      hexToDec =
        h:
        let
          charToNum =
            c:
            if c == "0" then
              0
            else if c == "1" then
              1
            else if c == "2" then
              2
            else if c == "3" then
              3
            else if c == "4" then
              4
            else if c == "5" then
              5
            else if c == "6" then
              6
            else if c == "7" then
              7
            else if c == "8" then
              8
            else if c == "9" then
              9
            else if c == "a" || c == "A" then
              10
            else if c == "b" || c == "B" then
              11
            else if c == "c" || c == "C" then
              12
            else if c == "d" || c == "D" then
              13
            else if c == "e" || c == "E" then
              14
            else if c == "f" || c == "F" then
              15
            else
              0;
          high = charToNum (builtins.substring 0 1 h);
          low = charToNum (builtins.substring 1 1 h);
        in
        high * 16 + low;
      r = hexToDec (builtins.substring 0 2 cleanHex);
      g = hexToDec (builtins.substring 2 2 cleanHex);
      b = hexToDec (builtins.substring 4 2 cleanHex);
    in
    "${toString r}, ${toString g}, ${toString b}";

  # Helper function to convert opacity (0.0-1.0) to hex alpha (00-FF)
  opacityToHex =
    opacity:
    let
      # Calculate alpha value (0-255)
      alphaInt = builtins.floor (opacity * 255 + 0.5); # Round to nearest integer
      # Convert to hex string
      toHexDigit =
        n:
        builtins.elemAt [
          "0"
          "1"
          "2"
          "3"
          "4"
          "5"
          "6"
          "7"
          "8"
          "9"
          "A"
          "B"
          "C"
          "D"
          "E"
          "F"
        ] n;
      high = toHexDigit (alphaInt / 16);
      low = toHexDigit (builtins.bitAnd alphaInt 15);
    in
    high + low;

  # Global opacity values (must be floating point)
  opacity = 0.99; # Main window opacity

  # Common opacity values
  opacities = {
    high = 0.93; # For borders and shadows (ee in hex)
    medium = 0.67; # For inactive elements (aa in hex)
    glow = {
      close = 0.5; # Closest glow layer
      mid = 0.3; # Middle glow layer
      far = 0.2; # Farthest glow layer
    };
    subtle = 0.15; # For very subtle overlays
    hover = 0.1; # For hover backgrounds
  };

  # Calculate hex alpha once
  alphaHex = opacityToHex opacity;

  # Color definitions (centralized)
  colors =
    let
      # Define base hex colors first
      bgHex = "#161616";
      bgAltHex = "#2a2a2a";
      fgHex = "#f2f4f8";
      fgAltHex = "#b6b8bb";
      accentHex = "#3ddbd9";
      hoverBaseHex = "#f6f6f6";

      # Semantic hex colors
      successHex = "#8af2a1";
      warningHex = "#ffc591";
      errorHex = "#ee5396";
      infoHex = "#ae81ff";

      # UI element hex colors
      borderHex = "#3a3a3a";
      borderInactiveHex = "#595959";
      shadowHex = "#1a1a1a";
    in
    {
      # Base colors
      bg = bgHex; # Background (hex)
      bgWithOpacity = "${bgHex}${alphaHex}"; # Background with opacity (calculated)
      bgRgba = "rgba(${hexToRgb bgHex}, ${toString opacity})"; # Background with opacity (rgba)
      bgAlt = bgAltHex; # Alternate background (lighter than bg for better visibility)
      fg = fgHex; # Foreground/text
      fgAlt = fgAltHex; # Alternate foreground/comments

      # Accent colors
      accent = accentHex; # Primary accent (cyan)
      accentRgba = "rgba(${hexToRgb accentHex}, ${toString opacities.subtle})"; # Accent with low opacity (CSS format)
      accentBorder = "rgba(${builtins.substring 1 6 accentHex}${opacityToHex opacities.high})"; # Hyprland format: rgba(HEXaa)
      hover = "rgba(${hexToRgb hoverBaseHex}, ${toString opacities.hover})"; # Hover state background

      # Semantic colors
      success = successHex; # Green (for battery, success states)
      warning = warningHex; # Orange (for warnings, volume)
      error = errorHex; # Pink/Red (for errors, critical states)
      info = infoHex; # Purple (for info, network)

      # UI element colors
      border = borderHex; # Subtle borders for UI separators
      borderInactive = "rgba(${
        builtins.substring 1 6 borderInactiveHex
      }${opacityToHex opacities.medium})"; # Hyprland format: rgba(HEXaa)
      shadowColor = "rgba(${builtins.substring 1 6 shadowHex}${opacityToHex opacities.high})"; # Hyprland format: rgba(HEXaa)
    };
in
{
  # Carbonfox theme definition
  # A dark theme with carbon black background and cyan accents

  # Export colors and opacity
  colors = colors;
  opacity = opacity;
  isDark = true; # Carbonfox is a dark theme

  # Zed editor configuration
  zed = {
    theme = "Carbonfox - blurred";
    overrides = {
      # Global background - only this one should have transparency
      # All other backgrounds are opaque to prevent layering/compounding transparency
      background = "${colors.bg}${alphaHex}";

      # Main editor - opaque (sits on top of global transparent background)
      "editor.background" = "${colors.bg}00";
      "editor.gutter.background" = "${colors.bg}00";
      # "editor.active_line.background" = "${colors.bgAlt}"; # bgAlt for subtle highlight

      # Terminal - opaque
      "terminal.background" = "${colors.bg}00";

      # Panels and chrome - opaque
      "panel.background" = "${colors.bg}00"; # File tree sidebar
      "toolbar.background" = "${colors.bg}00"; # Top toolbar
      "tab_bar.background" = "${colors.bg}00"; # Tab bar
      "status_bar.background" = "${colors.bg}${alphaHex}"; # Bottom status bar
      "title_bar.background" = "${colors.bg}${alphaHex}"; # Top menu bar (File, Edit, View, etc.)
      "title_bar.inactive_background" = "${colors.bg}${alphaHex}"; # Title bar when window inactive
    };
  };

  # Waybar CSS styling
  waybar = {
    css =
      let
        c = colors;
        # Helper to create glow effect from any color
        glow =
          color:
          let
            rgb = hexToRgb color;
          in
          ''
            0 0 3px rgba(${rgb}, ${toString opacities.glow.close}),
            0 0 6px rgba(${rgb}, ${toString opacities.glow.mid}),
            0 0 9px rgba(${rgb}, ${toString opacities.glow.far})
          '';
      in
      ''
        * {
          font-family: "JetBrainsMono Nerd Font Propo", monospace;
          font-weight: bold;
          font-size: 13px;
          border: none;
          border-radius: 0;
        }

        window#waybar {
          background-color: ${c.bg};
        }

        tooltip {
          background: ${c.bg};
          color: ${c.fg};
          border-radius: 5px;
          border: 1px solid ${c.border};
          padding: 5px 10px;
          margin: 0;
        }

        #workspaces label {
          font-size: 30px;
        }

        #workspaces button {
          padding: 0px 8px 0px 8px;
          color: ${c.fgAlt};
          background-color: transparent;
          background: transparent;
          box-shadow: none;
          text-shadow: none;
          animation: none;
        }

        #workspaces button:hover {
          background-color: ${c.hover};
          background: ${c.hover};
          color: ${c.fg};
          box-shadow: none;
          text-shadow: ${glow c.fg};
          animation: none;
        }

        #workspaces button.active {
          padding: 0px 8px 0px 8px;
          color: ${c.accent};
          background-color: transparent;
          background: transparent;
          box-shadow: none;
          text-shadow: ${glow c.accent};
          animation: none;
        }

        #workspaces button.active:hover {
          background-color: ${c.hover};
          background: ${c.hover};
          color: ${c.accent};
          text-shadow: ${glow c.accent};
        }

        #clock {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.accent};
          text-shadow: ${glow c.accent};
        }

        #cpu {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.info};
          text-shadow: ${glow c.info};
        }

        #memory {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.info};
          text-shadow: ${glow c.info};
        }

        #temperature {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.info};
          text-shadow: ${glow c.info};
        }

        #temperature.critical {
          color: ${c.error};
          text-shadow: ${glow c.error};
        }

        #disk {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.info};
          text-shadow: ${glow c.info};
        }

        #battery {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.success};
          text-shadow: ${glow c.success};
        }

        #battery.charging {
          color: ${c.success};
        }

        #battery.warning:not(.charging) {
          color: ${c.warning};
        }

        #battery.critical:not(.charging) {
          color: ${c.error};
          animation: blink 1s linear infinite;
        }

        @keyframes blink {
          50% {
            opacity: 0.5;
          }
        }

        #network {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.success};
          text-shadow: ${glow c.success};
        }

        #network.disconnected {
          color: ${c.error};
        }

        #backlight {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.warning};
          text-shadow: ${glow c.warning};
        }

        #pulseaudio {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.warning};
          text-shadow: ${glow c.warning};
        }

        #pulseaudio.muted {
          color: ${c.fgAlt};
        }
      '';
  };

  # Rofi theme configuration
  rofi = {
    rasi =
      let
        c = colors;
      in
      ''
        * {
          bg: ${c.bgWithOpacity};
          bg-alt: ${c.bgAlt};
          fg: ${c.fg};
          fg-alt: ${c.fgAlt};

          background-color: transparent;
          text-color: @fg;

          accent: ${c.accent};
          urgent: ${c.error};
          active: ${c.success};
        }

        window {
          transparency: "real";
          background-color: @bg;
          border: 2px;
          border-color: @bg-alt;
          border-radius: 8px;
          width: 600px;
          location: center;
          anchor: center;
        }

        mainbox {
          spacing: 10px;
          padding: 20px;
          background-color: transparent;
        }

        inputbar {
          spacing: 10px;
          padding: 10px;
          border-radius: 4px;
          background-color: @bg-alt;
          children: [ prompt, entry ];
        }

        prompt {
          text-color: @accent;
          background-color: transparent;
        }

        entry {
          placeholder: "Search...";
          placeholder-color: @fg-alt;
          background-color: transparent;
        }

        listview {
          columns: 1;
          lines: 8;
          cycle: true;
          scrollbar: false;
          spacing: 5px;
          background-color: transparent;
        }

        element {
          padding: 10px;
          border-radius: 4px;
          background-color: transparent;
        }

        element selected.normal {
          background-color: @accent;
          text-color: @bg;
        }

        element selected.urgent {
          background-color: @urgent;
          text-color: @bg;
        }

        element selected.active {
          background-color: @active;
          text-color: @bg;
        }

        element-text {
          background-color: transparent;
          text-color: inherit;
        }

        element-icon {
          background-color: transparent;
          size: 24px;
        }

        message {
          padding: 10px;
          border-radius: 4px;
          background-color: @bg-alt;
        }

        textbox {
          background-color: transparent;
        }
      '';
  };

  # GTK theme configuration
  gtk = {
    # Base GTK theme (dark variant of Adwaita)
    themeName = "Adwaita-dark";
    themePackage = "gnome-themes-extra"; # Package name as string for pkgs lookup

    # Icon theme
    iconThemeName = "Papirus-Dark";
    iconThemePackage = "papirus-icon-theme"; # Package name as string for pkgs lookup

    # GTK3 CSS - Empty to use base Adwaita-dark theme without overrides
    # We only customize GTK4 (for Nautilus), leaving GTK3 apps with clean Adwaita-dark
    gtk3Css = "";

    # GTK4 CSS
    gtk4Css =
      let
        c = colors;
      in
      ''
        /* Carbonfox theme color overrides for GTK4 */

        /* Window colors */
        @define-color window_bg_color ${c.bg};
        @define-color window_fg_color ${c.fg};

        /* View colors */
        @define-color view_bg_color ${c.bgAlt};
        @define-color view_fg_color ${c.fg};

        /* Accent colors */
        @define-color accent_bg_color ${c.accent};
        @define-color accent_fg_color ${c.bg};

        /* Header bar */
        @define-color headerbar_bg_color ${c.bg};
        @define-color headerbar_fg_color ${c.fg};

        /* Cards and popovers */
        @define-color card_bg_color ${c.bgAlt};
        @define-color card_fg_color ${c.fg};
        @define-color popover_bg_color ${c.bgAlt};
        @define-color popover_fg_color ${c.fg};

        /* Borders */
        @define-color borders ${c.border};

        /* Semantic colors */
        @define-color success_color ${c.success};
        @define-color warning_color ${c.warning};
        @define-color error_color ${c.error};

        /* Navigation sidebar (Nautilus left panel) - darker */
        .navigation-sidebar {
          background-color: ${c.bg};
          color: ${c.fg};
        }

        /* Main file view area - lighter for contrast */
        .view {
          background-color: ${c.bgAlt};
          color: ${c.fg};
        }

        /* Top bar (header bar) */
        .top-bar {
          background-color: ${c.bg};
          color: ${c.fg};
        }

        /* Paned separator borders (sidebar, split views) */
        paned separator {
          background-color: @borders;
        }
      '';
  };

  # Firefox theme configuration
  firefox = {
    # userChrome.css - Styles the Firefox UI
    userChrome =
      let
        c = colors;
      in
      ''
        /* Carbonfox theme for Firefox UI */

        :root {
          /* Carbonfox color palette */
          --carbonfox-bg: ${c.bg};
          --carbonfox-bg-alt: ${c.bgAlt};
          --carbonfox-fg: ${c.fg};
          --carbonfox-fg-alt: ${c.fgAlt};
          --carbonfox-accent: ${c.accent};
          --carbonfox-border: ${c.border};
          --carbonfox-hover: ${c.hover};
          --carbonfox-success: ${c.success};
          --carbonfox-warning: ${c.warning};
          --carbonfox-error: ${c.error};
          --carbonfox-info: ${c.info};
        }

        /* Main browser window background */
        #main-window,
        #browser,
        #navigator-toolbox {
          background-color: var(--carbonfox-bg) !important;
        }

        /* Toolbar backgrounds */
        #nav-bar,
        #PersonalToolbar,
        #TabsToolbar {
          background-color: var(--carbonfox-bg) !important;
          border-color: var(--carbonfox-border) !important;
        }

        /* URL bar */
        #urlbar,
        #urlbar-background,
        #searchbar {
          background-color: var(--carbonfox-bg-alt) !important;
          color: var(--carbonfox-fg) !important;
          border-color: var(--carbonfox-border) !important;
        }

        #urlbar:focus-within,
        #searchbar:focus-within {
          border-color: var(--carbonfox-accent) !important;
        }

        /* Tabs */
        .tabbrowser-tab {
          color: var(--carbonfox-fg-alt) !important;
        }

        .tabbrowser-tab[selected="true"] {
          color: var(--carbonfox-accent) !important;
          background-color: var(--carbonfox-bg-alt) !important;
        }

        .tabbrowser-tab:hover:not([selected="true"]) {
          background-color: var(--carbonfox-hover) !important;
          color: var(--carbonfox-fg) !important;
        }

        /* Tab close button */
        .tab-close-button:hover {
          background-color: var(--carbonfox-error) !important;
        }

        /* Sidebar */
        #sidebar-box,
        #sidebar-header {
          background-color: var(--carbonfox-bg) !important;
          color: var(--carbonfox-fg) !important;
          border-color: var(--carbonfox-border) !important;
        }

        /* Context menus and dropdowns */
        menupopup,
        panel {
          background-color: var(--carbonfox-bg-alt) !important;
          color: var(--carbonfox-fg) !important;
          border-color: var(--carbonfox-border) !important;
        }

        menuitem:hover,
        menu:hover {
          background-color: var(--carbonfox-hover) !important;
          color: var(--carbonfox-accent) !important;
        }
      '';

    # userContent.css - Styles web content
    userContent =
      let
        c = colors;
      in
      ''
        /* Carbonfox theme for Firefox web content */

        /* Dark mode for about: pages */
        @-moz-document url-prefix(about:) {
          body {
            background-color: ${c.bg} !important;
            color: ${c.fg} !important;
          }

          a {
            color: ${c.accent} !important;
          }

          a:hover {
            color: ${c.info} !important;
          }
        }

        /* New tab page */
        @-moz-document url("about:home"), url("about:newtab") {
          body {
            background-color: ${c.bg} !important;
            color: ${c.fg} !important;
          }

          .search-wrapper input {
            background-color: ${c.bgAlt} !important;
            color: ${c.fg} !important;
            border-color: ${c.border} !important;
          }

          .search-wrapper input:focus {
            border-color: ${c.accent} !important;
          }
        }
      '';
  };
}
