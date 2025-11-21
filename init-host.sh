#!/usr/bin/env bash
# Host initialization script for NixOS configuration
# Works with user-preferences.nix module (no secrets.nix needed)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verify we're in the nix-configs directory
if [ ! -f "flake.nix" ] || [ ! -d "hosts" ] || [ ! -d "modules" ]; then
    echo -e "${RED}Error: This script must be run from the nix-configs directory${NC}"
    echo "Please cd to your nix-configs directory and try again."
    exit 1
fi

echo -e "${GREEN}NixOS Host Initialization${NC}"
echo "=========================="
echo ""

# Ask which host to configure
echo "Which host are you initializing?"
echo "1) desktop"
echo "2) laptop"
read -p "Enter choice (1 or 2): " host_choice

if [ "$host_choice" = "1" ]; then
    HOST="desktop"
elif [ "$host_choice" = "2" ]; then
    HOST="laptop"
else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

HOST_DIR="hosts/$HOST"

if [ ! -d "$HOST_DIR" ]; then
    echo -e "${RED}Error: $HOST_DIR not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Initializing host: $HOST${NC}"

# Copy hardware configuration
echo ""
echo -e "${YELLOW}Copying hardware configuration...${NC}"
HARDWARE_SRC="/etc/nixos/hardware-configuration.nix"
HARDWARE_DEST="$HOST_DIR/hardware-configuration.nix"

if [ -f "$HARDWARE_SRC" ]; then
    sudo cp "$HARDWARE_SRC" "$HARDWARE_DEST"
    sudo chown $USER: "$HARDWARE_DEST"
    echo -e "${GREEN}✓ Copied $HARDWARE_SRC to $HARDWARE_DEST${NC}"
else
    echo -e "${RED}⚠ Warning: $HARDWARE_SRC not found${NC}"
    echo -e "${YELLOW}You'll need to generate it with: sudo nixos-generate-config${NC}"
    read -p "Would you like to generate it now? (y/n): " generate
    if [ "$generate" = "y" ] || [ "$generate" = "Y" ]; then
        sudo nixos-generate-config --show-hardware-config > "$HARDWARE_DEST"
        sudo chown $USER: "$HARDWARE_DEST"
        echo -e "${GREEN}✓ Generated $HARDWARE_DEST${NC}"
    else
        echo -e "${YELLOW}Skipping hardware configuration. You'll need to create it manually.${NC}"
    fi
fi

# Detect stateVersion from existing system
echo ""
echo -e "${YELLOW}Detecting system stateVersion...${NC}"
STATE_VERSION=""
if [ -f /etc/nixos/configuration.nix ]; then
    STATE_VERSION=$(grep -oP 'system\.stateVersion\s*=\s*"\K[^"]+' /etc/nixos/configuration.nix 2>/dev/null || echo "")
fi

if [ -z "$STATE_VERSION" ]; then
    echo -e "${YELLOW}Could not detect stateVersion from /etc/nixos/configuration.nix${NC}"
    echo "Common versions: 24.05, 24.11, 25.05"
    read -p "Enter your NixOS stateVersion (e.g., 24.05) [skip to leave unchanged]: " STATE_VERSION
fi

if [ -n "$STATE_VERSION" ]; then
    echo ""
    echo -e "${YELLOW}Updating stateVersion to $STATE_VERSION...${NC}"

    # Backup and update system stateVersion
    if [ -f "modules/system/core.nix" ]; then
        if [ ! -f "modules/system/core.nix.backup" ]; then
            cp "modules/system/core.nix" "modules/system/core.nix.backup"
        fi
        sed -i "s|system.stateVersion = \".*\";|system.stateVersion = \"$STATE_VERSION\";|" "modules/system/core.nix"
        echo -e "${GREEN}✓ Updated system.stateVersion in modules/system/core.nix${NC}"
    fi

    # Backup and update home-manager stateVersion
    if [ -f "modules/home/default.nix" ]; then
        if [ ! -f "modules/home/default.nix.backup" ]; then
            cp "modules/home/default.nix" "modules/home/default.nix.backup"
        fi
        sed -i "s|home.stateVersion = \".*\";|home.stateVersion = \"$STATE_VERSION\";|" "modules/home/default.nix"
        echo -e "${GREEN}✓ Updated home.stateVersion in modules/home/default.nix${NC}"
    fi
else
    echo -e "${YELLOW}Skipping stateVersion update${NC}"
fi

