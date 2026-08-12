_: {
  # Not parametric on host, deliberately. This aspect used to open with
  # '{ host, ... }:' so two aliases could say 'nixos-rebuild --flake .#<name>',
  # and den reads a bare function at an aspect path as parametric over scope
  # arguments. In a standalone den.homes there is no host, so den dropped the
  # entire aspect - no error, no warning, just a shell with no fzf, no
  # completion and dotDir silently back at $HOME. Thirty-odd portable aliases
  # were lost to two that weren't.
  #
  # Those two now come from core.nix, which is host scope and can name the
  # machine honestly. Everything left here works anywhere zsh does.
  megadots.apps.shell.zsh = {
    description = "zsh with starship, fzf, completion, history and a portable alias set. Names no host.";

    # Shell history. Everything else here, the zshrc, the aliases, the
    # starship config, gets rewritten on activation, but this is the one
    # thing zsh writes at runtime and .local/share is inside the home that
    # gets rolled back.
    #
    # The directory, NOT the .zsh_history file inside it. impermanence only
    # bind mounts a persisted file once the /persist copy exists; until then
    # it leaves a symlink pointing at it. zsh saves history by writing a temp
    # file and renaming it over the target, which replaces that symlink with
    # a real file, so the history never reaches /persist and the next
    # activation dies with "A file already exists at ...". A directory entry
    # is a real bind mount from the start, so the rename happens inside
    # /persist where it belongs. Home Manager writes nothing else into
    # .local/share/zsh, so nothing else is dragged along with it.
    home-persist.directories = [ ".local/share/zsh" ];

    homeManager =
      { config, ... }:
      {
        # Shell integration is already on through
        # home.shell.enableShellIntegration, so I don't repeat it here.
        programs.fzf.enable = true;

        programs.zsh = {
          # No programs.zsh.enable here. den.batteries.user-shell "zsh" in
          # users/tomwrw already turns it on at both the NixOS and Home
          # Manager level, and setting it again just hides where it comes
          # from.
          dotDir = "${config.xdg.configHome}/zsh";
          autosuggestion.enable = true;
          enableCompletion = true;
          shellAliases = {
            # nix-r and nix-b are not here. They name a host, so core.nix
            # hands them down through provides.to-users on the machine they
            # rebuild.
            nix-clean = "nix-collect-garbage -d --delete-old && sudo nix-collect-garbage -d --delete-old";
            hstat = "curl -o /dev/null --silent --head --write-out '%{http_code}\n' $1";
            # ls, l and la come from programs.eza in apps/shell/cli-apps.nix.
            # eza was installed but never used while these aliased coreutils.
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
            # Same path as before, written through xdg.dataHome to match
            # dotDir above. The filename keeps its leading dot on purpose,
            # renaming it would orphan my existing history.
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
