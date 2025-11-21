let
  # Admin key - can decrypt and edit all secrets
  admin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGg3D8Zb+asQJhtzSAcwH1WXeNsoyXObi/lADdMUcNaw agenix-admin";

  # Host keys - one per machine
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFUZlNu9FD/QlmVhtkVV0uuTu6uQR32vbZ5C7LZsxbwc root@laptop";
  # desktop = "ssh-ed25519 AAAAC3Nza... root@desktop";  # Add when desktop is configured

  # Groups for convenience
  allHosts = [ laptop ];  # Add desktop here when ready
  everyone = [ admin ] ++ allHosts;
in
{
  # Agenix infrastructure is ready for truly sensitive secrets
  # Email and gitName are in user-preferences.nix (not sensitive enough for encryption)

  # Add secrets here as needed:
  # "github-token.age".publicKeys = everyone;
  # "ssh-private-key.age".publicKeys = everyone;
  # "api-keys.age".publicKeys = everyone;
  # "wifi-password.age".publicKeys = everyone;
}
