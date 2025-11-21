# Agenix Secret Management Transition Plan

## Current State Analysis

### Existing Secret Management
Your current setup uses a bash script (`setup.sh`) that creates per-host `secrets.nix` files containing:
- Personal information (userName, fullName, email, gitName)
- System preferences (timezone, desktopEnvironment)
- These files are gitignored and made visible to flakes via `git add -N` (intent-to-add)

**Limitations of Current Approach:**
1. **No Encryption**: secrets.nix files are plaintext on disk
2. **Machine-Dependent**: Can't easily share configs between machines
3. **No Version Control**: Secret changes aren't tracked in git
4. **Manual Management**: Requires running setup.sh on each machine
5. **Limited Scope**: Only handles user preferences, not true secrets (API keys, passwords, etc.)

### Files That Currently Use Secrets
- `hosts/desktop/default.nix` - Imports and uses secrets.nix
- `hosts/laptop/default.nix` - Imports and uses secrets.nix
- `modules/system/user.nix` - Receives values from secrets
- `modules/home/programs/git.nix` - Uses email and name for git config

---

## Transition Strategy

### Phase 1: Foundation Setup (Non-Breaking)

**Goal**: Add agenix infrastructure without breaking existing setup

#### Step 1.1: Add Agenix to Flake
Add agenix input to `flake.nix`:
```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  agenix.url = "github:ryantm/agenix";  # ADD THIS
};
```

Update outputs to include agenix module and CLI tool:
```nix
outputs = { self, nixpkgs, home-manager, agenix, ... }@inputs: {
  nixosConfigurations = {
    desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/desktop
        home-manager.nixosModules.home-manager
        agenix.nixosModules.default  # ADD THIS
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          environment.systemPackages = [ agenix.packages.x86_64-linux.default ];  # ADD CLI
        }
      ];
    };

    laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/laptop
        home-manager.nixosModules.home-manager
        agenix.nixosModules.default  # ADD THIS
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          environment.systemPackages = [ agenix.packages.x86_64-linux.default ];  # ADD CLI
        }
      ];
    };
  };
};
```

**Validation**: Run `nix flake update` and `sudo nixos-rebuild switch --flake .#<hostname>`

#### Step 1.2: Generate Admin Key
```bash
# Create a dedicated admin key for managing secrets
ssh-keygen -t ed25519 -C "agenix-admin" -f ~/.ssh/agenix-admin

# Back up this key securely!
# Consider storing it in a password manager or encrypted backup
```

**Important**: This key will be able to decrypt ALL secrets. Store the private key securely.

#### Step 1.3: Collect Host SSH Keys
For each host (desktop and laptop):

```bash
# On the target machine, get the host public key
sudo cat /etc/ssh/ssh_host_ed25519_key.pub

# Or remotely via SSH
ssh-keyscan <hostname-or-ip>
```

Save these keys - you'll need them for the next step.

#### Step 1.4: Create Secrets Directory Structure
```bash
mkdir -p secrets
```

#### Step 1.5: Create secrets/secrets.nix
This file defines WHO can access WHAT secrets:

```nix
let
  # Admin key - can decrypt and edit all secrets
  admin = "ssh-ed25519 AAAAC3Nza... agenix-admin";  # Replace with your actual key

  # Host keys - one per machine
  desktop = "ssh-ed25519 AAAAC3Nza... root@desktop";  # From /etc/ssh/ssh_host_ed25519_key.pub
  laptop = "ssh-ed25519 AAAAC3Nza... root@laptop";    # From /etc/ssh/ssh_host_ed25519_key.pub

  # Groups for convenience
  allHosts = [ desktop laptop ];
  everyone = [ admin ] ++ allHosts;
in
{
  # User information secrets (shared across all hosts)
  "user-email.age".publicKeys = everyone;
  "user-fullname.age".publicKeys = everyone;
  "user-gitname.age".publicKeys = everyone;

  # Host-specific secrets
  "desktop-timezone.age".publicKeys = [ admin desktop ];
  "laptop-timezone.age".publicKeys = [ admin laptop ];

  # Desktop environment preferences
  "desktop-de.age".publicKeys = [ admin desktop ];
  "laptop-de.age".publicKeys = [ admin laptop ];

  # Future secrets can go here
  # "github-token.age".publicKeys = everyone;
  # "wifi-password.age".publicKeys = [ admin laptop ];
  # "vpn-config.age".publicKeys = everyone;
}
```

