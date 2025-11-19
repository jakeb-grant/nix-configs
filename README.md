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

## Initial Setup

### 1. Fresh NixOS Installation

On a fresh NixOS install:

```bash
# Generate hardware configuration
sudo nixos-generate-config --root /mnt

# Clone this repository
git clone https://github.com/yourusername/nix-configs.git
cd nix-configs

# Copy hardware-configuration.nix to appropriate host
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/desktop/  # or hosts/laptop/
```

### 2. Configure Your Settings

Edit the following files with your personal information:

**modules/system/core.nix:**
- Change `time.timeZone`
- Change `users.users.user` to your username
- Update user description

**modules/home/default.nix:**
- Change `home-manager.users.user` to your username

**modules/home/programs/git.nix:**
- Set your `userName`
- Set your `userEmail`

**modules/home/programs/shell.nix:**
- Update alias paths if you cloned to a different location

### 3. Build and Switch

For desktop:
```bash
sudo nixos-rebuild switch --flake .#desktop
```

For laptop:
```bash
sudo nixos-rebuild switch --flake .#laptop
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
