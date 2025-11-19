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

## Installation

### Fresh NixOS Installation

**Important:** Flakes are still experimental and NOT enabled by default in NixOS installers. You must enable them explicitly.

#### Recommended Method: Direct Flake Install

Boot from the NixOS installer USB and:

```bash
# 1. Partition your disk (example using UEFI)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# 2. Format partitions
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# 3. Mount partitions
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# 4. Generate hardware configuration
nixos-generate-config --root /mnt

# 5. Clone this repository
git clone https://github.com/yourusername/nix-configs /mnt/etc/nixos/nix-configs
cd /mnt/etc/nixos/nix-configs

# 6. Copy hardware-configuration.nix to your host
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nix-configs/hosts/desktop/

# 7. IMPORTANT: Configure your settings (see Configuration section below)
# Edit username, timezone, git config, etc.

# 8. Install from flake (enable flakes for this command)
nixos-install --flake /mnt/etc/nixos/nix-configs#desktop --extra-experimental-features "nix-command flakes"

# 9. Set root password when prompted, then reboot
reboot
```

#### Alternative: Two-Step Install

If you prefer the traditional approach:

```bash
# 1. Partition, format, and mount as above

# 2. Generate config
nixos-generate-config --root /mnt

# 3. Enable flakes in the temporary config
cat >> /mnt/etc/nixos/configuration.nix << 'EOF'
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
EOF

# 4. Do initial install
nixos-install

# 5. Reboot and login
reboot

# 6. After reboot, clone your config
git clone https://github.com/yourusername/nix-configs
cd nix-configs

# 7. Copy hardware config
sudo cp /etc/nixos/hardware-configuration.nix hosts/desktop/

# 8. Configure your settings (see Configuration section below)

# 9. Switch to flake configuration
sudo nixos-rebuild switch --flake .#desktop
```

### Configuration Before First Build

Before running `nixos-install` or `nixos-rebuild`, edit these files:

**modules/system/core.nix:**
- Change `time.timeZone` to your timezone
- Change `users.users.user` to your actual username
- Update user `description`

**modules/home/default.nix:**
- Change `home-manager.users.user` to match your username

**modules/home/programs/git.nix:**
- Set your `userName`
- Set your `userEmail`

**modules/home/programs/shell.nix:**
- Update alias paths if you cloned to a different location

**For laptop:** Use `hosts/laptop/` instead of `hosts/desktop/` in all commands above.

### Post-Installation

After first boot:

```bash
# Set your user password
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