**Note**: The `secrets/secrets.nix` file is ONLY for the agenix CLI - it's NOT imported into your NixOS configuration.

---

### Phase 2: Secret Migration

#### Step 2.1: Create Encrypted Secrets
For each secret, use the agenix CLI to create and encrypt:

```bash
# Navigate to your nix-configs directory
cd /path/to/nix-configs

# Create user email secret
agenix -e secrets/user-email.age -i ~/.ssh/agenix-admin
# (Opens editor - type the email, save, exit)

# Create user fullname secret
agenix -e secrets/user-fullname.age -i ~/.ssh/agenix-admin
# (Type the full name)

# Create user gitname secret
agenix -e secrets/user-gitname.age -i ~/.ssh/agenix-admin
# (Type the git name)

# Create timezone secrets (per-host)
agenix -e secrets/desktop-timezone.age -i ~/.ssh/agenix-admin
# (Type timezone, e.g., America/Denver)

agenix -e secrets/laptop-timezone.age -i ~/.ssh/agenix-admin
# (Type timezone)

# Create desktop environment secrets (per-host)
agenix -e secrets/desktop-de.age -i ~/.ssh/agenix-admin
# (Type "plasma" or "hyprland")

agenix -e secrets/laptop-de.age -i ~/.ssh/agenix-admin
# (Type "plasma" or "hyprland")
```

**Validation**: Verify you can decrypt:
```bash
agenix -d secrets/user-email.age -i ~/.ssh/agenix-admin
```

#### Step 2.2: Add Encrypted Secrets to Git
```bash
git add secrets/
git commit -m "Add agenix encrypted secrets

- User information secrets (email, names)
- Host-specific preferences (timezone, DE)
- Encrypted with agenix using SSH keys"
```

**This is safe**: The .age files are encrypted and can be committed to version control.

---

### Phase 3: Configuration Updates

#### Step 3.1: Create Agenix Secrets Module
Create `modules/system/agenix-secrets.nix`:

```nix
{ config, lib, ... }:

{
  # Declare all secrets that should be decrypted at boot
  age.secrets = {
    user-email = {
      file = ../../secrets/user-email.age;
      mode = "0440";
      owner = "root";
      group = "root";
    };

    user-fullname = {
      file = ../../secrets/user-fullname.age;
      mode = "0440";
      owner = "root";
      group = "root";
    };

    user-gitname = {
      file = ../../secrets/user-gitname.age;
      mode = "0440";
      owner = "root";
      group = "root";
    };
  };

  # Helper function to read secret files
  # Secrets are decrypted to /run/agenix/<name>
  # We'll read them in the host configs
}
```

#### Step 3.2: Update Host Configurations
Modify `hosts/desktop/default.nix`:

```nix
{ config, pkgs, lib, ... }:

let
  # Keep backward compatibility with old secrets.nix during transition
  legacySecrets = if builtins.pathExists ./secrets.nix
    then import ./secrets.nix
    else null;

  # Helper to read agenix secret at evaluation time (if available)
  # Note: This only works AFTER the system has been built once with agenix
  readSecretOr = secretPath: default:
    if builtins.pathExists secretPath
    then lib.strings.removeSuffix "\n" (builtins.readFile secretPath)
    else default;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/user.nix
    ../../modules/system/core.nix
    ../../modules/system/desktop-environment.nix
    ../../modules/system/desktop/base.nix
    ../../modules/home
    ../../modules/system/agenix-secrets.nix  # ADD THIS
  ]
  ++ (
    # Use agenix secrets if available, fall back to legacy
    let
      desktopEnv = if legacySecrets != null
        then (legacySecrets.desktopEnvironment or "plasma")
        else readSecretOr "/run/agenix/desktop-de" "plasma";
    in
    lib.optionals (desktopEnv == "plasma") [
      ../../modules/system/desktop/plasma.nix
    ]
    ++ lib.optionals (desktopEnv == "hyprland") [
      ../../modules/system/desktop/hyprland.nix
    ]
  )
  ++ [
    ../../modules/system/hardware/nvidia.nix
  ];

  # Declare host-specific secrets
  age.secrets.desktop-timezone = {
    file = ../../secrets/desktop-timezone.age;
    mode = "0440";
  };

  age.secrets.desktop-de = {
    file = ../../secrets/desktop-de.age;
    mode = "0440";
  };

  networking.hostName = "desktop";

  # Timezone configuration
  # Use agenix secret if available, fall back to legacy secrets.nix
  time.timeZone =
    if legacySecrets != null
    then legacySecrets.personalInfo.timezone
    else readSecretOr "/run/agenix/desktop-timezone" "America/Denver";

  # User configuration
  main-user = {
    enable = true;
    userName =
      if legacySecrets != null
      then legacySecrets.personalInfo.userName
      else readSecretOr config.age.secrets.user-email.path "user";
    description =
      if legacySecrets != null
      then legacySecrets.personalInfo.fullName
      else readSecretOr config.age.secrets.user-fullname.path "Main User";
    email =
      if legacySecrets != null
      then legacySecrets.personalInfo.email
      else readSecretOr config.age.secrets.user-email.path "user@example.com";
    gitName =
      if legacySecrets != null
      then legacySecrets.personalInfo.gitName
      else readSecretOr config.age.secrets.user-gitname.path "";
  };

  # Desktop environment
  desktop-environment = {
    enable = true;
    de = if legacySecrets != null
      then legacySecrets.desktopEnvironment or "plasma"
      else readSecretOr "/run/agenix/desktop-de" "plasma";
  };
}
```

