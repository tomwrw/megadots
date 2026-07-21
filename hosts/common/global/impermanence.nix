{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  systemd.services.systemd-machine-id-commit.enable = false;

  system.activationScripts.persistent-dirs.text =
    let
      mkHomePersist =
        user:
        lib.optionalString user.createHome ''
          mkdir -p /persist/${user.home}
          chown ${user.name}:${user.group} /persist/${user.home}
          chmod ${user.homeMode} /persist/${user.home}
          # `just deploy` seeds .ssh key stubs into the persisted home as root
          # via `nixos-anywhere --extra-files`; impermanence then propagates
          # that root ownership into the live ~/.ssh, blocking home-manager
          # (can't write ~/.ssh/config) and ssh (can't read the root-owned
          # private keys). Own the whole .ssh tree for the user. Scoped to
          # .ssh — not `-R` on the home root, which would crawl all the
          # app-state persisted under it.
          if [ -d /persist/${user.home}/.ssh ]; then
            chown -R ${user.name}:${user.group} /persist/${user.home}/.ssh
            chmod 700 /persist/${user.home}/.ssh
          fi
        '';
      users = lib.attrValues config.users.users;
    in
    lib.concatLines (map mkHomePersist users);

  environment.persistence."/persist" = {
    hideMounts = true;
    files = [
      "/etc/machine-id"
    ];
    directories = [
      "/var/lib/nixos"
      "/var/log"
      "/etc/NetworkManager/system-connections"
      "/etc/wireguard"
      "/var/db/sudo/lectured"
      "/var/lib/alsa"
      "/var/lib/systemd"
      "/var/lib/sops-nix"
      "/var/lib/udisks2"
      "/var/lib/upower"
    ];
  };
}
