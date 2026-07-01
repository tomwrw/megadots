{ config, pkgs, ... }:
{
  programs = {
    git = {
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
        user = {
          email = "tomwrw@proton.me";
          name = "tomwrw";
        };
        init.defaultBranch = "main";
        pull.rebase = false;
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519_sk_primary";
        gpg.ssh.allowedSignersFile = "${pkgs.writeText "git-allowed-signers" ''
          tomwrw@proton.me sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPiQIe8ejl2D9ZLBZCHYyt7Iyh9jFHZ5iMYydq57DnDSAAAACnNzaDp0b213cnc= tomwrw-primary
          tomwrw@proton.me sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIG+ODAzUIgoEOgf1+ijqOPCljmYoXn9HETmJ1kP5cuAFAAAACnNzaDp0b213cnc= tomwrw-backup
          # Retired 2026-06-12; kept so signatures on older commits still verify.
          tomwrw@proton.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw-legacy
        ''}";
      };
    };
  };
}
