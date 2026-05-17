{ config, ... }:
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
        user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      };
    };
  };
}
