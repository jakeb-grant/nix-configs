let
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

  # Global opacity value (must be floating point)
  opacity = 0.99;

  # Calculate hex alpha once
  alphaHex = opacityToHex opacity;

  # Color definitions (centralized)
  colors = {
    # Base colors
    bg = "#161616"; # Background (hex)
    bgWithOpacity = "#161616${alphaHex}"; # Background with opacity (calculated)
    bgRgba = "rgba(22, 22, 22, ${toString opacity})"; # Background with opacity (rgba)
    bgAlt = "#2a2a2a"; # Alternate background (lighter than bg for better visibility)
    fg = "#f2f4f8"; # Foreground/text
    fgAlt = "#b6b8bb"; # Alternate foreground/comments

    # Accent colors
    accent = "#3ddbd9"; # Primary accent (cyan)
    accentRgba = "rgba(61, 219, 217, 0.15)"; # Accent with low opacity (CSS format)
    accentBorder = "rgba(3ddbd9ee)"; # Accent for Hyprland borders (Hyprland rgba format)
    hover = "rgba(246, 246, 246, 0.1)"; # Hover state background

    # Semantic colors
    success = "#8af2a1"; # Green (for battery, success states)
    warning = "#ffc591"; # Orange (for warnings, volume)
    error = "#ee5396"; # Pink/Red (for errors, critical states)
    info = "#ae81ff"; # Purple (for info, network)

    # UI element colors
    border = "#3a3a3a"; # Subtle borders for UI separators
    borderInactive = "rgba(595959aa)"; # Inactive borders (Hyprland rgba format)
    shadowColor = "rgba(1a1a1aee)"; # Shadow color (Hyprland rgba format)
  };