**Note**: There's a chicken-and-egg problem here - secrets need to exist at evaluation time, but they're only decrypted after build. We'll address this with a better approach in Step 3.3.

#### Step 3.3: Better Approach - Use String Literals
Instead of reading at eval time, store secret REFERENCES and use activation scripts:

Update `modules/system/user.nix` to accept secret paths:

```nix
{ lib, config, pkgs, ... }:

let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable = lib.mkEnableOption "enable user module";

    userName = lib.mkOption {
      default = "mainuser";
      description = "Username for the main user account";
      type = lib.types.str;
    };

    # ... other options ...

    # ADD OPTIONS FOR SECRET PATHS
    emailSecretPath = lib.mkOption {
      default = null;
      description = "Path to encrypted email secret (agenix)";
      type = lib.types.nullOr lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      description = cfg.description;
      shell = cfg.shell;
      extraGroups = cfg.extraGroups;
    };
  };
}
```

**Better Solution**: Since username is needed at evaluation time, keep using plaintext config options for non-sensitive data, and use agenix only for truly sensitive secrets.

#### Step 3.4: Revised Approach - Hybrid Strategy

**Key Insight**: Not all data in secrets.nix is actually "secret":
- **Non-sensitive** (can be in plaintext config): userName, fullName, gitName, timezone, desktopEnvironment
- **Actually sensitive** (use agenix): passwords, API tokens, SSH keys, email (arguably)

**Recommendation**:
1. Move non-sensitive user preferences to a proper NixOS module option
2. Use agenix ONLY for truly sensitive data
3. This simplifies the transition and avoids evaluation-time issues

Create `modules/system/user-preferences.nix`:

```nix
{ lib, config, ... }:

let
  cfg = config.user-preferences;
in
{
  options.user-preferences = {
    enable = lib.mkEnableOption "user preferences module";

    userName = lib.mkOption {
      default = "user";
      type = lib.types.str;
      description = "Primary username";
    };

    fullName = lib.mkOption {
      default = "Main User";
      type = lib.types.str;
      description = "Full name for user account";
    };

    timezone = lib.mkOption {
      default = "America/Denver";
      type = lib.types.str;
      description = "System timezone";
    };

    desktopEnvironment = lib.mkOption {
      default = "plasma";
      type = lib.types.enum [ "plasma" "hyprland" ];
      description = "Desktop environment choice";
    };

    # Sensitive data - paths to agenix secrets
    emailSecretPath = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.path;
      description = "Path to encrypted email secret";
    };

    gitNameSecretPath = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.path;
      description = "Path to encrypted git name secret";
    };
  };

  config = lib.mkIf cfg.enable {
    # Apply preferences
    time.timeZone = cfg.timezone;

    main-user = {
      enable = true;
      userName = cfg.userName;
      description = cfg.fullName;
      # Email and gitName would reference secrets
    };

    desktop-environment = {
      enable = true;
      de = cfg.desktopEnvironment;
    };
  };
}
```

---

### Phase 4: Testing & Validation

#### Step 4.1: Test on One Host First
1. Implement changes on desktop first
2. Build and switch: `sudo nixos-rebuild switch --flake .#desktop`
3. Verify secrets are decrypted: `ls -la /run/agenix/`
4. Verify services using secrets work correctly
5. Test git configuration: `git config --global --list`