# Extract current defaults from user-preferences.nix
echo ""
echo -e "${YELLOW}Reading current defaults from modules/system/user-preferences.nix...${NC}"

PREFS_FILE="modules/system/user-preferences.nix"
if [ ! -f "$PREFS_FILE" ]; then
    echo -e "${RED}Error: $PREFS_FILE not found${NC}"
    exit 1
fi

# Extract defaults using grep (need more context lines to reach the default value)
CURRENT_USERNAME=$(grep -A4 'userName = lib.mkOption' "$PREFS_FILE" | grep 'default =' | sed 's/.*default = "\(.*\)";.*/\1/')
CURRENT_FULLNAME=$(grep -A4 'fullName = lib.mkOption' "$PREFS_FILE" | grep 'default =' | sed 's/.*default = "\(.*\)";.*/\1/')
CURRENT_TIMEZONE=$(grep -A4 'timezone = lib.mkOption' "$PREFS_FILE" | grep 'default =' | sed 's/.*default = "\(.*\)";.*/\1/')
CURRENT_DESKTOP=$(grep -A4 'desktopEnvironment = lib.mkOption' "$PREFS_FILE" | grep 'default =' | sed 's/.*default = "\(.*\)";.*/\1/')
CURRENT_GITEMAIL=$(grep -A4 'gitEmail = lib.mkOption' "$PREFS_FILE" | grep 'default =' | sed 's/.*default = "\(.*\)";.*/\1/')
CURRENT_GITNAME=$(grep -A4 'gitName = lib.mkOption' "$PREFS_FILE" | grep 'default =' | sed 's/.*default = "\(.*\)";.*/\1/')

echo "Current defaults:"
echo "  - userName: $CURRENT_USERNAME"
echo "  - fullName: $CURRENT_FULLNAME"
echo "  - timezone: $CURRENT_TIMEZONE"
echo "  - desktopEnvironment: $CURRENT_DESKTOP"
echo "  - gitEmail: $CURRENT_GITEMAIL"
echo "  - gitName: $CURRENT_GITNAME"
echo ""
read -p "Would you like to update these defaults now? (y/n): " update_prefs

if [ "$update_prefs" = "y" ] || [ "$update_prefs" = "Y" ]; then
    SYSTEM_USER=$(whoami)
    read -p "Username [$SYSTEM_USER] (currently in config: $CURRENT_USERNAME): " USERNAME
    USERNAME=${USERNAME:-$SYSTEM_USER}

    read -p "Full Name [$CURRENT_FULLNAME]: " FULLNAME
    FULLNAME=${FULLNAME:-$CURRENT_FULLNAME}

    echo ""
    echo "Common timezones:"
    echo "  - America/New_York"
    echo "  - America/Chicago"
    echo "  - America/Denver"
    echo "  - America/Los_Angeles"
    read -p "Timezone [$CURRENT_TIMEZONE]: " TIMEZONE
    TIMEZONE=${TIMEZONE:-$CURRENT_TIMEZONE}

    echo ""
    echo "Desktop Environment:"
    echo "  1) Plasma (KDE Plasma 6)"
    echo "  2) Hyprland (Wayland compositor)"
    if [ "$CURRENT_DESKTOP" = "hyprland" ]; then
        read -p "Choose desktop environment [2]: " DE_CHOICE
        DE_CHOICE=${DE_CHOICE:-2}
    else
        read -p "Choose desktop environment [1]: " DE_CHOICE
        DE_CHOICE=${DE_CHOICE:-1}
    fi

    case "$DE_CHOICE" in
        1) DESKTOP_ENV="plasma" ;;
        2) DESKTOP_ENV="hyprland" ;;
        *)
            echo -e "${YELLOW}Invalid choice, defaulting to $CURRENT_DESKTOP${NC}"
            DESKTOP_ENV="$CURRENT_DESKTOP"
            ;;
    esac

    echo ""
    read -p "Git Email [$CURRENT_GITEMAIL]: " GITEMAIL
    GITEMAIL=${GITEMAIL:-$CURRENT_GITEMAIL}

    read -p "Git Name [$CURRENT_GITNAME]: " GITNAME
    GITNAME=${GITNAME:-$CURRENT_GITNAME}

    # Update user-preferences.nix
    echo ""
    echo -e "${YELLOW}Updating modules/system/user-preferences.nix...${NC}"

    if [ ! -f "modules/system/user-preferences.nix.backup" ]; then
        cp "modules/system/user-preferences.nix" "modules/system/user-preferences.nix.backup"
    fi

    # Use current values for replacement to handle any existing defaults
    sed -i "/userName = lib.mkOption/,/};/{s|default = \"$CURRENT_USERNAME\";|default = \"$USERNAME\";|}" modules/system/user-preferences.nix
    sed -i "/fullName = lib.mkOption/,/};/{s|default = \"$CURRENT_FULLNAME\";|default = \"$FULLNAME\";|}" modules/system/user-preferences.nix
    sed -i "/timezone = lib.mkOption/,/default /{s|default = \"$CURRENT_TIMEZONE\";|default = \"$TIMEZONE\";|}" modules/system/user-preferences.nix
    sed -i "/desktopEnvironment = lib.mkOption/,/default /{s|default = \"$CURRENT_DESKTOP\";|default = \"$DESKTOP_ENV\";|}" modules/system/user-preferences.nix
    sed -i "/gitEmail = lib.mkOption/,/};/{s|default = \"$CURRENT_GITEMAIL\";|default = \"$GITEMAIL\";|}" modules/system/user-preferences.nix
    sed -i "/gitName = lib.mkOption/,/};/{s|default = \"$CURRENT_GITNAME\";|default = \"$GITNAME\";|}" modules/system/user-preferences.nix

    echo -e "${GREEN}✓ Updated user-preferences.nix${NC}"
