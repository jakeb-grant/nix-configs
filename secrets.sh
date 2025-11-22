#!/usr/bin/env bash
# Interactive Agenix Secrets Manager
# Manage secrets and keys for your NixOS configuration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SECRETS_DIR="secrets"
SECRETS_NIX="$SECRETS_DIR/secrets.nix"
ADMIN_KEY="$HOME/.ssh/agenix-admin"

# Editor - use $EDITOR from environment, or detect a working editor
if [ -n "$EDITOR" ]; then
    AGENIX_EDITOR="$EDITOR"
elif command -v zeditor &> /dev/null; then
    AGENIX_EDITOR="zeditor --wait"
elif command -v zed &> /dev/null; then
    AGENIX_EDITOR="zed --wait"
elif command -v nano &> /dev/null; then
    AGENIX_EDITOR="nano"
elif command -v vim &> /dev/null; then
    AGENIX_EDITOR="vim"
else
    AGENIX_EDITOR="vi"
fi

# Verify we're in the nix-configs directory
if [ ! -f "flake.nix" ] || [ ! -d "$SECRETS_DIR" ]; then
    echo -e "${RED}Error: This script must be run from the nix-configs directory${NC}"
    exit 1
fi

# Helper function to extract keys from secrets.nix
extract_keys() {
    local key_type=$1
    grep "^  $key_type = " "$SECRETS_NIX" | sed 's/.*= "\(.*\)";.*/\1/' || echo ""
}

# Helper function to extract key comment/name
extract_key_name() {
    local key=$1
    echo "$key" | awk '{print $NF}'
}

# List all secrets
list_secrets() {
    echo -e "${BLUE}Current Secrets:${NC}"
    if [ -n "$(ls -A $SECRETS_DIR/*.age 2>/dev/null)" ]; then
        for secret in $SECRETS_DIR/*.age; do
            basename "$secret"
        done
    else
        echo "  No secrets found"
    fi
    echo ""
}

# List all keys
list_keys() {
    echo -e "${BLUE}=== Current Keys ===${NC}"
    echo ""

    # Extract all key variables from secrets.nix
    echo -e "${GREEN}Admin Keys:${NC}"
    local admin=$(extract_keys "admin")
    if [ -n "$admin" ]; then
        echo "  admin: $(extract_key_name "$admin")"
    else
        echo "  No admin key found"
    fi

    echo ""
    echo -e "${GREEN}Host Keys:${NC}"
    # Find all lines that look like host key definitions (not admin, not groups)
    grep -E "^  [a-z]+ = \"ssh-" "$SECRETS_NIX" | grep -v "admin = " | while read -r line; do
        local var_name=$(echo "$line" | sed 's/^\s*\([a-z]*\) = .*/\1/')
        local key=$(echo "$line" | sed 's/.*= "\(.*\)";.*/\1/')
        local name=$(extract_key_name "$key")
        echo "  $var_name: $name"
    done

    echo ""
}

# Add a new secret
add_secret() {
    echo -e "${BLUE}=== Add New Secret ===${NC}"
    echo ""

    read -p "Secret name (e.g., github-token): " secret_name
    if [ -z "$secret_name" ]; then
        echo -e "${RED}Secret name cannot be empty${NC}"
        return
    fi

    # Add .age extension if not present
    if [[ ! "$secret_name" == *.age ]]; then
        secret_name="${secret_name}.age"
    fi

    # Check if secret already exists
    if [ -f "$SECRETS_DIR/$secret_name" ]; then
        echo -e "${YELLOW}Warning: Secret $secret_name already exists${NC}"
        read -p "Edit existing secret? (y/n): " edit_existing
        if [ "$edit_existing" != "y" ] && [ "$edit_existing" != "Y" ]; then
            return
        fi
    fi

    # Ask who should have access
    echo ""
    echo "Who should have access to this secret?"
    echo "  1) Everyone (admin + all hosts)"
    echo "  2) Admin only"
    echo "  3) Custom (choose specific keys)"
    read -p "Choice [1]: " access_choice
    access_choice=${access_choice:-1}

    local public_keys=""
    case "$access_choice" in
        1) public_keys="everyone" ;;
        2) public_keys="[ admin ]" ;;
        3)
            echo "Available keys:"
            list_keys
            read -p "Enter key names (space-separated, e.g., 'admin laptop desktop'): " key_names
            public_keys="[ $key_names ]"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return
            ;;
    esac

    # Add to secrets.nix if it's a new secret
    if ! grep -q "\"$secret_name\"" "$SECRETS_NIX"; then
        echo ""
        echo -e "${YELLOW}Adding $secret_name to secrets.nix...${NC}"

        # Find the closing brace and insert before it
        sed -i "/^}$/i \\  \"$secret_name\".publicKeys = $public_keys;" "$SECRETS_NIX"
        echo -e "${GREEN}✓ Added to secrets.nix${NC}"
    fi

    # Create/edit the secret
    echo ""
    echo -e "${YELLOW}Opening editor for secret (using $AGENIX_EDITOR)...${NC}"
    cd "$SECRETS_DIR"
    EDITOR="$AGENIX_EDITOR" agenix -e "$secret_name" -i "$ADMIN_KEY"
    cd ..

    echo -e "${GREEN}✓ Secret created/updated${NC}"
}

