# NixOS Configuration

Multi-host NixOS configuration using flakes and home-manager.

## Structure

```
nix-config/
├── flake.nix                    # Main entry point
├── flake.lock                   # Lock file (committed)
├── .gitignore
├── README.md
│
├── hosts/
│   ├── desktop/                 # Desktop configuration
│   │   ├── default.nix
│   │   └── hardware-configuration.nix  # Generated, gitignored
│   └── laptop/                  # Laptop configuration
│       ├── default.nix
│       └── hardware-configuration.nix  # Generated, gitignored
│
└── modules/
    ├── system/
    │   ├── user.nix             # Main user module (centralized user config)
    │   ├── core.nix             # Core system configuration
    │   ├── desktop.nix          # Desktop environment (KDE Plasma)
    │   └── hardware/
    │       ├── nvidia.nix       # NVIDIA GPU configuration (desktop)
    │       ├── nvidia-prime.nix # NVIDIA Prime/Optimus (laptop hybrid graphics)
    │       └── amd.nix          # AMD GPU configuration (alternative)
    └── home/
        ├── default.nix          # Home-manager entry point
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

#### Step 2: Clone This Repository

After reboot, clone your configuration:

```bash
# Clone to your home directory
cd ~
git clone https://github.com/yourusername/nix-configs
cd nix-configs
```

#### Step 3: Run Setup Script

Run the automated setup script to configure everything:

```bash
cd nix-configs
./setup-user.sh
```

The script will:
- Detect your system's stateVersion automatically
- Ask for your user information (username, full name, email, etc.)
- Copy hardware-configuration.nix to the correct host directory
- Update all configuration files

**What the script asks for:**
- Which host to configure (desktop or laptop)
- Username
- Full name
- Email address
- Git name (optional)
- Timezone

**Alternative: Manual Configuration**

If you prefer to configure manually instead of using the setup script:

1. **Copy hardware configuration:**
   ```bash
   # For desktop
   sudo cp /etc/nixos/hardware-configuration.nix ~/nix-configs/hosts/desktop/

   # For laptop
   sudo cp /etc/nixos/hardware-configuration.nix ~/nix-configs/hosts/laptop/
   ```

2. **Edit your host configuration file** (`hosts/desktop/default.nix` or `hosts/laptop/default.nix`):
```nix
main-user = {
  enable = true;
  userName = "yourname";              # Your actual username
  description = "Your Full Name";     # Your full name
  email = "you@example.com";          # Your email for git
  gitName = "";                       # Optional: git name (uses description if empty)
};
```

**For laptop** (`hosts/laptop/default.nix`):
- Configure the same `main-user` block as above

**Optional customization:**
- `modules/system/core.nix` - Change `time.timeZone` to your timezone (if not using setup script)
- `modules/home/programs/shell.nix` - Update alias paths if you cloned to a different location

That's it! All user settings (username, email, git config) are now centralized in one place.

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

**Adding Discord:**
```nix
# modules/home/desktop/common/default.nix
home.packages = with pkgs; [
  firefox
  vscode
  discord  # Add here
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
  EDITOR = "vim";  # Personal preference
};
```

**Rule of Thumb:**
- **System variables** → Hardware drivers, system infrastructure, affects all users
- **Home variables** → Application configs, user preferences, per-user settings

### Useful Aliases (after first rebuild)

- `rebuild-desktop` - Rebuild desktop configuration
- `rebuild-laptop` - Rebuild laptop configuration
- `update-flake` - Update flake inputs

## Customization

### Change Desktop Environment

This configuration uses a modular desktop environment system with a convenient switcher.

**Quick Method** (recommended):

Edit your host configuration (`hosts/desktop/default.nix` or `hosts/laptop/default.nix`):

```nix
desktop-environment = {
  enable = true;
  de = "plasma";  # Change to "hyprland"
};
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .#desktop
```

**Available Options:**
- `"plasma"` - KDE Plasma 6 with SDDM (default)
- `"hyprland"` - Hyprland Wayland compositor

**What Changes:**
- System configuration automatically loads the correct DE modules
- Home-manager automatically configures DE-specific settings
- Desktop-specific packages are installed/removed as needed

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
- Environment variable `WLR_NO_HARDWARE_CURSORS=1` is already set
- If issues persist, try `WLR_RENDERER=vulkan`

**Poor battery life (laptop):**
- Ensure `powerManagement.finegrained = true` in nvidia-prime.nix
- Verify Intel is being used by default: `glxinfo | grep "OpenGL renderer"`

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Wiki](https://nixos.wiki/)
