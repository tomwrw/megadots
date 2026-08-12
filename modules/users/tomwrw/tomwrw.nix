{
  den,
  megadots,
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
      megadots.core.sops
      megadots.apps.security.ssh
      megadots.apps.sync.syncthing
      megadots.desktop.stylix
      megadots.apps.browsers.firefox
      megadots.apps.dev.git
      megadots.apps.shell.zsh
      megadots.apps.shell.cli-apps
      megadots.apps.terminals.ghostty
      megadots.apps.monitoring.btop

      # Applications (common to all hosts).
      megadots.apps.messaging.element
      megadots.apps.messaging.signal
      megadots.apps.messaging.vesktop
      megadots.apps.messaging.whatsapp
      megadots.apps.storage.ente-desktop
      megadots.apps.media.spotify
      megadots.apps.productivity.joplin
      megadots.apps.productivity.obsidian
      megadots.apps.security.ente-auth
      megadots.apps.security.bitwarden
      megadots.apps.storage.filen-desktop
      megadots.apps.productivity.proton-suite
    ];

    nixos = _: {
      sops.secrets."users/tomwrw/password".neededForUsers = true;

      # GNOME sets the avatar through accountsservice, which copies the image
      # into /var/lib/AccountsService/icons/<user> and records Icon= in
      # users/<user>. Both sit under a path desktop/gnome.nix already persists,
      # but with no Icon= key accountsservice falls back to ~/.face - a bare
      # file in the home root, and only subdirectories of it are persisted. So a
      # picture set in Settings was gone by the next boot.
      #
      # Declaring both ends rather than persisting them. The image can't live in
      # my home either way: gdm draws the login screen as its own user and
      # /home/tomwrw is 0700, so an avatar in there shows up in Settings and
      # nowhere else.
      #
      # 'f+' truncates, so this owns users/tomwrw outright and the other keys
      # accountsservice keeps there - Language, XSession - are rewritten away on
      # every boot instead of merged. Same trade as users.mutableUsers and the
      # VSCodium extension list: what's in this repo is the only source of
      # truth.
      #
      # Real newlines below, not "\n". The tmpfiles module runs the argument
      # through lib.strings.escapeC, so it emits the escapes itself - writing
      # them here gets the backslash escaped a second time and lands a literal
      # \n in the keyfile. nixpkgs warns about exactly that, which is the only
      # reason I know.
      systemd.tmpfiles.settings."10-tomwrw-avatar" = {
        "/var/lib/AccountsService/icons/tomwrw"."L+".argument = "${./avatar.png}";
        "/var/lib/AccountsService/users/tomwrw"."f+" = {
          mode = "0600";
          user = "root";
          group = "root";
          argument = ''
            [User]
            Icon=/var/lib/AccountsService/icons/tomwrw
          '';
        };
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

    # / goes back to a blank snapshot every boot and /home is inside it, so my
    # home keeps only what's listed here or in an app aspect's own home-persist
    # block. hideMounts is set once by the consumer in core/impermanence.nix
    # rather than here, since every aspect's entries share that one store.
    home-persist.directories = [
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

        # The theme choices themselves. desktop/stylix.nix owns the wiring and
        # declares these options; which scheme and which picture are mine.
        megadots.theme = {
          scheme = "rose-pine-moon";
          wallpaper = ../../../assets/wallpaper/snake.png;
        };

        # Stylix needs the vault's absolute path so it can drop a CSS snippet
        # in. Built from homeDirectory rather than written out, so this line
        # carries my note-taking layout but not my username.
        stylix.targets.obsidian.vaultNames = [
          "${config.home.homeDirectory}/Syncthing/02 Area/Notes"
        ];

        programs.git.settings.user.name = "tomwrw";
        programs.git.settings.user.email = email;

        # A path to the private key, not the key:: literal this used to be.
        #
        # git only adds -U to 'ssh-keygen -Y sign' for a literal, and -U means
        # "this identity lives in an agent". Nothing here ever puts it in one:
        # apps/security/ssh.nix starts an empty agent, and AddKeysToAgent
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
