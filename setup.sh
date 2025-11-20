#!/usr/bin/env bash
# Setup script to configure user settings in NixOS config

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}NixOS User Configuration Setup${NC}"
echo "================================"
echo ""

# Ask which host to configure
echo "Which host are you configuring?"
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

HOST_FILE="hosts/$HOST/default.nix"

if [ ! -f "$HOST_FILE" ]; then
    echo -e "${RED}Error: $HOST_FILE not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Please enter your user information:${NC}"
echo ""

# Collect user information
CURRENT_USER=$(whoami)
read -p "Username [${CURRENT_USER}]: " USERNAME
USERNAME=${USERNAME:-$CURRENT_USER}

read -p "Full Name (e.g., John Doe): " FULLNAME
read -p "Email (e.g., john@example.com): " EMAIL
read -p "Git Name (leave empty to use Full Name): " GITNAME

# Set timezone
echo ""
echo "Common timezones:"
echo "  - America/New_York"
echo "  - America/Chicago"
echo "  - America/Denver"
echo "  - America/Los_Angeles"
echo "  - Europe/London"
echo "  - Europe/Paris"
read -p "Timezone [America/Denver]: " TIMEZONE
TIMEZONE=${TIMEZONE:-America/Denver}

# Choose desktop environment
echo ""
echo "Desktop Environment:"
echo "  1) Plasma (KDE Plasma 6)"
echo "  2) Hyprland (Wayland compositor)"
echo "  3) None (minimal/server)"
read -p "Choose desktop environment [1]: " DE_CHOICE
DE_CHOICE=${DE_CHOICE:-1}

case "$DE_CHOICE" in
    1)
        DESKTOP_ENV="plasma"
        ;;
    2)
        DESKTOP_ENV="hyprland"
        ;;
    3)
        DESKTOP_ENV="none"
        ;;
    *)
        echo -e "${YELLOW}Invalid choice, defaulting to Plasma${NC}"
        DESKTOP_ENV="plasma"
        ;;
esac

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
    read -p "Enter your NixOS stateVersion (e.g., 24.05): " STATE_VERSION
    if [ -z "$STATE_VERSION" ]; then
        echo -e "${RED}Error: stateVersion is required${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Detected stateVersion: $STATE_VERSION${NC}"
fi

# Backup original files
echo ""
echo -e "${YELLOW}Creating backups...${NC}"
if [ -f "$HOST_FILE" ] && [ ! -f "$HOST_FILE.backup" ]; then
    cp "$HOST_FILE" "$HOST_FILE.backup"
fi
if [ -f "modules/system/core.nix" ] && [ ! -f "modules/system/core.nix.backup" ]; then
    cp "modules/system/core.nix" "modules/system/core.nix.backup"
fi
if [ -f "modules/home/default.nix" ] && [ ! -f "modules/home/default.nix.backup" ]; then
    cp "modules/home/default.nix" "modules/home/default.nix.backup"
fi

echo -e "${GREEN}Backups created with .backup extension${NC}"

# Create secrets.nix file
echo ""
echo -e "${YELLOW}Creating secrets.nix...${NC}"
SECRETS_FILE="hosts/$HOST/secrets.nix"

cat > "$SECRETS_FILE" << EOF
# This file contains personal/machine-specific configuration
# It is gitignored and will not be pushed to the repository
{
  personalInfo = {
    userName = "$USERNAME";
    fullName = "$FULLNAME";
    email = "$EMAIL";
    gitName = "$GITNAME";
    timezone = "$TIMEZONE";
  };
  desktopEnvironment = "$DESKTOP_ENV";
}
EOF

echo -e "${GREEN}✓ Created $SECRETS_FILE${NC}"

# Update stateVersion in both system and home-manager configs
echo ""
echo -e "${YELLOW}Updating stateVersion to $STATE_VERSION...${NC}"
sed -i "s|system.stateVersion = \".*\";|system.stateVersion = \"$STATE_VERSION\";|" "modules/system/core.nix"
echo -e "${GREEN}✓ Updated system.stateVersion in modules/system/core.nix${NC}"

