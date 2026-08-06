{
  den,
  lib,
  ...
}:
let
  email = "tomwrw@proton.me";
  # Single source for tomwrw's SSH keys - consumed below both as login
  # credentials (authorizedKeys) and as commit-signing identities
  # (allowed_signers), which previously had to be kept in sync by hand.
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

      # 'd' fixes ownership/mode even when nixos-anywhere --extra-files
      # already created these as root; 'z' does the same for the seeded
      # files themselves and is a no-op if a path is absent (unlike the
      # oneshot chown it replaces, no '|| true' needed).
      #
      # BOTH sides are listed, deliberately, and dropping either one breaks a
      # different boot:
      #
      # - /persist/... is where 'just deploy' seeds these as root, and where
      #   they survive the rollback. impermanence never repairs an existing
      #   persist directory; when one is already there it copies that
      #   directory's owner and mode ONTO the live path
      #   (create-directories.bash, chown/chmod --reference). So an unowned
      #   /persist entry keeps re-infecting the live home on every activation.
      #
      # - /home/... is needed because that copy happens during
      #   system.activationScripts, which on this fleet runs in the INITRD
      #   (initrd-nixos-activation), while tmpfiles run at sysinit in stage 2 -
      #   afterwards. Fixing only /persist therefore leaves the live tree wrong
      #   for the whole of the first boot after a deploy. Note ~/.ssh is a plain
      #   directory, not a bind mount: only the individual files under it are
      #   bind-mounted, so correcting /persist does NOT reach it through a
      #   shared inode.
      #
      # Getting this wrong is what previously broke home-manager (cannot write
      # ~/.ssh/config as uid 1000) and ssh (cannot read root-owned private
      # keys), twice. tmpfiles-setup is part of sysinit.target and
      # home-manager-tomwrw.service is wantedBy multi-user.target, so the live
      # fixes land before home-manager runs with no explicit ordering.
      systemd.tmpfiles.settings."10-tomwrw-seed" =
        let
          owned = mode: {
            d = {
              user = "tomwrw";
              group = "users";
              inherit mode;
            };
          };
          # Mode is left alone - justfile's 'install -Dm600/-m644' already sets
          # it; this only adopts ownership.
          adopted = {
            z = {
              user = "tomwrw";
              group = "users";
            };
          };
          entries = prefix: {
            "${prefix}/home/tomwrw" = owned "0700";
            "${prefix}/home/tomwrw/.ssh" = owned "0700";
            "${prefix}/home/tomwrw/.config" = owned "0755";
            "${prefix}/home/tomwrw/.config/sops" = owned "0700";
            "${prefix}/home/tomwrw/.config/sops/age" = owned "0700";
            "${prefix}/home/tomwrw/.config/sops/age/keys.txt" = adopted;
            "${prefix}/home/tomwrw/.ssh/id_ed25519*" = adopted;
          };
        in
        entries "/persist" // entries "";
    };

    # den's 'user' class forwards these fields directly onto
    # users.users.tomwrw (os-user battery); osConfig is the injected parent
    # NixOS config, since this module's own 'config' is the user-class's.
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

    homeManager = _: {
      systemd.user.startServices = "sd-switch";
      programs.home-manager.enable = true;
      home.sessionPath = [ "$HOME/.local/bin" ];

      # / is rolled back to a blank snapshot on every boot and /home lives
      # inside it, so a home directory keeps only what is listed here or in an
      # app aspect's own home.persistence block.
      #
      # hideMounts is per-STORE: the same option on
      # environment.persistence."/persist" (core/impermanence.nix) does NOT
      # cover these entries, so it has to be set again here. Setting it here
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

      # A literal key, not a path to one. git only passes -U (meaning "this
      # identity is held by an agent") to `ssh-keygen -Y sign` when signingkey
      # is a literal key or key::-prefixed; given a PATH it hands the file
      # straight to ssh-keygen, which does not read ssh_config at all. So with
      # a path, AddKeysToAgent never applies and a passphrase-protected key
      # prompts on every single signed commit, agent or no agent.
      programs.git.settings.user.signingkey = "key::${sshKeys.plain}";

      xdg.configFile."git/allowed_signers".text = lib.concatMapStrings (k: "${email} ${k}\n") (
        lib.attrValues sshKeys
      );
    };

    # Host-specific extras are NOT listed here. They come from the roles a host
    # takes (roles/gaming.nix, roles/dev.nix) via provides.to-users, so this
    # file never mentions a host by name - renaming a host cannot silently
    # change what a user gets.
  };
}
