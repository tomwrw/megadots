_: {
  den.aspects.apps.dev.git.homeManager =
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
          commit.gpgsign = true;
          gpg.format = "ssh";
          user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519";
          gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
        };
      };
    };
}
