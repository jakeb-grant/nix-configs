# NixOS Configuration

Multi-host NixOS configuration using flakes and home-manager.

## Structure

```
nix-configs/
├── flake.nix                    # Main entry point
├── flake.lock                   # Lock file (committed)
├── .gitignore
├── README.md
├── init.sh                      # Host initialization script
├── secrets.sh                   # Interactive secret management tool
│
├── hosts/
│   ├── desktop/                 # Desktop configuration
│   │   ├── default.nix
│   │   └── hardware-configuration.nix  # Generated, gitignored
│   └── laptop/                  # Laptop configuration
│       ├── default.nix
│       └── hardware-configuration.nix  # Generated, gitignored
│
├── secrets/                     # Agenix encrypted secrets
│   ├── secrets.nix              # Public keys and secret definitions
│   └── *.age                    # Encrypted secret files (safe to commit)
│
├── wallpapers/                  # Wallpaper images for desktop environments
│   └── *.jpg                    # Used by Hyprpaper and other wallpaper managers
│
└── modules/
    ├── system/
    │   ├── user.nix             # Main user module
    │   ├── user-preferences.nix # Centralized user preferences
    │   ├── core.nix             # Core system configuration
    │   ├── desktop-environment.nix  # Desktop environment selector
    │   ├── agenix-secrets.nix   # Secret declarations for agenix
    │   ├── desktop/
    │   │   ├── base.nix         # Common desktop settings
    │   │   ├── plasma.nix       # KDE Plasma 6 configuration
    │   │   └── hyprland.nix     # Hyprland Wayland compositor
    │   └── hardware/
    │       ├── nvidia.nix       # NVIDIA GPU configuration (desktop)
    │       ├── nvidia-prime.nix # NVIDIA Prime/Optimus (laptop hybrid)
    │       └── amd.nix          # AMD GPU configuration (alternative)
    └── home/
        ├── default.nix          # Home-manager entry point
        ├── desktop/             # Desktop environment configs
        │   ├── common/
        │   │   └── default.nix  # Shared across all DEs (Zed, Ghostty, Firefox)
        │   ├── plasma/
        │   │   └── default.nix  # Plasma-specific packages
        │   └── hyprland/
        │       └── default.nix  # Hyprland config (Waybar, Rofi, etc.)
        └── programs/
            ├── shell.nix        # Bash configuration
            └── git.nix          # Git configuration
```

## Installation

