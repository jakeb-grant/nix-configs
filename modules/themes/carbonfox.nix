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
in
{
  # Carbonfox theme definition
  # A dark theme with carbon black background and cyan accents

  colors = {
    # Base colors
    bg = "#161616"; # Background (hex)
    bgWithOpacity = "#161616${alphaHex}"; # Background with opacity (calculated)
    bgRgba = "rgba(22, 22, 22, ${toString opacity})"; # Background with opacity (rgba)
    bgAlt = "#0f0f0f"; # Alternate background
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
    borderInactive = "rgba(595959aa)"; # Inactive borders (Hyprland rgba format)
    shadowColor = "rgba(1a1a1aee)"; # Shadow color (Hyprland rgba format)
  };

  # Export opacity value
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
}
