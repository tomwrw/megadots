{
  inputs,
  lib,
  ...
}:
{
  imports = [
    # Import the required inputs.
    inputs.sops-nix.nixosModules.sops
  ];
  # The host's sops identity is derived from its SSH host key. openssh
  # generates the key on first boot; impermanence-using hosts override
  # the path below in ephemeral-btrfs.nix so initrd activation can read
  # it from /persist before the bind mounts are set up.
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;
    age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.generateKey = false;
  };
}
