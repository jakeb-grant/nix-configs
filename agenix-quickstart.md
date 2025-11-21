# agenix Quick Start Guide

## What is agenix?

Encrypt secrets (passwords, API keys, etc.) using SSH keys and deploy them securely to NixOS systems.

## Installation (Flakes)

Add to your `flake.nix`:

```nix
{
  inputs.agenix.url = "github:ryantm/agenix";

  outputs = { self, nixpkgs, agenix }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        agenix.nixosModules.default
        {
          environment.systemPackages = [ agenix.packages.x86_64-linux.default ];
        }
      ];
    };
  };
}
```

## Generating Keys

### Create an Admin Key

Generate a dedicated admin key that you'll use across all hosts:

```bash
# Generate a new ed25519 key specifically for agenix
ssh-keygen -t ed25519 -C "agenix-admin" -f ~/.ssh/agenix-admin

# View the public key (you'll need this for secrets.nix)
cat ~/.ssh/agenix-admin.pub
```

**Best practice:** Keep this admin private key secure and backed up. This key can decrypt all your secrets.

### Get System Keys

For each server you want to deploy secrets to:

```bash
# If the server is already running with SSH
ssh-keyscan your-server-hostname-or-ip

# Or from the server itself
cat /etc/ssh/ssh_host_ed25519_key.pub
```

### Get User Keys (Optional)

If you want specific users to be able to decrypt secrets:

```bash
# Your personal key
cat ~/.ssh/id_ed25519.pub

# Another user's key from GitHub
curl https://github.com/username.keys
```

## Quick Setup

### 1. Create secrets directory

```bash
mkdir secrets
cd secrets
```

### 2. Create `secrets.nix`

```nix
let
  # Admin key - can decrypt everything
  admin = "ssh-ed25519 AAAAC3Nza... agenix-admin";
  
  # System keys - one per server
  server1 = "ssh-ed25519 AAAAC3Nza... root@server1";
  server2 = "ssh-ed25519 AAAAC3Nza... root@server2";
  
  # User keys (optional) - for users who need to edit secrets
  alice = "ssh-ed25519 AAAAC3Nza... alice@laptop";
  bob = "ssh-ed25519 AAAAC3Nza... bob@workstation";
  
  # Convenient groups
  admins = [ admin alice ];
  allServers = [ server1 server2 ];
in
{
  # Secret that only server1 needs (admin can still edit it)
  "db-password.age".publicKeys = [ admin server1 ];
  
  # Secret that all servers need
  "api-key.age".publicKeys = admins ++ allServers;
  
  # Secret that multiple admins can edit, only server2 can decrypt
  "ssl-cert.age".publicKeys = admins ++ [ server2 ];
  
  # User-specific secret (e.g., for home-manager)
  "alice-github-token.age".publicKeys = [ admin alice ];
}
```

### 3. Create a secret

```bash
# Use your admin key to create/edit secrets
agenix -e db-password.age -i ~/.ssh/agenix-admin
```

This opens your `$EDITOR`. Type your secret, save, and exit. The file is now encrypted.

### 4. Use the secret in NixOS config

```nix
{
  # Declare the secret
  age.secrets.db-password.file = ./secrets/db-password.age;

  # Use it in your config
  services.postgresql = {
    enable = true;
    # The secret will be decrypted to /run/agenix/db-password
    passwordFile = config.age.secrets.db-password.path;
  };
}
```

### 5. Deploy

```bash
nixos-rebuild switch --flake .
```

## Adding New Keys

### Adding a New Server

1. Get the server's public key:
```bash
ssh-keyscan new-server-ip
```

2. Add it to `secrets.nix`:
```nix
let
  server3 = "ssh-ed25519 AAAAC3Nza... root@server3";
  allServers = [ server1 server2 server3 ];  # Add to group
in
{
  "api-key.age".publicKeys = [ admin ] ++ allServers;
}
```

3. Rekey all secrets (re-encrypts them with the new key):
```bash
agenix --rekey -i ~/.ssh/agenix-admin
```

### Adding a New Admin/User

1. Get their public key:
```bash
# From their machine
cat ~/.ssh/id_ed25519.pub

# Or from GitHub
curl https://github.com/username.keys
```

2. Add to `secrets.nix`:
```nix
let
  charlie = "ssh-ed25519 AAAAC3Nza... charlie@desktop";
  admins = [ admin alice charlie ];  # Add to admins group
```

3. Rekey the secrets they should have access to:
```bash
agenix --rekey -i ~/.ssh/agenix-admin
```

## User-Specific Keys: Should You Care?

