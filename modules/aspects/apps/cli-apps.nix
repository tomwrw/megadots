_: {
  # A set of command-line tools that replace or supplement the coreutils defaults.
  den.aspects.cli-apps.homeManager =
    { config, pkgs, ... }:
    {
      # eza and nh go through their Home Manager modules and not home.packages.
      # programs.eza sets up the ls aliases, see apps/shell.nix, and
      # programs.nh carries the flake and config plumbing.
      #
      # nh.clean stays off. core/nix.nix already runs nix.gc weekly, and two
      # garbage collectors with different retention on one store is how I lose
      # the generation I wanted.
      programs.eza.enable = true;
      programs.nh.enable = true;

      # Exports NH_OS_FLAKE, which is what lets the nix aliases in core/nix.nix
      # and the scripts below reach this repo from any directory. Written once,
      # here; everything else reads it back out of the environment.
      #
      # The mutable checkout, deliberately - not inputs.self, which evaluates to
      # a /nix/store path that nix flake update cannot write a lock file into.
      # Same homeDirectory-relative shape as the Obsidian vault path in
      # users/tomwrw, out of the same Syncthing tree, so it resolves on every
      # host that syncs it.
      #
      # One consequence: "nh os switch" now means this flake even while standing
      # in another checkout. "nh os switch ." overrides it for the one-off.
      programs.nh.osFlake = "${config.home.homeDirectory}/Syncthing/02 Area/Development/megadots";

      home.packages = [
        pkgs.bc # arbitrary-precision calculator
        pkgs.fastfetch # system info
        pkgs.ncdu # disk usage analyzer
        pkgs.nix-diff # compare derivations
        pkgs.nix-output-monitor # nicer build logs
        pkgs.nixd # Nix language server
        pkgs.nixfmt # Nix formatter
        pkgs.nvd # Nix version diff

        # The helpers that cannot be aliases, because they need an argument in
        # the middle of a command or a working directory. Scripts rather than
        # zsh functions so they behave the same in whatever shell I end up in,
        # and so shellcheck runs over them at build time.
        #
        # Three of these read NH_OS_FLAKE, set by programs.nh above.
        (pkgs.writeShellApplication {
          name = "hstat";
          runtimeInputs = [ pkgs.curl ];
          # Was an alias, which is why it never worked: an alias is literal
          # text, so $1 expanded to nothing in an interactive shell and curl
          # got a stray empty argument instead of the URL.
          text = ''
            curl -o /dev/null --silent --head --write-out '%{http_code}\n' "$1"
          '';
        })

        (pkgs.writeShellApplication {
          name = "nfmt";
          # nix fmt has no --flake, it resolves the formatter from the flake in
          # the working directory - so unlike nu and ncheck this one has to cd.
          text = ''
            cd "$NH_OS_FLAKE" && exec nix fmt "$@"
          '';
        })

        (pkgs.writeShellApplication {
          name = "nopt";
          # Reads the option out of the flake, so it answers before a rebuild.
          # nixos-option only ever shows the running system.
          text = ''
            exec nix eval "$NH_OS_FLAKE#nixosConfigurations.$(hostname).config.$1"
          '';
        })

        (pkgs.writeShellApplication {
          name = "ngdiff";
          runtimeInputs = [ pkgs.nvd ];
          # Generation numbers as ngen prints them.
          text = ''
            exec nvd diff \
              "/nix/var/nix/profiles/system-$1-link" \
              "/nix/var/nix/profiles/system-$2-link"
          '';
        })
      ];
    };
}