else
    echo -e "${YELLOW}Skipping user preferences update. You can manually edit modules/system/user-preferences.nix${NC}"
fi

# Setup git for flakes
echo ""
echo -e "${YELLOW}Setting up git for flakes...${NC}"

# Set temporary git config if not already configured
if ! git config user.name > /dev/null 2>&1; then
    git config user.name "NixOS Setup Script"
fi

if ! git config user.email > /dev/null 2>&1; then
    git config user.email "setup@localhost"
fi

# Add hardware-configuration.nix to local gitignore
if ! grep -q "hosts/\*/hardware-configuration.nix" .git/info/exclude 2>/dev/null; then
    echo "hosts/*/hardware-configuration.nix" >> .git/info/exclude
    echo -e "${GREEN}✓ Added hardware-configuration.nix to .git/info/exclude${NC}"
fi

# Make hardware-configuration.nix visible to flakes (intent-to-add)
if [ -f "$HARDWARE_DEST" ]; then
    git add -f -N "$HARDWARE_DEST" 2>/dev/null || true
    echo -e "${GREEN}✓ Made $HARDWARE_DEST visible to flakes (intent-to-add)${NC}"
fi

# Optionally commit changes
if [ -n "$STATE_VERSION" ] || [ "$update_prefs" = "y" ] || [ "$update_prefs" = "Y" ]; then
    echo ""
    read -p "Would you like to commit these changes? (y/n): " commit_choice

    if [ "$commit_choice" = "y" ] || [ "$commit_choice" = "Y" ]; then
        git add modules/system/core.nix modules/home/default.nix modules/system/user-preferences.nix 2>/dev/null || true

        COMMIT_MSG="Initialize $HOST configuration"
        if [ -n "$STATE_VERSION" ]; then
            COMMIT_MSG="$COMMIT_MSG

- Set stateVersion: $STATE_VERSION"
        fi
        if [ "$update_prefs" = "y" ] || [ "$update_prefs" = "Y" ]; then
            COMMIT_MSG="$COMMIT_MSG
- Update user preferences in user-preferences.nix"
        fi
        COMMIT_MSG="$COMMIT_MSG

Note: hardware-configuration.nix is not committed (only intent-to-add)"

        git commit -m "$COMMIT_MSG" > /dev/null 2>&1 || echo -e "${YELLOW}⚠ Nothing to commit${NC}"
        echo -e "${GREEN}✓ Changes committed${NC}"
    fi
fi

# Show summary
echo ""
echo -e "${GREEN}Host initialization complete!${NC}"
echo "============================="
echo "Host: $HOST"
if [ -f "$HARDWARE_DEST" ]; then
    echo -e "${GREEN}✓ Hardware configuration copied${NC}"
fi
if [ -n "$STATE_VERSION" ]; then
    echo -e "${GREEN}✓ StateVersion: $STATE_VERSION${NC}"
fi
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "Run: sudo nixos-rebuild switch --flake .#$HOST"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo "- User preferences are configured in modules/system/user-preferences.nix"
echo "- Hardware configuration is visible to flakes but will NOT be committed"
echo "- Email and gitName will be configured via agenix in a future step"
echo ""
