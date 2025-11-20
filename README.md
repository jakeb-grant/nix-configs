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
    │       └── amd.nix          # AMD GPU configuration
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

#### Step 3: Copy Hardware Configuration

The graphical installer generated a hardware-configuration.nix for your specific machine. Copy it:

```bash
# For desktop
sudo cp /etc/nixos/hardware-configuration.nix ~/nix-configs/hosts/desktop/

# For laptop
sudo cp /etc/nixos/hardware-configuration.nix ~/nix-configs/hosts/laptop/
```

#### Step 4: Configure Your User Settings

**Option 1: Automated Setup (Recommended)**

Run the setup script to configure your user information interactively:

```bash
cd nix-configs
./setup-user.sh
```

The script will ask for:
- Username
- Full name
- Email address
- Git name (optional)
- Timezone

It will automatically update the appropriate configuration files.

**Option 2: Manual Configuration**

Edit your host configuration file directly.

**For desktop** (`hosts/desktop/default.nix`):
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

#### Step 5: Switch to Flake Configuration

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

#### Step 6: Set Your User Password

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

### Add Packages

**System-wide packages:** Edit `modules/system/core.nix`

**User packages:** Edit `modules/home/default.nix`

### Useful Aliases (after first rebuild)

- `rebuild-desktop` - Rebuild desktop configuration
- `rebuild-laptop` - Rebuild laptop configuration
- `update-flake` - Update flake inputs

## Customization

### Change Desktop Environment

Edit `modules/system/desktop.nix`:
- Comment out KDE sections
- Uncomment Hyprland sections

### Add Hardware Configurations

Create new files in `modules/system/hardware/`:
- `nvidia.nix` for NVIDIA GPUs
- `intel.nix` for Intel iGPUs
- `hybrid.nix` for laptop hybrid graphics

Then import them in the appropriate host's `default.nix`.

### Per-Host Customization

Add host-specific configuration in `hosts/{desktop,laptop}/default.nix`.

## Troubleshooting

### Hardware not detected

Make sure `hardware-configuration.nix` exists in your host directory and is generated from the actual machine.

### Permission errors

Ensure you're using `sudo` for `nixos-rebuild` commands.

### Flake errors

Run `nix flake check` to validate your configuration.

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Wiki](https://nixos.wiki/)
