{config, ...}: let
  owner = config.flake.meta.owner;
in {
  flake.modules.homeManager.pc = {config, ...}: {
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
        user = {
          email = owner.email;
          name = owner.name;
          signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
        };
        init.defaultBranch = "main";
        pull.rebase = false;
        commit.gpgsign = true;
        gpg.format = "ssh";
      };
    };
  };
}
