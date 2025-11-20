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
cp "$HOST_FILE" "$HOST_FILE.backup"
cp "modules/system/core.nix" "modules/system/core.nix.backup"
cp "modules/home/default.nix" "modules/home/default.nix.backup"

echo -e "${GREEN}Backups created with .backup extension${NC}"

# Update host configuration
echo ""
echo -e "${YELLOW}Updating $HOST_FILE...${NC}"

# Use sed to update the main-user block
sed -i "s/userName = \"user\";/userName = \"$USERNAME\";/" "$HOST_FILE"
sed -i "s/description = \"Main User\";/description = \"$FULLNAME\";/" "$HOST_FILE"
sed -i "s/email = \"your.email@example.com\";/email = \"$EMAIL\";/" "$HOST_FILE"

if [ -n "$GITNAME" ]; then
    sed -i "s/gitName = \"\";/gitName = \"$GITNAME\";/" "$HOST_FILE"
fi

echo -e "${GREEN}✓ Updated $HOST_FILE${NC}"

# Update timezone if provided
if [ -n "$TIMEZONE" ]; then
    echo -e "${YELLOW}Updating timezone in modules/system/core.nix...${NC}"
    sed -i "s|time.timeZone = \"America/Denver\";|time.timeZone = \"$TIMEZONE\";|" "modules/system/core.nix"
    echo -e "${GREEN}✓ Updated timezone to $TIMEZONE${NC}"
fi

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

# Commit changes to git
echo ""
echo -e "${YELLOW}Committing changes to git...${NC}"

# Set temporary git config if not already configured
if ! git config user.name > /dev/null 2>&1; then
    git config user.name "NixOS Setup Script"
fi

if ! git config user.email > /dev/null 2>&1; then
    git config user.email "setup@localhost"
fi

# Add all changes including gitignored files (like hardware-configuration.nix)
git add -f -A

# Commit with descriptive message
COMMIT_MSG="Configure $HOST: $USERNAME ($FULLNAME)

- Set timezone: $TIMEZONE
- Set stateVersion: $STATE_VERSION
- Added hardware-configuration.nix
- Configured user settings"

git commit -m "$COMMIT_MSG" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Changes committed to git${NC}"
else
    echo -e "${YELLOW}⚠ No changes to commit or commit failed${NC}"
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
echo "StateVersion: $STATE_VERSION"
echo ""
echo -e "${GREEN}All changes have been committed to git!${NC}"
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "Run: sudo nixos-rebuild switch --flake .#$HOST"
echo ""
echo -e "${YELLOW}To restore backups if needed:${NC}"
echo "  mv $HOST_FILE.backup $HOST_FILE"
echo "  mv modules/system/core.nix.backup modules/system/core.nix"
echo "  mv modules/home/default.nix.backup modules/home/default.nix"
