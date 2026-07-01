_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com" = {
      User = "git";
      IdentitiesOnly = true;
      IdentityFile = [
        "~/.ssh/id_ed25519_sk_primary"
        "~/.ssh/id_ed25519_sk_backup"
      ];
    };
  };

  # FIDO2 sk key handle-stub files (seeded via `just deploy`'s
  # nixos-anywhere --extra-files into /persist/home/<user>/.ssh) plus
  # known_hosts.
  home.persistence."/persist".files = [
    ".ssh/known_hosts"
    ".ssh/id_ed25519_sk_primary"
    ".ssh/id_ed25519_sk_primary.pub"
    ".ssh/id_ed25519_sk_backup"
    ".ssh/id_ed25519_sk_backup.pub"
  ];
}
