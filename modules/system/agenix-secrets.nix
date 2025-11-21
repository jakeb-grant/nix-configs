{ config, lib, ... }:

{
  # Declare all secrets that should be decrypted at boot
  # Secrets are decrypted to /run/agenix/<name> by the agenix service

  # No secrets currently defined - agenix infrastructure ready for future use
  # Example:
  # age.secrets = {
  #   github-token = {
  #     file = ../../secrets/github-token.age;
  #     mode = "0440";
  #     owner = "root";
  #     group = "root";
  #   };
  # };

  # Secrets are available at: config.age.secrets.<name>.path -> /run/agenix/<name>
}
