_: {
  # zsh with starship, fzf, completion and history.
  #
  # A sub-aspect of shell rather than an aspect of its own, the same shape
  # core/boot.nix uses for its bootloaders: the parent carries what every shell
  # shares - the aliases - and this provides the one implementation. A provides
  # child does not inherit its parent, so users/tomwrw includes both, exactly as
  # roles/base.nix takes den.aspects.boot while each host takes its loader.
  #
  # Names no host, deliberately. This aspect used to open with "{ host, ... }:"
  # so two aliases could run nixos-rebuild, and den reads a bare function at an
  # aspect path as parametric over scope arguments - so anywhere without a host
  # it was dropped whole, with no error.
  #
  # No aliases here at all now. They are filed with the tool they drive:
  # core/nix.nix for the nix set, which is host scope and can name the machine
  # it rebuilds, apps/git.nix for git, and apps/shell.nix for the rest.
  den.aspects.shell.provides.zsh = {
    # Shell history is the one thing here zsh writes at runtime; everything else
    # is rewritten on activation.
    #
    # The directory, NOT the .zsh_history file inside it. impermanence leaves a
    # symlink until the /persist copy exists, and zsh saves history by renaming
    # a temp file over the target - which replaces the symlink with a real file,
    # so the history never reaches /persist and the next activation dies with "A
    # file already exists at ...". A directory entry is a real bind mount from
    # the start.
    persist.home.directories = [ ".local/share/zsh" ];

    homeManager =
      { config, ... }:
      {
        # Shell integration is already on through home.shell.enableShellIntegration.
        programs.fzf.enable = true;

        programs.zsh = {
          # No enable here: den.batteries.user-shell "zsh" in users/tomwrw turns
          # it on at both levels, and repeating it hides where it comes from.
          dotDir = "${config.xdg.configHome}/zsh";
          autosuggestion.enable = true;
          enableCompletion = true;
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