in
{
  # Carbonfox theme definition
  # A dark theme with carbon black background and cyan accents

  # Export colors and opacity
  colors = colors;
  opacity = opacity;

  # Zed editor configuration
  zed = {
    theme = "Carbonfox - blurred";
    overrides = {
      # Global background - only this one should have transparency
      # All other backgrounds are opaque to prevent layering/compounding transparency
      background = "#161616${alphaHex}";

      # Main editor - opaque (sits on top of global transparent background)
      "editor.background" = "#16161600";
      "editor.gutter.background" = "#16161600";
      # "editor.active_line.background" = "#0f0f0f"; # bgAlt for subtle highlight

      # Terminal - opaque
      "terminal.background" = "#16161600";

      # Panels and chrome - opaque
      "panel.background" = "#16161600"; # File tree sidebar
      "toolbar.background" = "#16161600"; # Top toolbar
      "tab_bar.background" = "#16161600"; # Tab bar
      "status_bar.background" = "#161616${alphaHex}"; # Bottom status bar
      "title_bar.background" = "#161616${alphaHex}"; # Top menu bar (File, Edit, View, etc.)
      "title_bar.inactive_background" = "#161616${alphaHex}"; # Title bar when window inactive
    };
  };

  # Waybar CSS styling
  waybar = {
    css =
      let
        c = colors;
      in
      ''
        * {
          font-family: "JetBrainsMono Nerd Font", monospace;
          font-size: 13px;
          border: none;
          border-radius: 0;
        }

        window#waybar {
          background-color: ${c.bgRgba};
          color: ${c.fg};
        }

        #workspaces button {
          padding: 4px 12px;
          margin: 0;
          color: ${c.fgAlt};
          background-color: transparent;
          transition: all 0.3s ease;
          font-size: 14px;
          font-weight: 500;
          min-width: 30px;
        }

        #workspaces button * {
          background-color: transparent;
        }

        #workspaces button.active {
          color: ${c.accent};
          background-color: ${c.accentRgba};
          border-bottom: 2px solid ${c.accent};
        }

        #workspaces button.active * {
          background-color: transparent;
        }

        #workspaces button:hover {
          background-color: ${c.hover};
          color: ${c.fg};
        }

        #clock, #battery, #network, #pulseaudio {
          padding: 0 12px;
          margin: 0 2px;
          color: ${c.fg};
        }

        #clock {
          color: ${c.accent};
          font-weight: bold;
        }

        #battery {
          color: ${c.success};
        }

        #battery.charging {
          color: ${c.accent};
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
          color: ${c.info};
        }

        #network.disconnected {
          color: ${c.error};
        }

        #pulseaudio {
          color: ${c.warning};
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
    # GTK3 CSS
    gtk3Css =
      let
        c = colors;
      in
      ''
        /* Carbonfox theme color overrides for GTK3 */

        /* Standard GTK3 color names */
        @define-color bg_color ${c.bg};
        @define-color fg_color ${c.fg};
        @define-color base_color ${c.bgAlt};
        @define-color text_color ${c.fg};
        @define-color selected_bg_color ${c.accent};
        @define-color selected_fg_color ${c.fg};
        @define-color tooltip_bg_color ${c.bgAlt};
        @define-color tooltip_fg_color ${c.fg};

        /* Theme variants (for compatibility with different theme conventions) */
        @define-color theme_bg_color ${c.bg};
        @define-color theme_fg_color ${c.fg};
        @define-color theme_base_color ${c.bgAlt};
        @define-color theme_text_color ${c.fg};
        @define-color theme_selected_bg_color ${c.accent};
        @define-color theme_selected_fg_color ${c.fg};
        @define-color borders ${c.border};
        @define-color unfocused_borders ${c.border};

        /* Semantic colors */
        @define-color success_color ${c.success};
        @define-color warning_color ${c.warning};
        @define-color error_color ${c.error};
        @define-color link_color ${c.accent};
        @define-color error_color_backdrop ${c.error};
        @define-color success_color_backdrop ${c.success};
        @define-color warning_color_backdrop ${c.warning};

        /* Content/view colors */
        @define-color content_view_bg ${c.bgAlt};
        @define-color theme_unfocused_bg_color ${c.bg};
        @define-color theme_unfocused_fg_color ${c.fg};

        /* Apply default colors to everything */
        * {
          background-color: @bg_color;
          color: @fg_color;
          border-color: @borders;
        }

        /* Exceptions - things that should differ from default */

        /* Buttons - slightly lighter background */
        button {
          background-color: shade(@bg_color, 1.1);
        }

        button:hover {
          background-color: shade(@bg_color, 1.2);
        }

        button:active, button:checked {
          background-color: @selected_bg_color;
          color: @selected_fg_color;
        }

        /* Input fields - use alternate background */
        entry, textview {
          background-color: @base_color;
          color: @text_color;
        }

        /* Selected items - use accent color */
        *:selected {
          background-color: @selected_bg_color;
          color: @selected_fg_color;
        }

        /* Paned separator borders (sidebar, split views) */
        paned > separator {
          background-color: @borders;
          border-color: @borders;
        }
      '';

    # GTK4 CSS
    gtk4Css =
      let
        c = colors;
      in
      ''
        /* Carbonfox theme color overrides for GTK4 */
        @define-color window_bg_color ${c.bg};
        @define-color window_fg_color ${c.fg};
        @define-color view_bg_color ${c.bgAlt};
        @define-color view_fg_color ${c.fg};
        @define-color accent_bg_color ${c.accent};
        @define-color accent_fg_color ${c.bg};
        @define-color headerbar_bg_color ${c.bg};
        @define-color headerbar_fg_color ${c.fg};
        @define-color card_bg_color ${c.bgAlt};
        @define-color card_fg_color ${c.fg};
        @define-color popover_bg_color ${c.bgAlt};
        @define-color popover_fg_color ${c.fg};
        @define-color borders ${c.border};

        /* Semantic colors */
        @define-color success_color ${c.success};
        @define-color warning_color ${c.warning};
        @define-color error_color ${c.error};

        /* Apply border color globally */
        * {
          border-color: @borders;
        }

        /* Paned separator borders (sidebar, split views) */
        paned separator {
          background-color: @borders;
        }
      '';
  };
}