This guide assumes you've already completed a fresh NixOS installation using the **graphical installer**. If you haven't installed NixOS yet, download the ISO from [nixos.org](https://nixos.org/download.html) and run through the graphical installer first.

### Post-Installation Setup

After completing the graphical installation and logging into your new NixOS system:

#### Step 1: Enable Flakes and Install Git

Flakes are experimental and not enabled by default. You'll also need git to clone this repository:

```bash
# Edit the system configuration
sudo nano /etc/nixos/configuration.nix

# Add these lines anywhere in the configuration block:
nix.settings.experimental-features = [ "nix-command" "flakes" ];
environment.systemPackages = with pkgs; [ git ];

# Apply the change
sudo nixos-rebuild switch

# Reboot to ensure flakes are active
sudo reboot
```

**Note on stateVersion:** This configuration uses NixOS 25.05. Both `system.stateVersion` (in `modules/system/core.nix`) and `home.stateVersion` (in `modules/home/default.nix`) are set to `"25.05"`. These should remain in sync. The init.sh script will automatically detect and update both if needed.

#### Step 2: Clone This Repository

After reboot, clone your configuration:

```bash
# Clone to your home directory
cd ~
git clone https://github.com/yourusername/nix-configs
cd nix-configs
```

#### Step 3: Run Initialization Script

Run the automated initialization script to configure everything:

```bash
cd nix-configs
./init.sh
```

The script will:
- Detect your system's stateVersion automatically
- Copy/generate hardware-configuration.nix to the correct host directory
- Optionally update the default values in user-preferences.nix
- Set up git visibility for flake-required files

**What the script asks for:**
- Which host to configure (desktop or laptop)
- Whether to update the default values in user-preferences.nix:
  - Username (defaults to current user)
  - Full name
  - Timezone
  - Desktop environment (Plasma or Hyprland)
  - Git email
  - Git name

**Note:** The script modifies the defaults directly in `modules/system/user-preferences.nix`, not per-host configuration files.

**Alternative: Manual Configuration**

If you prefer to configure manually instead of using the init script:

1. **Copy hardware configuration:**
   ```bash
   # For desktop
   sudo cp /etc/nixos/hardware-configuration.nix ~/nix-configs/hosts/desktop/
   sudo chown $USER: ~/nix-configs/hosts/desktop/hardware-configuration.nix

   # For laptop
   sudo cp /etc/nixos/hardware-configuration.nix ~/nix-configs/hosts/laptop/
   sudo chown $USER: ~/nix-configs/hosts/laptop/hardware-configuration.nix
   ```

2. **Edit user preferences** (`modules/system/user-preferences.nix`):
```nix
userName = lib.mkOption {
  type = lib.types.str;
  default = "jacob";           # Change to your username
  description = "Primary username for the system";
};

fullName = lib.mkOption {
  type = lib.types.str;
  default = "jacob";           # Change to your full name
  description = "Full name/description for the user account";
};

gitEmail = lib.mkOption {
  type = lib.types.str;
  default = "you@example.com"; # Change to your git email
  description = "Email address for git configuration";
};

gitName = lib.mkOption {
  type = lib.types.str;
  default = "jacob";           # Change to your git name
  description = "Name to use for git commits";
};

timezone = lib.mkOption {
  type = lib.types.str;
  default = "America/Denver";  # Change to your timezone
  description = "System timezone";
};

desktopEnvironment = lib.mkOption {
  type = lib.types.enum [ "plasma" "hyprland" ];
  default = "hyprland";        # Set your preference: "plasma" or "hyprland"
  description = "Desktop environment choice";
};
```

3. **Make hardware-configuration.nix visible to flakes:**
```bash
# Add as "intent-to-add" - makes file visible to Nix flakes without committing it
git add -f -N hosts/*/hardware-configuration.nix

# Add to git's local exclude list - prevents accidental commits
echo "hosts/*/hardware-configuration.nix" >> .git/info/exclude
```

**What is "intent-to-add"?** The `-N` flag (`--intent-to-add`) tells git about the file without staging its contents. This makes the file visible to Nix flakes (which need to see all referenced files) while keeping it uncommitted. Hardware configs are machine-specific and shouldn't be in version control.

That's it! All user settings are centralized in `user-preferences.nix` and automatically applied to all hosts.

#### Step 4: Switch to Flake Configuration

Now apply your flake-based configuration:

```bash
cd ~/nix-configs

# For desktop
sudo nixos-rebuild switch --flake .#desktop

# For laptop
sudo nixos-rebuild switch --flake .#laptop
```

This will:
- Create your user account with the specified settings
- Install all packages defined in the configuration
- Set up home-manager with your dotfiles
- Configure git with your name and email
- Install KDE Plasma desktop environment

#### Step 5: Set Your User Password

After the rebuild completes, set your password:

```bash
# Set password for your user account
passwd

# Your shell aliases will be available after reloading your shell
# Test with:
rebuild-desktop  # or rebuild-laptop
```

## Daily Usage

### Update System

```bash
# Update flake inputs
nix flake update

# Rebuild with updates
sudo nixos-rebuild switch --flake .#desktop
```

### Package Management

This configuration follows a clear separation of concerns for package management:

#### Where to Add Packages

**System-Level Packages** (`environment.systemPackages`):
- Required by ALL users (including root)
- Needed in emergency/recovery situations
- Core system functionality
- **Location:** `modules/system/core.nix`
- **Examples:** vim, git, curl, wget, htop

**User CLI Tools** (`home.packages`):
- Terminal-based utilities and development tools
- Used in both GUI and non-GUI environments
- **Location:** `modules/home/default.nix`
- **Examples:** ripgrep, fd, bat, neovim, tmux, btop

**GUI Applications** (`home.packages` in desktop modules):
- Applications that require a desktop environment
- Shared across all desktop environments
- **Location:** `modules/home/desktop/common/default.nix`
- **Examples:** firefox, vscode, discord, gimp

**Desktop-Specific Packages** (`home.packages` in DE modules):
- Tools specific to a particular desktop environment
- **Plasma:** `modules/home/desktop/plasma/default.nix`
- **Hyprland:** `modules/home/desktop/hyprland/default.nix`
- **Examples:** waybar, rofi, kitty (for Hyprland)

#### Decision Tree

```
Does root or the system need this package?
├─ YES → modules/system/core.nix
└─ NO → Is it a GUI application?
    ├─ YES → Does it require a specific DE?
    │   ├─ YES → modules/home/desktop/{plasma,hyprland}/default.nix
    │   └─ NO → modules/home/desktop/common/default.nix
    └─ NO → modules/home/default.nix (CLI tools)
```

#### Examples

**Adding Discord (example - not currently installed):**
```nix
# modules/home/desktop/common/default.nix
home.packages = with pkgs; [
  firefox
  discord  # Add Discord here
];
```

**Adding a terminal tool:**
```nix
# modules/home/default.nix
home.packages = with pkgs; [
  ripgrep
  jq  # Add here
];
```

**Adding a system utility:**
```nix
# modules/system/core.nix
environment.systemPackages = with pkgs; [
  vim
  git
  pciutils  # Add here
];
```

#### Session Variables (Environment Variables)

Environment variables should follow the same separation of concerns as packages:

**System-Level Variables** (`environment.sessionVariables`):
- Hardware/driver configuration (visible to all users including root)
- System infrastructure requirements
- **Location:** Hardware modules (`modules/system/hardware/*.nix`) or DE system modules
- **Examples:** `LIBVA_DRIVER_NAME`, `GBM_BACKEND`, `WLR_NO_HARDWARE_CURSORS`, `NIXOS_OZONE_WL`

**User-Level Variables** (`home.sessionVariables`):
- User preferences and application-specific settings
- Only visible to the specific user
- **Location:** With the related application (preferred) or in `modules/home/default.nix` (for general preferences)
- **Examples:** `EDITOR` (general), `PAGER` (general), `MOZ_ENABLE_WAYLAND` (with Firefox in desktop/common)

**Examples:**

System variable for NVIDIA hardware:
```nix
# modules/system/hardware/nvidia.nix
environment.sessionVariables = {
  LIBVA_DRIVER_NAME = "nvidia";  # All users need this for NVIDIA
};
```

User variable for application config:
```nix
# modules/home/desktop/common/default.nix (with Firefox)
home.sessionVariables = {
  MOZ_ENABLE_WAYLAND = "1";  # Firefox-specific
};
```

User preference:
```nix
# modules/home/default.nix
home.sessionVariables = {
  EDITOR = "zeditor --wait";  # Personal preference
};
```

**Rule of Thumb:**
- **System variables** → Hardware drivers, system infrastructure, affects all users
- **Home variables** → Application configs, user preferences, per-user settings

### Configured Applications

This configuration includes the following pre-configured applications:

**Development Tools:**
- **Zed Editor** - Fast, collaborative code editor with Nix LSP support
  - VSCode keybindings
  - Configured with Svelte and Nix extensions
  - JetBrainsMono Nerd Font integration
  - Location: `modules/home/desktop/common/default.nix`

- **Claude Code** - AI-powered coding assistant via CLI
  - MCP servers configured: Svelte, NixOS
  - Location: `modules/home/default.nix`

**Terminal:**
- **Ghostty** - GPU-accelerated terminal emulator
  - Carbonfox theme with 95% opacity and blur
  - JetBrainsMono Nerd Font
  - Location: `modules/home/desktop/common/default.nix`

**Desktop Environment Specific:**
- **Hyprland**: Waybar, Rofi, Hyprpaper, Mako, Swaylock, Brightnessctl
- **Plasma**: KDE Plasma 6 native applications

### Useful Aliases (after first rebuild)

- `rebuild-desktop` - Rebuild desktop configuration
- `rebuild-laptop` - Rebuild laptop configuration
- `update-flake` - Update flake inputs

## User Preferences

All non-sensitive user configuration is centralized in `modules/system/user-preferences.nix`. This module provides default values that apply to all hosts.

### Available Options

```nix
user-preferences = {
  userName = "jacob";                                      # System username
  fullName = "jacob";                                      # Full name for user account
  timezone = "America/Denver";                             # System timezone
  desktopEnvironment = "hyprland";                         # Set to "plasma" or "hyprland"
  gitEmail = "86214494+jakeb-grant@users.noreply.github.com";  # Git commit email
  gitName = "jacob";                                       # Git commit name
};
```

### How It Works

The `user-preferences` module automatically:
- Creates your user account with the specified settings
- Sets the system timezone
- Configures git with your email and name
- Loads the correct desktop environment modules

### Customizing

**Global defaults** (applies to all hosts):
Edit `modules/system/user-preferences.nix` to change the default values.

**Per-host overrides** (if needed):
You can override specific values in a host's `default.nix`:
```nix
# hosts/laptop/default.nix
user-preferences = {
  enable = true;
  desktopEnvironment = "hyprland";  # Override just for laptop
};
```

## Secret Management

This configuration uses [agenix](https://github.com/ryantm/agenix) for managing sensitive data like API keys, tokens, and passwords.

### Security Model (Hybrid Approach)

**Plaintext (in version control):**
- User preferences (username, email, timezone, etc.)
- Not truly "secret" - visible in commits, logs, etc.
- Stored in `user-preferences.nix`

**Encrypted with Agenix:**
- API keys, tokens, passwords
- WiFi passwords, SSH keys
- Any truly sensitive data
- Encrypted `.age` files safe to commit

### How Agenix Works

1. **Public keys** (in `secrets/secrets.nix`) - Safe to commit
2. **Encrypted secrets** (`secrets/*.age`) - Safe to commit
3. **Private keys** (on machines only) - Never in repo
4. **Decryption** happens at boot using host's private key
5. **Secrets available** at `/run/agenix/<secret-name>`

### Security: Why It's Safe

**If someone clones your repo, they get:**
- ❌ Encrypted `.age` files (can't decrypt without private key)
- ❌ Public keys in `secrets.nix` (can't use for decryption)
- ✅ They need a private key to decrypt (which they don't have)

**To add a new host:**
- Must rekey from a machine that already has access
- Rekeying requires decrypting first (needs existing private key)
- Attacker can't rekey without access

### Managing Secrets

Use the interactive `secrets.sh` tool:

```bash
./secrets.sh
```

**Options:**
1. **List secrets** - View all encrypted secrets
2. **List keys** - Show admin and host keys
3. **Add new secret** - Create encrypted secret (API key, token, etc.)
4. **Remove secret** - Delete a secret
5. **Add new key** - Add admin or host key
6. **Remove key** - Remove a key and rekey
7. **Fresh install** - Guided setup for new hosts

### Adding a Secret

```bash
./secrets.sh
# Choose: 3) Add new secret
# Enter secret name (e.g., "github-token")
# Choose who has access (everyone, admin only, or custom)
# Editor opens - type your secret value
# Save and close - encrypted automatically
```

**Secret file formats:**
- **Single value**: Just the raw secret (e.g., `ghp_abc123xyz`)
- **Key=value pairs**: For environment variables
- **JSON**: For structured data

### Adding a New Host

From a machine that already has access (e.g., laptop with admin key):

```bash
./secrets.sh
# Choose: 7) Fresh install (add host key)
# Enter new host name (e.g., "desktop")
# Paste host's public key from: sudo cat /etc/ssh/ssh_host_ed25519_key.pub
# Secrets automatically rekeyed
# Commit and push
```

On the new host:
```bash
git pull
sudo nixos-rebuild switch --flake .#desktop
# Secrets automatically decrypt to /run/agenix/
```

### Using Secrets in Configuration

Secrets are declared in `modules/system/agenix-secrets.nix`. Here's an example (this configuration currently has no secrets defined):

```nix
age.secrets.github-token = {
  file = ../../secrets/github-token.age;
  mode = "0440";
  owner = "root";
  group = "root";
};
```

**Note:** The above is an example. To add actual secrets, use `./secrets.sh` and then declare them in `modules/system/agenix-secrets.nix`.

Access secrets in your configuration:
```nix
# Secret file path
config.age.secrets.github-token.path  # → /run/agenix/github-token

# Example: Use in a service
services.something = {
  tokenFile = config.age.secrets.github-token.path;
};
```

## Management Tools

### init.sh - Host Initialization

Initialize a new host (copy hardware config, set preferences):

```bash
./init.sh
```

**What it does:**
- Prompts for which host (desktop/laptop)
- Copies or generates `hardware-configuration.nix`
- Optionally updates `user-preferences.nix` defaults
- Sets up git visibility for flake-required files

**When to use:**
- Setting up a new machine
- After running `nixos-generate-config` on a fresh install

### secrets.sh - Secret Management

Interactive tool for managing agenix secrets:

```bash
./secrets.sh
```

**Features:**
- Add/remove secrets
- Add/remove keys (admin and host)
- Fresh install workflow
- Automatic rekeying
- Validates inputs and shows current state

## Customization

### Change Desktop Environment

This configuration uses a modular desktop environment system.

**Method 1: Global Default** (recommended - applies to all hosts):

Edit `modules/system/user-preferences.nix`:

```nix
desktopEnvironment = lib.mkOption {
  type = lib.types.enum [ "plasma" "hyprland" ];
  default = "hyprland";  # Set to your preferred desktop environment
  description = "Desktop environment choice";
};
```

**Method 2: Per-Host Override** (different DE per machine):

Edit your host configuration (`hosts/laptop/default.nix`):

```nix
user-preferences = {
  enable = true;
  desktopEnvironment = "hyprland";  # Override just for this host
};
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .#laptop
```

**Available Options:**
- `"plasma"` - KDE Plasma 6 with SDDM
- `"hyprland"` - Hyprland Wayland compositor

**What Changes Automatically:**
- System loads correct DE modules (conditionally with `mkIf`)
- Home-manager configures DE-specific settings
- Desktop-specific packages installed/removed as needed
- All managed through `user-preferences`

### GPU Configurations

This repository includes GPU configurations in `modules/system/hardware/`:

**NVIDIA (Desktop)** - `nvidia.nix`:
- Proprietary NVIDIA drivers with Wayland/Hyprland support
- Hardware acceleration (OpenGL, Vulkan)
- 32-bit support for gaming
- Used in `hosts/desktop/default.nix`

**NVIDIA Prime (Laptop)** - `nvidia-prime.nix`:
- Hybrid Intel + NVIDIA configuration
- Offload mode: Intel by default, NVIDIA on-demand
- Run apps on NVIDIA: `nvidia-offload <command>`
- Example: `nvidia-offload steam` or `nvidia-offload hyprland`
- Battery-efficient with performance when needed
- Used in `hosts/laptop/default.nix`

**AMD (Alternative)** - `amd.nix`:
- AMD GPU configuration for reference
- Switch by editing your host's `default.nix`

**Customizing GPU settings:**
- To change NVIDIA driver version: Edit `package` in nvidia.nix
- To switch to sync mode (laptop): Enable `prime.sync` in nvidia-prime.nix
- To verify PCI bus IDs: `lspci | grep -E "VGA|3D"`

### Per-Host Customization

Add host-specific configuration in `hosts/{desktop,laptop}/default.nix`.

## Troubleshooting

### Hardware not detected

Make sure `hardware-configuration.nix` exists in your host directory and is generated from the actual machine.

### Permission errors

Ensure you're using `sudo` for `nixos-rebuild` commands.

### Flake errors

Run `nix flake check` to validate your configuration.

### NVIDIA-specific issues

**Black screen after boot:**
- Check that PCI bus IDs are correct in nvidia-prime.nix: `lspci | grep -E "VGA|3D"`
- Try adding `nomodeset` to kernel params temporarily

**Laptop: GPU not switching:**
- Verify offload is working: `nvidia-offload glxinfo | grep "NVIDIA"`
- Check `nvidia-smi` to see if NVIDIA is active

**Wayland/Hyprland cursor issues:**
- Hardware cursors are disabled in Hyprland config via `cursor.no_hardware_cursors = true` (in `modules/home/desktop/hyprland/default.nix`)
- This is configured natively in Hyprland, not as an environment variable
- If issues persist, try adding `WLR_RENDERER=vulkan` as an environment variable

**Poor battery life (laptop):**
- Ensure `powerManagement.finegrained = true` in nvidia-prime.nix
- Verify Intel is being used by default: `glxinfo | grep "OpenGL renderer"`

### Agenix / Secret Management

**Can't decrypt secrets on new host:**
- Verify host key is in `secrets/secrets.nix`
- Check host is in `allHosts` group
- Ensure secrets were rekeyed after adding host
- Verify host key matches: `sudo cat /etc/ssh/ssh_host_ed25519_key.pub`

**Can't edit secrets:**
- Need admin key at `~/.ssh/agenix-admin`
- Or generate new admin key and add to `secrets/secrets.nix`
- Use `secrets.sh` tool which handles keys automatically

**Editor not found (zeditor: command not found):**
- Install Zed CLI: Open Zed → Menu → "Install CLI"
- Or set `EDITOR` to a different editor in `modules/home/default.nix`
- Script falls back to nano/vim if zeditor unavailable

**Secrets not available after rebuild:**
- Check `/run/agenix/` directory exists
- Verify agenix service is running: `systemctl status agenix`
- Check secret is declared in `modules/system/agenix-secrets.nix`
- Look for errors: `journalctl -u agenix`

**Can't rekey secrets:**
- Need a private key that can already decrypt the secrets
- Must use admin key or existing host key
- Run from machine with access: `./secrets.sh` → option 5 or 6

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Wiki](https://nixos.wiki/)
