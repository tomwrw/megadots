{ ... }:
{
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
          # Sign commits with the SSH key (no GPG needed — uses ssh-keygen).
          commit.gpgsign = true;
          gpg.format = "ssh";
          user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
          # user.name / user.email are set in the tomwrw user module.
        };
      };
    };
}
