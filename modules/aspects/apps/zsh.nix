_: {
  den.aspects.apps.shell.zsh =
    { host, ... }:
    {
      homeManager =
        { config, ... }:
        {
          # Shell integration is on by default via
          # home.shell.enableShellIntegration, so it is not restated here.
          programs.fzf.enable = true;

          programs.zsh = {
            # programs.zsh.enable is not set here: den.batteries.user-shell
            # "zsh" (see users/tomwrw) already enables it at both the NixOS and
            # Home Manager level. Setting it again just hides where it comes
            # from.
            dotDir = "${config.xdg.configHome}/zsh";
            autosuggestion.enable = true;
            enableCompletion = true;
            shellAliases = {
              nix-r = "nixos-rebuild switch --flake .#${host.name} --sudo";
              nix-b = "nixos-rebuild build --flake .#${host.name} --sudo";
              nix-clean = "nix-collect-garbage -d --delete-old && sudo nix-collect-garbage -d --delete-old";
              hstat = "curl -o /dev/null --silent --head --write-out '%{http_code}\n' $1";
              # ls/l/la come from programs.eza (apps/cli-apps.nix) - eza was
              # installed but never actually used while these aliased coreutils.
              psf = "ps -aux | grep";
              lsf = "ls | grep";
              nsp = "nix search nixpkgs";
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
            history = {
              # Same path as before, expressed through xdg.dataHome to match
              # dotDir above. Filename keeps its leading dot deliberately -
              # renaming it would orphan the existing history file.
              path = "${config.xdg.dataHome}/zsh/.zsh_history";
              size = 8000;
            };
          };

          programs.starship = {
            enable = true;
            settings = {
              add_newline = false;
              directory = {
                truncation_length = 2;
                format = "[$path]($style)[$read_only]($read_only_style) ";
              };
              git_commit.disabled = false;
              hostname = {
                ssh_only = false;
                format = "[$hostname]($style) ";
              };
              username.show_always = true;
            };
          };
        };
    };
}