#### Step 4.2: Smoke Tests
```bash
# Check secret files exist
ls -la /run/agenix/

# Check secret permissions
stat /run/agenix/user-email

# Verify secret contents (as root)
sudo cat /run/agenix/user-email

# Check user configuration
id $(whoami)
echo $USER
```

#### Step 4.3: Rollback Plan
If anything breaks:

```bash
# Revert to previous generation
sudo nixos-rebuild switch --rollback

# Or manually restore backups
mv hosts/desktop/default.nix.backup hosts/desktop/default.nix
```

Keep the legacy `secrets.nix` files until fully validated!

---

### Phase 5: Cleanup & Documentation

#### Step 5.1: Remove Legacy Setup Script
Once fully migrated and tested:
```bash
# Optional: Keep for reference or remove
mv setup.sh setup.sh.legacy
```

#### Step 5.2: Update Documentation
Create `README-SECRETS.md`:

```markdown
# Secret Management with Agenix

This repository uses agenix for encrypted secret management.

## First-Time Setup

1. Get the admin SSH key from your password manager
2. Place it at `~/.ssh/agenix-admin`
3. Build the system: `sudo nixos-rebuild switch --flake .#<hostname>`
4. Secrets will be automatically decrypted to `/run/agenix/`

## Adding a New Secret

1. Add entry to `secrets/secrets.nix`
2. Create the secret: `agenix -e secrets/new-secret.age -i ~/.ssh/agenix-admin`
3. Declare in configuration: `age.secrets.new-secret.file = ...`
4. Reference in config: `config.age.secrets.new-secret.path`
5. Commit the .age file: `git add secrets/ && git commit`

## Adding a New Host

1. Get host SSH key: `ssh-keyscan hostname`
2. Add to `secrets/secrets.nix`
3. Rekey secrets: `agenix --rekey -i ~/.ssh/agenix-admin`
4. Commit changes

## Common Issues

See `agenix-quickstart.md` for troubleshooting.
```

#### Step 5.3: Git Cleanup
```bash
# Update .gitignore to include legacy files
echo "setup.sh.legacy" >> .gitignore
echo "*.backup" >> .gitignore

# Remove legacy secrets from exclude
# Edit .git/info/exclude manually
```

---

## Migration Checklist

### Pre-Migration
- [ ] Read agenix documentation (`agenix-quickstart.md`)
- [ ] Backup current configuration
- [ ] Document current secrets.nix values
- [ ] Test current setup works

### Phase 1: Foundation
- [ ] Add agenix to flake.nix
- [ ] Update flake.lock: `nix flake update`
- [ ] Generate admin SSH key
- [ ] Collect host SSH keys from all machines
- [ ] Create `secrets/` directory
- [ ] Create `secrets/secrets.nix` with key mappings
- [ ] Test agenix CLI: `nix run github:ryantm/agenix`

### Phase 2: Secret Creation
- [ ] Create user-email.age
- [ ] Create user-fullname.age
- [ ] Create user-gitname.age
- [ ] Create timezone secrets (per-host)
- [ ] Create desktop-de secrets (per-host)
- [ ] Verify decryption works
- [ ] Commit encrypted secrets to git

### Phase 3: Configuration
- [ ] Create `modules/system/user-preferences.nix` (optional)
- [ ] Update `hosts/desktop/default.nix`
- [ ] Update `hosts/laptop/default.nix`
- [ ] Update flake to include agenix module
- [ ] Add agenix CLI to systemPackages

### Phase 4: Testing
- [ ] Build on desktop: `nixos-rebuild switch --flake .#desktop`
- [ ] Verify secrets decrypted: `ls /run/agenix/`
- [ ] Test git config
- [ ] Test user account
- [ ] Build on laptop: `nixos-rebuild switch --flake .#laptop`
- [ ] Verify laptop secrets
- [ ] Test both systems for 1 week

### Phase 5: Cleanup
- [ ] Remove legacy secrets.nix files
- [ ] Archive setup.sh script
- [ ] Update documentation
- [ ] Clean up .gitignore
- [ ] Create README-SECRETS.md

### Post-Migration
- [ ] Back up admin SSH key securely
- [ ] Document secret locations for team
- [ ] Plan for future secrets (API keys, etc.)

---

## Future Enhancements

Once agenix is established, consider adding:

