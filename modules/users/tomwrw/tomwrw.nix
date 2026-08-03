{
  den,
  ...
}:
{
  den.aspects.tomwrw = {

    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
      den.aspects.sops
      den.aspects.syncthing
      den.aspects.firefox
      den.aspects.git
      den.aspects.zsh
      den.aspects.ghostty
      den.aspects.btop
      den.aspects.cli-apps
      den.aspects.stylix

      # Applications (common to all hosts).
      den.aspects.element
      den.aspects.signal
      den.aspects.vesktop
      den.aspects.whatsapp
      den.aspects.ente-desktop
      den.aspects.spotify
      den.aspects.joplin
      den.aspects.obsidian
      den.aspects.ente-auth
      den.aspects.bitwarden
      den.aspects.filen-desktop
      den.aspects.claude-code
      den.aspects.vscodium
      den.aspects.proton-suite
    ];

    nixos =
      {
        config,
        ...
      }:
      {
        users.mutableUsers = false;

        sops.secrets."users/tomwrw/password".neededForUsers = true;

        users.users.tomwrw = {
          hashedPasswordFile = config.sops.secrets."users/tomwrw/password".path;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw"
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPiQIe8ejl2D9ZLBZCHYyt7Iyh9jFHZ5iMYydq57DnDSAAAACnNzaDp0b213cnc= tomwrw-primary"
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIG+ODAzUIgoEOgf1+ijqOPCljmYoXn9HETmJ1kP5cuAFAAAACnNzaDp0b213cnc= tomwrw-backup"
          ];

          extraGroups = [
            "disk"
            "kvm"
            "video"
            "render"
            "audio"
            "input"
          ];
        };

        # `d` fixes ownership/mode even when nixos-anywhere --extra-files
        # already created these as root; `z` does the same for the seeded
        # files themselves and is a no-op if a path is absent (unlike the
        # oneshot chown it replaces, no `|| true` needed). tmpfiles-setup
        # runs at sysinit, well before home-manager-tomwrw.service, so no
        # explicit ordering is needed either.
        systemd.tmpfiles.settings."10-tomwrw-seed" = {
          "/home/tomwrw/.ssh".d = {
            user = "tomwrw";
            group = "users";
            mode = "0700";
          };
          "/home/tomwrw/.config".d = {
            user = "tomwrw";
            group = "users";
            mode = "0755";
          };
          "/home/tomwrw/.config/sops".d = {
            user = "tomwrw";
            group = "users";
            mode = "0700";
          };
          "/home/tomwrw/.config/sops/age".d = {
            user = "tomwrw";
            group = "users";
            mode = "0700";
          };

          # Mode is left alone here — justfile's `install -Dm600/-m644`
          # already sets it; this only adopts ownership.
          "/home/tomwrw/.config/sops/age/keys.txt".z = {
            user = "tomwrw";
            group = "users";
          };
          "/home/tomwrw/.ssh/id_ed25519*".z = {
            user = "tomwrw";
            group = "users";
          };
        };
      };

    homeManager = _: {
      systemd.user.startServices = "sd-switch";
      programs.home-manager.enable = true;
      home.sessionPath = [ "$HOME/.local/bin" ];

      programs.git.settings.user.name = "tomwrw";
      programs.git.settings.user.email = "tomwrw@proton.me";

      xdg.configFile."git/allowed_signers".text = ''
        tomwrw@proton.me sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPiQIe8ejl2D9ZLBZCHYyt7Iyh9jFHZ5iMYydq57DnDSAAAACnNzaDp0b213cnc= tomwrw-primary
        tomwrw@proton.me sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIG+ODAzUIgoEOgf1+ijqOPCljmYoXn9HETmJ1kP5cuAFAAAACnNzaDp0b213cnc= tomwrw-backup
        tomwrw@proton.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw
      '';
    };

    # This is stuff that I want on endgame only and not
    # deployed to all my hosts.
    provides.endgame = {
      includes = [
        den.aspects.gaming
        den.aspects.code-cursor
        den.aspects.gemini
        den.aspects.emulation
        den.aspects.minecraft
      ];
    };
  };
}