# Remove a secret
remove_secret() {
    echo -e "${BLUE}=== Remove Secret ===${NC}"
    echo ""

    list_secrets

    read -p "Secret name to remove: " secret_name
    if [ -z "$secret_name" ]; then
        echo -e "${RED}Secret name cannot be empty${NC}"
        return
    fi

    # Add .age extension if not present
    if [[ ! "$secret_name" == *.age ]]; then
        secret_name="${secret_name}.age"
    fi

    if [ ! -f "$SECRETS_DIR/$secret_name" ]; then
        echo -e "${RED}Secret $secret_name not found${NC}"
        return
    fi

    echo -e "${YELLOW}Warning: This will remove $secret_name${NC}"
    read -p "Are you sure? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Cancelled"
        return
    fi

    # Remove from secrets.nix
    sed -i "/\"$secret_name\"/d" "$SECRETS_NIX"

    # Remove the file
    rm "$SECRETS_DIR/$secret_name"

    echo -e "${GREEN}✓ Secret removed${NC}"
}

# Add a new key
add_key() {
    echo -e "${BLUE}=== Add New Key ===${NC}"
    echo ""

    echo "Key type:"
    echo "  1) Admin key (can edit all secrets)"
    echo "  2) Host key (for a specific machine)"
    read -p "Choice [2]: " key_type
    key_type=${key_type:-2}

    read -p "Key variable name (e.g., laptop, desktop): " key_name
    if [ -z "$key_name" ]; then
        echo -e "${RED}Key name cannot be empty${NC}"
        return
    fi

    echo ""
    echo "How to provide the public key:"
    echo "  1) Paste it now"
    echo "  2) Get it from a host via ssh-keyscan"
    echo "  3) Read from a file"
    read -p "Choice [1]: " input_method
    input_method=${input_method:-1}

    local public_key=""
    case "$input_method" in
        1)
            read -p "Paste the public key: " public_key
            ;;
        2)
            read -p "Hostname or IP: " hostname
            public_key=$(ssh-keyscan "$hostname" 2>/dev/null | grep "ssh-ed25519" | head -1)
            if [ -z "$public_key" ]; then
                echo -e "${RED}Could not retrieve key from $hostname${NC}"
                return
            fi
            ;;
        3)
            read -p "Path to public key file: " key_file
            if [ ! -f "$key_file" ]; then
                echo -e "${RED}File not found: $key_file${NC}"
                return
            fi
            public_key=$(cat "$key_file")
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            return
            ;;
    esac

    # Validate it's an SSH key
    if [[ ! "$public_key" =~ ^ssh- ]]; then
        echo -e "${RED}Invalid SSH public key format${NC}"
        return
    fi

    # Add to secrets.nix
    echo ""
    echo -e "${YELLOW}Adding $key_name to secrets.nix...${NC}"

    # Find the 'in' line and insert before it
    local key_line="  $key_name = \"$public_key\";"
    sed -i "/^in$/i $key_line" "$SECRETS_NIX"

    # If it's a host, add to allHosts group
    if [ "$key_type" = "2" ]; then
        # Update allHosts line to include new host
        sed -i "s/allHosts = \[\(.*\)\];/allHosts = [\1 $key_name ];/" "$SECRETS_NIX"
    fi

    echo -e "${GREEN}✓ Key added to secrets.nix${NC}"

    # Rekey all secrets
    echo ""
    read -p "Rekey all secrets to include this key? (y/n): " rekey
    if [ "$rekey" = "y" ] || [ "$rekey" = "Y" ]; then
        echo -e "${YELLOW}Rekeying secrets...${NC}"
        cd "$SECRETS_DIR"
        agenix --rekey -i "$ADMIN_KEY"
        cd ..
        echo -e "${GREEN}✓ Secrets rekeyed${NC}"
    else
        echo -e "${YELLOW}Remember to rekey secrets manually later${NC}"
    fi
}

