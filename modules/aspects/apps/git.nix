_: {
  # git, configured for SSH commit signing against a caller-supplied key set.
  den.aspects.git.homeManager =
    { config, ... }:
    {
      # Shell aliases for git, next to git's own aliases below. home.shellAliases
      # and not programs.zsh.shellAliases - see the note in apps/shell.nix.
      home.shellAliases = {
        gst = "git status";
        gss = "git status -s";
        gd = "git diff";
        gds = "git diff --staged";
        glog = "git log --oneline --graph --decorate -20";
        gloga = "git log --oneline --graph --decorate --all";
        # stage
        ga = "git add";
        gaa = "git add --all";
        # commit (usage: gc \"message\")
        gc = "git commit -m";
        gca = "git commit -a -m";
        gcane = "git commit --amend --no-edit";
        # push / pull / fetch
        gp = "git push";
        gpu = "git push -u origin HEAD"; # first push of a branch (sets upstream)
        gpf = "git push --force-with-lease"; # safe force, e.g. after an amend
        gl = "git pull";
        glr = "git pull --rebase";
        gf = "git fetch --all --prune";
        # branch / switch
        gsw = "git switch";
        gswc = "git switch -c"; # create + switch to a new branch
        gco = "git checkout";
        gb = "git branch";
        gbd = "git branch -d";
        # stash
        gsta = "git stash";
        gstp = "git stash pop";
      };

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
