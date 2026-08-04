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
          # user.signingkey is NOT set here: it is an identity, so it lives in
          # the user aspect (users/tomwrw) next to the key material it comes
          # from. This aspect only decides the signing *policy*.
          gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
        };
      };
    };
}
