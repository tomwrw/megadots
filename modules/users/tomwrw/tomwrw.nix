{
  den,
  lib,
  ...
}:
let
  email = "tomwrw@proton.me";
  # One place for my SSH keys, used below both as login credentials
  # (authorizedKeys) and as commit signing identities (allowed_signers). I
  # used to keep those two lists in sync by hand.
  sshKeys = {
    plain = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw";
    sk-primary = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPiQIe8ejl2D9ZLBZCHYyt7Iyh9jFHZ5iMYydq57DnDSAAAACnNzaDp0b213cnc= tomwrw-primary";
    sk-backup = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIG+ODAzUIgoEOgf1+ijqOPCljmYoXn9HETmJ1kP5cuAFAAAACnNzaDp0b213cnc= tomwrw-backup";
  };
in
{
  den.aspects.tomwrw = {

    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
      den.aspects.core.security.sops
      den.aspects.core.security.ssh-agent
      den.aspects.core.syncthing
      den.aspects.desktop.stylix
      den.aspects.apps.browsers.firefox
      den.aspects.apps.dev.git
      den.aspects.apps.shell.zsh
      den.aspects.apps.shell.cli-apps
      den.aspects.apps.terminals.ghostty
      den.aspects.apps.monitoring.btop

      # Applications (common to all hosts).
      den.aspects.apps.messaging.element
      den.aspects.apps.messaging.signal
      den.aspects.apps.messaging.vesktop
      den.aspects.apps.messaging.whatsapp
      den.aspects.apps.storage.ente-desktop
      den.aspects.apps.media.spotify
      den.aspects.apps.productivity.joplin
      den.aspects.apps.productivity.obsidian
      den.aspects.apps.security.ente-auth
      den.aspects.apps.security.bitwarden
      den.aspects.apps.storage.filen-desktop
      den.aspects.apps.dev.claude-code
      den.aspects.apps.dev.vscodium
      den.aspects.apps.productivity.proton-suite
    ];

    nixos = _: {
      sops.secrets."users/tomwrw/password".neededForUsers = true;

      # 'd' fixes ownership and mode even though nixos-anywhere seeded these
      # as root. Both sides are listed on purpose, and dropping either one
      # breaks a different boot:
      #
      # - /persist is where 'just deploy' seeds them. impermanence never
      #   repairs an existing persist directory, it copies that directory's
      #   owner and mode onto the live path, so a root-owned /persist entry
      #   keeps re-infecting my home on every activation.
      #
      # - /home is needed because that copy runs during activation, which here
      #   happens in the initrd, while tmpfiles run at sysinit in stage 2
      #   afterwards. Fix only /persist and the live tree stays wrong for the
      #   whole first boot after a deploy. ~/.ssh is a plain directory, not a
      #   bind mount, so correcting /persist doesn't reach it.
      #
      # Getting this wrong broke home-manager and ssh twice. tmpfiles run at
      # sysinit and home-manager-tomwrw is wantedBy multi-user.target, so the
      # live fixes land first without any explicit ordering.
      systemd.tmpfiles.settings."10-tomwrw-seed" =
        let
          owned = mode: {
            d = {
              user = "tomwrw";
              group = "users";
              inherit mode;
            };
          };
          # Directories only. The seeded files are handled by
          # systemd.services.tomwrw-seeded-keys below.
          entries = prefix: {
            "${prefix}/home/tomwrw" = owned "0700";
            "${prefix}/home/tomwrw/.ssh" = owned "0700";
            "${prefix}/home/tomwrw/.config" = owned "0755";
            "${prefix}/home/tomwrw/.config/sops" = owned "0700";
            "${prefix}/home/tomwrw/.config/sops/age" = owned "0700";
          };
        in
        entries "/persist" // entries "";

      # tmpfiles can own the seeded directories but not the seeded files.
      # systemd-tmpfiles refuses to 'z' a file whose path runs through
      # user-owned directories, which is its protection against symlink
      # attacks, so the rules do nothing and the keys stay root:root 0600.
      # sops-nix then dies with "cannot read keyfile
      # '~/.config/sops/age/keys.txt': permission denied" and takes syncthing
      # with it, since copy-keys needs the decrypted cert. It all looks like a
      # deploy that skipped the keys.
      #
      # So the chown happens from root in a oneshot, not as tmpfiles 'z'
      # entries. I replaced this with 'z' rules once because they were more
      # declarative. They are, and they don't work. Found out on a flatmate
      # deploy.
      #
      # /persist is the side that gets chowned, since it's the source of the
      # bind mount and the live path is the same inode. The globs mirror what
      # 'just deploy' seeds, so keep them in step with that recipe.
      systemd.services.tomwrw-seeded-keys = {
        description = "Own tomwrw's deploy-seeded key files";
        wantedBy = [ "multi-user.target" ];
        before = [ "home-manager-tomwrw.service" ];
        unitConfig.ConditionPathExists = "/persist/home/tomwrw";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        # Globbed and guarded instead of a blanket ignore. A missing key is
        # normal, not every host seeds every key, but a chown that actually
        # fails should still fail the unit.
        script = ''
          shopt -s nullglob
          files=(
            /persist/home/tomwrw/.config/sops/age/keys.txt
            /persist/home/tomwrw/.ssh/id_ed25519*
          )
          if [ ''${#files[@]} -gt 0 ]; then
            chown tomwrw:users "''${files[@]}"
          fi
        '';
      };
    };

    # den's 'user' class puts these straight onto users.users.tomwrw. osConfig
    # is the parent NixOS config, since this module's own 'config' belongs to
    # the user class.
    user =
      { osConfig, ... }:
      {
        hashedPasswordFile = osConfig.sops.secrets."users/tomwrw/password".path;
        openssh.authorizedKeys.keys = lib.attrValues sshKeys;

        extraGroups = [
          "disk"
          "kvm"
          "video"
          "render"
          "audio"
          "input"
        ];
      };

    homeManager =
      { config, ... }:
      {
        systemd.user.startServices = "sd-switch";
        programs.home-manager.enable = true;
        home.sessionPath = [ "$HOME/.local/bin" ];

        # / goes back to a blank snapshot every boot and /home is inside it, so
        # my home keeps only what's listed here or in an app aspect's own
        # home.persistence block.
        #
        # hideMounts is per store. The same option in core/impermanence.nix
        # doesn't cover these, so it needs setting again here. Setting it here
        # covers every aspect's entries, since they all share this store.
        home.persistence."/persist" = {
          hideMounts = true;
          directories = [
            "Documents"
            "Downloads"
            "Pictures"
            "Videos"
            "Music"
          ];
        };

        programs.git.settings.user.name = "tomwrw";
        programs.git.settings.user.email = email;

        # A path to the private key, not the key:: literal this used to be.
        #
        # git only adds -U to 'ssh-keygen -Y sign' for a literal, and -U means
        # "this identity lives in an agent". Nothing here ever puts it in one:
        # core/security/ssh-agent.nix starts an empty agent, and AddKeysToAgent
        # is an ssh(1) option, so it fires on an SSH connection and never on a
        # signature. Every first commit of a fresh login died with "Couldn't
        # find key in agent" until I'd happened to ssh somewhere first.
        #
        # The earlier note here said a path prompts on every signed commit. It
        # only prompts when the agent doesn't already hold the key: ssh-keygen
        # checks the agent for the matching public key before it falls back to
        # reading the file. So this form always completes - silently once the
        # key is loaded, after one passphrase prompt when it isn't - where the
        # literal had no fallback at all and simply failed.
        programs.git.settings.user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519";

        xdg.configFile."git/allowed_signers".text = lib.concatMapStrings (k: "${email} ${k}\n") (
          lib.attrValues sshKeys
        );
      };

    # No host-specific extras here. They come from the roles a host takes,
    # roles/gaming.nix and roles/dev.nix, through provides.to-users. That way
    # this file never names a host, and renaming one can't quietly change what
    # I get.
  };
}