### When to Use User Keys

**YES, use user-specific keys when:**

- Multiple people manage your infrastructure (they each need to edit secrets)
- You want developers to encrypt secrets without giving them the admin key
- You use home-manager and want user-level secrets (personal API tokens, etc.)
- You want audit trail of who can decrypt what

**NO, skip user keys when:**

- You're the only admin
- You just want a simple "one admin key" setup
- Your team is small and shares the admin key securely

### User Keys Example: Multiple Admins

```nix
let
  # Each admin has their own key
  alice = "ssh-ed25519 AAAAC3Nza... alice@laptop";
  bob = "ssh-ed25519 AAAAC3Nza... bob@workstation";
  
  # System keys
  server1 = "ssh-ed25519 AAAAC3Nza... root@server1";
in
{
  # Both alice and bob can edit, server1 can decrypt
  "db-password.age".publicKeys = [ alice bob server1 ];
}
```

Now both Alice and Bob can edit secrets using their own private keys:

```bash
# Alice edits (uses her key automatically)
agenix -e db-password.age

# Bob edits (uses his key automatically)
agenix -e db-password.age
```

### User Keys Example: Home-Manager

For user-level secrets (not system-level):

```nix
# In your home-manager config
{
  age = {
    identityPaths = [ "~/.ssh/id_ed25519" ];
    secrets = {
      github-token = {
        file = ../secrets/alice-github-token.age;
      };
    };
  };
  
  # Use the secret
  programs.gh = {
    enable = true;
    tokenFile = config.age.secrets.github-token.path;
  };
}
```

## Common Tasks

**Edit a secret:**
```bash
agenix -e db-password.age -i ~/.ssh/agenix-admin
```

**Create a new secret:**
```bash
agenix -e new-secret.age -i ~/.ssh/agenix-admin
```

**Rekey all secrets (after adding/removing keys):**
```bash
agenix --rekey -i ~/.ssh/agenix-admin
```

**Decrypt to stdout (for debugging):**
```bash
agenix -d db-password.age -i ~/.ssh/agenix-admin
```

**Use a specific editor:**
```bash
EDITOR=vim agenix -e db-password.age -i ~/.ssh/agenix-admin
```

## Key Concepts

- Secrets are encrypted with **public** SSH keys
- Secrets are decrypted using the **private** SSH key on the target system
- Decrypted secrets live in `/run/agenix/` (only at runtime, never in Nix store)
- You can add multiple public keys to each secret
- The `secrets.nix` file is NOT imported into your NixOS config - it's only for the CLI tool
- Anyone with a private key matching one of the public keys can decrypt that secret

## File Structure Example

```
my-nixos-config/
├── flake.nix
├── configuration.nix
└── secrets/
    ├── secrets.nix          # Defines who can access what
    ├── db-password.age      # Encrypted secret
    ├── api-key.age          # Encrypted secret
    └── ssl-cert.age         # Encrypted secret
```

## Security Tips

1. **Backup your admin key securely** - if you lose it, you'll need to regenerate all secrets
2. **Add your admin key to every secret** - so you can always recover/edit
3. **Keep encrypted `.age` files in git** - they're safe to commit
4. **Never commit `secrets.nix` private keys** - only public keys go there
5. **Use different keys for different purposes** - admin key, system keys, user keys
6. **Rotate secrets periodically** - agenix is not post-quantum safe (as of 2024)
7. **Never use `builtins.readFile` on secrets** - always reference `config.age.secrets.<name>.path`

## Troubleshooting

**"no identity matched any of the recipients"**
- You're trying to edit with a private key that doesn't match any public key in `secrets.nix`
- Solution: Use the correct private key with `-i` flag

**"Permission denied"**
- The secret file has wrong permissions or ownership
- Check `age.secrets.<name>.mode`, `.owner`, and `.group` in your config

**Secret not decrypting on server**
- Ensure the server's host key is in `secrets.nix` for that secret
- Check that the private key exists at `/etc/ssh/ssh_host_ed25519_key`
- Verify with: `age -d -i /etc/ssh/ssh_host_ed25519_key /path/to/secret.age`

## Quick Reference

```bash
# Generate admin key
ssh-keygen -t ed25519 -f ~/.ssh/agenix-admin

# Get system key
ssh-keyscan hostname

# Create/edit secret
agenix -e secret.age -i ~/.ssh/agenix-admin

# Rekey after changes
agenix --rekey -i ~/.ssh/agenix-admin

# Decrypt to view
agenix -d secret.age -i ~/.ssh/agenix-admin
```

That's it! You're ready to manage secrets securely with agenix.