### System Secrets
```bash
# WiFi passwords
agenix -e secrets/wifi-password.age

# VPN configurations
agenix -e secrets/vpn-config.age

# Tailscale auth keys
agenix -e secrets/tailscale-auth.age
```

### User Secrets (Home Manager)
```bash
# GitHub tokens
agenix -e secrets/github-token.age

# SSH private keys
agenix -e secrets/ssh-private-key.age

# API keys for development
agenix -e secrets/openai-api-key.age
```

### Service Secrets
```bash
# Database passwords
agenix -e secrets/postgres-password.age

# SMTP credentials
agenix -e secrets/smtp-credentials.age

# Nextcloud admin password
agenix -e secrets/nextcloud-admin-pass.age
```

---

## Security Best Practices

1. **Admin Key**
   - Generate with: `ssh-keygen -t ed25519 -C "agenix-admin"`
   - Store in password manager
   - Back up to encrypted USB drive
   - Never commit private key to git

2. **Host Keys**
   - Automatically generated by NixOS
   - Located at `/etc/ssh/ssh_host_ed25519_key.pub`
   - Can rotate by regenerating and rekeying secrets

3. **Secret Rotation**
   - Periodically update secrets
   - Use `agenix --rekey` after key changes
   - Agenix is not post-quantum safe (as of 2024)

4. **Access Control**
   - Only add public keys that need access
   - Use groups in secrets.nix for clarity
   - Regularly audit who has access

5. **Emergency Recovery**
   - Keep backup of admin key offline
   - Document recovery process
   - Test recovery on non-production system

---

## Comparison: Before vs After

### Before (secrets.nix)
- ❌ Plaintext on disk
- ❌ Not in version control
- ❌ Machine-specific
- ❌ Manual setup required per-host
- ✅ Simple to understand
- ✅ Works without network

### After (agenix)
- ✅ Encrypted at rest
- ✅ Version controlled (encrypted)
- ✅ Shareable across machines
- ✅ Automated decryption
- ✅ Supports SSH keys you already have
- ✅ Easy to rotate secrets
- ⚠️  Slightly more complex
- ⚠️  Requires host SSH keys

---

## Timeline Estimate

- **Phase 1** (Foundation): 1-2 hours
- **Phase 2** (Migration): 1 hour
- **Phase 3** (Configuration): 2-3 hours
- **Phase 4** (Testing): 1 week (ongoing validation)
- **Phase 5** (Cleanup): 1 hour

**Total active work**: ~5-7 hours
**Total elapsed time**: ~1-2 weeks (including testing period)

---

## Questions to Consider

1. **Do you need truly encrypted secrets NOW?**
   - If yes: Full migration to agenix
   - If no: Hybrid approach (agenix for future secrets only)

2. **Single user or multi-user?**
   - Single: One admin key is sufficient
   - Multi: Consider per-user keys for audit trail

3. **How many hosts?**
   - Few hosts (2-3): Simple key management
   - Many hosts: Consider grouping strategies

4. **What secrets do you need beyond user info?**
   - Plan ahead for GitHub tokens, WiFi passwords, etc.
   - Design secrets.nix structure accordingly

5. **Backup strategy?**
   - Where will you store admin key backup?
   - Password manager? Encrypted USB? Both?

---

## Recommended Approach

Given your current setup with just 2 hosts (desktop + laptop) and simple requirements:

**Option A: Full Migration** (Recommended for learning)
- Fully embrace agenix
- Migrate all sensitive data
- Remove legacy setup.sh
- Clean, modern approach

**Option B: Hybrid Approach** (Recommended for pragmatism)
- Keep user preferences in plaintext config
- Use agenix ONLY for truly sensitive secrets (future API keys, passwords)
- Simpler migration path
- Addresses actual security needs

**I recommend Option B** because:
1. User preferences (name, timezone) aren't truly "secret"
2. Simpler configuration (no eval-time complexity)
3. Easier to understand for future you
4. Scales well when you add real secrets later
5. Less likely to break during migration

---

## Next Steps

1. **Review this plan** - Any questions or concerns?
2. **Choose approach** - Option A (full) or Option B (hybrid)?
3. **Set aside time** - Block 5-7 hours for implementation
4. **Backup current system** - Create a full backup before starting
5. **Start with Phase 1** - Add agenix to flake and test CLI

Would you like me to proceed with implementation? If so, which approach do you prefer?
