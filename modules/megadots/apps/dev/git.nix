_: {
  megadots.apps.dev.git.description =
    "git, configured for SSH commit signing against a caller-supplied key set.";

  megadots.apps.dev.git.homeManager =
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
          # No user.signingkey here. That's an identity, so it lives in
          # users/tomwrw next to the key it comes from. This aspect only sets
          # the signing policy.
          gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
        };
      };
    };
}
