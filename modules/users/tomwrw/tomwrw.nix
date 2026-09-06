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

    # Everything here follows me onto every host. Anything host-specific comes
    # from the roles that host takes, through provides.to-users, so this file
    # never names a machine.
    includes = [
      # The account itself
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")

      # Shell and terminal
      den.aspects.btop
      den.aspects.cli-apps
      den.aspects.direnv
      den.aspects.ghostty
      den.aspects.neovim
      # The parent carries the shell-agnostic aliases, the sub-aspect is the
      # shell that renders them. A provides child does not pull its parent in,
      # so both are listed - as roles/base.nix does for den.aspects.boot.
      den.aspects.shell
      den.aspects.shell.zsh

      # Secrets, keys and sync
      den.aspects.sops
      den.aspects.ssh
      den.aspects.syncthing

      # Desktop and browser
      den.aspects.firefox
      den.aspects.stylix

      # Development
      den.aspects.git

      # Messaging
      den.aspects.element
      den.aspects.signal
      den.aspects.vesktop
      den.aspects.whatsapp

      # Productivity and media
      den.aspects.joplin
      den.aspects.obsidian
      den.aspects.spotify

      # Passwords and storage
      den.aspects.bitwarden
      den.aspects.ente-auth
      den.aspects.ente-desktop
      den.aspects.filen-desktop
      den.aspects.proton-suite
    ];

    # neededForUsers so the hash is on disk before users are created, which is
    # what makes a declarative account with no mutable password work at all.
    #
    # No avatar here. accountsservice writes both the image and its Icon= key
    # under /var/lib/AccountsService, which desktop/gnome.nix persists, so a
    # picture set in Settings survives the rollback on its own.
    nixos = _: {
      sops.secrets."users/tomwrw/password".neededForUsers = true;
    };

    # den's 'user' class puts these straight onto users.users.tomwrw. osConfig
    # is the parent NixOS config, since this module's own 'config' belongs to
    # the user class.
    user =
      { osConfig, ... }:
      {
        # Pinned rather than auto-allocated: .just deploy. chowns the seeded key
        # tree to 1000:100 against an installer that has no account for me, so
        # the number has to be one this config guarantees.
        uid = 1000;

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

    # The taste. aspects/desktop/stylix.nix owns the wiring; this is the only
    # place that says which scheme and which picture. A quirk rather than an
    # option because Stylix themes the host as well as the session, and a NixOS
    # module cannot read a Home Manager option.
    theme = {
      scheme = "rose-pine-moon";
      wallpaper = ../../../assets/wallpaper/snake.png;
    };

    # / goes back to a blank snapshot every boot and /home is inside it, so my
    # home keeps only what is listed here or in an app aspect.s own persist.home
    # block.
    persist.home.directories = [
      "Documents"
      "Downloads"
      "Pictures"
      "Videos"
      "Music"
    ];

    homeManager =
      { config, ... }:
      {
        systemd.user.startServices = "sd-switch";
        programs.home-manager.enable = true;
        home.sessionPath = [ "$HOME/.local/bin" ];

        # Stylix needs the vault.s absolute path to drop a CSS snippet in. Built
        # from homeDirectory so this carries the layout but not the username.
        stylix.targets.obsidian.vaultNames = [
          "${config.home.homeDirectory}/Syncthing/02 Area/Notes"
        ];

        programs.git.settings.user.name = "tomwrw";
        programs.git.settings.user.email = email;

        # A path, not a "key::" literal. git only passes -U to ssh-keygen for a
        # literal, which means "this identity lives in an agent" - and nothing
        # here ever puts it in one, so every first commit of a login failed with
        # "Couldn.t find key in agent". A path falls back to reading the file, so
        # it always completes: silently once the key is loaded, after one
        # passphrase prompt when it is not.
        programs.git.settings.user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519";

        xdg.configFile."git/allowed_signers".text = lib.concatMapStrings (k: "${email} ${k}\n") (
          lib.attrValues sshKeys
        );
      };

    # No host-specific extras here - they come from the roles a host takes,
    # through provides.to-users, so this file never names a machine.
  };
}
