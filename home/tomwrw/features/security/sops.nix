{
  inputs,
  config,
  ...
}:
{
  imports = [
    # Import the required inputs.
    inputs.sops-nix.homeManagerModules.sops
  ];
  # HM sops decrypts using a dedicated passphraseless age key at
  # ~/.config/sops/age/keys.txt, placed by `just bootstrap HOST`.
  # We use a separate file (rather than reusing ~/.ssh/id_ed25519)
  # because the SSH key is passphrase-protected and sops-nix has
  # no way to prompt for it during HM activation.
  sops = {
    defaultSopsFile = ../../../../secrets/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    age.generateKey = false;
  };
}