sed -i "s|home.stateVersion = \".*\";|home.stateVersion = \"$STATE_VERSION\";|" "modules/home/default.nix"
echo -e "${GREEN}✓ Updated home.stateVersion in modules/home/default.nix${NC}"

# Copy hardware configuration
echo ""
echo -e "${YELLOW}Copying hardware configuration...${NC}"
HARDWARE_SRC="/etc/nixos/hardware-configuration.nix"
HARDWARE_DEST="hosts/$HOST/hardware-configuration.nix"

if [ -f "$HARDWARE_SRC" ]; then
    sudo cp "$HARDWARE_SRC" "$HARDWARE_DEST"
    sudo chown $USER: "$HARDWARE_DEST"
    echo -e "${GREEN}✓ Copied $HARDWARE_SRC to $HARDWARE_DEST${NC}"
else
    echo -e "${RED}⚠ Warning: $HARDWARE_SRC not found${NC}"
    echo -e "${YELLOW}You'll need to generate it with: sudo nixos-generate-config${NC}"
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

# Add machine-specific files to local gitignore (never pushed to remote)
if ! grep -q "hosts/\*/secrets.nix" .git/info/exclude 2>/dev/null; then
    echo "hosts/*/secrets.nix" >> .git/info/exclude
    echo -e "${GREEN}✓ Added secrets.nix to .git/info/exclude${NC}"
fi

if ! grep -q "hosts/\*/hardware-configuration.nix" .git/info/exclude 2>/dev/null; then
    echo "hosts/*/hardware-configuration.nix" >> .git/info/exclude
    echo -e "${GREEN}✓ Added hardware-configuration.nix to .git/info/exclude${NC}"
fi

# Use git add -f -N (intent-to-add) for machine-specific files
# This makes them visible to flakes but prevents them from being committed
git add -f -N "$SECRETS_FILE"
echo -e "${GREEN}✓ Made $SECRETS_FILE visible to flakes (intent-to-add)${NC}"

git add -f -N "$HARDWARE_DEST" 2>/dev/null || true
echo -e "${GREEN}✓ Made $HARDWARE_DEST visible to flakes (intent-to-add)${NC}"

# Add stateVersion changes
git add modules/system/core.nix modules/home/default.nix 2>/dev/null || true

# Commit ONLY the stateVersion changes
# secrets.nix and hardware-configuration.nix are NOT committed (only intent-to-add)
COMMIT_MSG="Setup $HOST configuration

- Set stateVersion: $STATE_VERSION

Note: Machine-specific files (secrets.nix, hardware-configuration.nix) are not committed"

git commit -m "$COMMIT_MSG" > /dev/null 2>&1 || true

if git diff --cached --quiet && git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠ No changes to commit (stateVersion already set)${NC}"
else
    echo -e "${GREEN}✓ Committed setup changes (machine-specific files protected)${NC}"
fi

# Show summary
echo ""
echo -e "${GREEN}Configuration complete!${NC}"
echo "====================="
echo "Host: $HOST"
echo "Username: $USERNAME"
echo "Full Name: $FULLNAME"
echo "Email: $EMAIL"
if [ -n "$GITNAME" ]; then
    echo "Git Name: $GITNAME"
fi
if [ -n "$TIMEZONE" ]; then
    echo "Timezone: $TIMEZONE"
fi
echo "Desktop Environment: $DESKTOP_ENV"
echo "StateVersion: $STATE_VERSION"
echo ""
echo -e "${GREEN}✓ Personal data stored in: $SECRETS_FILE${NC}"
echo -e "${GREEN}✓ This file is protected and will NOT be pushed to GitHub${NC}"
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "Run: sudo nixos-rebuild switch --flake .#$HOST"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo "- secrets.nix and hardware-configuration.nix are visible to flakes (via git add -f -N)"
echo "- You can now add packages and push changes safely"
echo "- Machine-specific files will NEVER be committed or pushed"
echo ""
echo -e "${YELLOW}To restore backups if needed:${NC}"
echo "  mv $HOST_FILE.backup $HOST_FILE"
echo "  mv modules/system/core.nix.backup modules/system/core.nix"
echo "  mv modules/home/default.nix.backup modules/home/default.nix"