# Remove a key
remove_key() {
    echo -e "${BLUE}=== Remove Key ===${NC}"
    echo ""

    list_keys

    read -p "Key variable name to remove: " key_name
    if [ -z "$key_name" ]; then
        echo -e "${RED}Key name cannot be empty${NC}"
        return
    fi

    # Check if key exists
    if ! grep -q "^  $key_name = " "$SECRETS_NIX"; then
        echo -e "${RED}Key $key_name not found${NC}"
        return
    fi

    echo -e "${YELLOW}Warning: Removing $key_name${NC}"
    read -p "Are you sure? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Cancelled"
        return
    fi

    # Remove key definition
    sed -i "/^  $key_name = /d" "$SECRETS_NIX"

    # Remove from allHosts if present
    sed -i "s/ $key_name / /g; s/\[ $key_name /[/g; s/ $key_name \]/]/g" "$SECRETS_NIX"

    echo -e "${GREEN}✓ Key removed${NC}"

    # Rekey
    echo ""
    read -p "Rekey all secrets to remove access? (y/n): " rekey
    if [ "$rekey" = "y" ] || [ "$rekey" = "Y" ]; then
        echo -e "${YELLOW}Rekeying secrets...${NC}"
        cd "$SECRETS_DIR"
        agenix --rekey -i "$ADMIN_KEY"
        cd ..
        echo -e "${GREEN}✓ Secrets rekeyed${NC}"
    fi
}

# Fresh install helper
fresh_install() {
    echo -e "${BLUE}=== Fresh Install Setup ===${NC}"
    echo ""
    echo "This will help you add a host key from a new machine"
    echo ""

    read -p "New host name (e.g., laptop, desktop, server): " host_name
    if [ -z "$host_name" ]; then
        echo -e "${RED}Host name cannot be empty${NC}"
        return
    fi

    echo ""
    echo "On the new machine, run:"
    echo -e "${GREEN}  sudo cat /etc/ssh/ssh_host_ed25519_key.pub${NC}"
    echo ""
    echo "Or from this machine (if SSH is set up):"
    echo -e "${GREEN}  ssh-keyscan $host_name${NC}"
    echo ""

    read -p "Paste the host's public key: " public_key
    if [ -z "$public_key" ]; then
        echo -e "${RED}Key cannot be empty${NC}"
        return
    fi

    # Validate it's an SSH key
    if [[ ! "$public_key" =~ ^ssh- ]]; then
        echo -e "${RED}Invalid SSH public key format${NC}"
        return
    fi

    # Add to secrets.nix
    echo ""
    echo -e "${YELLOW}Adding $host_name to secrets.nix...${NC}"

    local key_line="  $host_name = \"$public_key\";"
    sed -i "/^in$/i $key_line" "$SECRETS_NIX"

    # Add to allHosts
    sed -i "s/allHosts = \[\(.*\)\];/allHosts = [\1 $host_name ];/" "$SECRETS_NIX"

    echo -e "${GREEN}✓ Host added${NC}"

    # Rekey
    echo ""
    echo -e "${YELLOW}Rekeying all secrets to include new host...${NC}"
    cd "$SECRETS_DIR"
    agenix --rekey -i "$ADMIN_KEY"
    cd ..
    echo -e "${GREEN}✓ Secrets rekeyed${NC}"

    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo "Don't forget to commit changes:"
    echo -e "${BLUE}  git add secrets/secrets.nix secrets/*.age${NC}"
    echo -e "${BLUE}  git commit -m 'Add $host_name host key'${NC}"
}

# Main menu
show_menu() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Agenix Secrets Manager           ║${NC}"
    echo -e "${GREEN}╔════════════════════════════════════╝${NC}"
    echo ""
    echo "  1) List secrets"
    echo "  2) List keys"
    echo "  3) Add new secret"
    echo "  4) Remove secret"
    echo "  5) Add new key"
    echo "  6) Remove key"
    echo "  7) Fresh install (add host key)"
    echo "  8) Exit"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Choose an option: " choice

    case "$choice" in
        1) list_secrets ;;
        2) list_keys ;;
        3) add_secret ;;
        4) remove_secret ;;
        5) add_key ;;
        6) remove_key ;;
        7) fresh_install ;;
        8)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac

    read -p "Press Enter to continue..."
done
