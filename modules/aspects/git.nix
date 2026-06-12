_: {
  den.aspects.git.homeManager =
    { config, ... }:
    {
      programs.git = {
        enable = true;
        lfs.enable = true;
        ignores = [
          "result"
          "*.swp"
          "*.qcow2"
        ];
        settings = {
          alias = {
            s = "status";
            d = "diff";
            a = "add";
            c = "commit";
            p = "push";
            co = "checkout";
          };
          init.defaultBranch = "main";
          pull.rebase = false;
          # Sign commits via SSH (no GPG stack) with the hardware-backed
          # FIDO2 credential — every signature needs touch + PIN. The backup
          # key's pubkey is registered everywhere too, so signing works with
          # either token (point the path at whichever handle is present).
          commit.gpgsign = true;
          gpg.format = "ssh";
          # Path to the PRIVATE handle file: with the .pub here, ssh-keygen
          # delegates to the ssh-agent (which can't do FIDO2 ceremonies);
          # with the private file it performs PIN + touch itself.
          user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_primary";
          # Lets `git log --show-signature` verify locally.
          gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
          # user.name / user.email are set in the tomwrw user module.
        };
      };

      xdg.configFile."git/allowed_signers".text = ''
        tomwrw@proton.me sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPiQIe8ejl2D9ZLBZCHYyt7Iyh9jFHZ5iMYydq57DnDSAAAACnNzaDp0b213cnc= tomwrw-primary
        tomwrw@proton.me sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIG+ODAzUIgoEOgf1+ijqOPCljmYoXn9HETmJ1kP5cuAFAAAACnNzaDp0b213cnc= tomwrw-backup
      '';
    };
}
