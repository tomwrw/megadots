{ inputs, ... }:
{
  # The nix daemon settings, garbage collection, and the alias set that names a
  # host.
  #
  # Those aliases live here and not in apps/shell.nix because they rebuild
  # *this* machine, so they need its name - and an aspect that takes a host
  # argument is dropped wherever there is no host. provides.to-users is the way
  # back down to the user: a bare homeManager block on a host-scope aspect is
  # emitted class-locally and never reaches them.
  #
  # ${host.name} resolves at eval time, so endgame's generation carries
  # "-H endgame" and flatmate's carries "-H flatmate". nh would default -H to
  # the running hostname if left off, but then the aspect would not be
  # parametric at all, and reading the alias would not tell me what it rebuilds.
  #
  # An "n" prefix rather than "nix-": nix owns that namespace already
  # (nix-build, nix-shell, nix-store, nix-collect-garbage, nix-diff and nine
  # more), so nix-b and nix-d could never be tab-completed. This matches the
  # git aliases in apps/git.nix. The everyday verbs are two characters; the
  # occasional and the destructive ones are spelled out, so nboot cannot be a
  # fat-fingered nb.
  #
  # Aliases and not just recipes because they cover the other axis: the
  # justfile drives *either* host *from the checkout*, these drive *this* host
  # *from anywhere*. nu/ncheck/nfmt deliberately overlap just update/check/fmt.
  den.aspects.nix.provides.to-users.homeManager =
    { host, ... }:
    {
      # home.shellAliases and not programs.zsh.shellAliases - see apps/shell.nix.
      home.shellAliases = {
        # Rebuild. nh wraps nixos-rebuild with a package diff and nom progress;
        # it finds the flake through NH_OS_FLAKE, set in apps/cli-apps.nix, so
        # none of these need to be run from the checkout.
        nr = "nh os switch -H ${host.name}";
        nb = "nh os build -H ${host.name}";
        nt = "nh os test -H ${host.name}"; # activate now, leave the bootloader alone
        nd = "nh os build -H ${host.name} --diff always"; # build, then show what would change
        nboot = "nh os boot -H ${host.name}"; # stage for next boot, do not activate
        ndry = "nh os switch -H ${host.name} --dry";
        nru = "nh os switch -H ${host.name} --update"; # update inputs, then switch

        # Flake maintenance. These take the flake explicitly rather than
        # relying on the working directory, so they reach this repo from
        # anywhere. nu covers a single input for free - "nu nixpkgs" appends it
        # as a positional argument.
        nu = ''nix flake update --flake "$NH_OS_FLAKE"'';
        ncheck = ''nix flake check "$NH_OS_FLAKE"'';
        nshow = ''nix flake show "$NH_OS_FLAKE"'';
        nmeta = ''nix flake metadata "$NH_OS_FLAKE"'';

        # Generations and the store.
        ngen = "nh os info";
        nback = "nh os rollback --ask";
        # --keep-since 30d and not "-d --delete-old", which took every old
        # generation including yesterday's working one. This matches the window
        # nix.gc already applies weekly below, and the justfile's gc recipe -
        # two collectors with different retention on one store is how I lose
        # the generation I wanted.
        nclean = "nh clean all --keep 5 --keep-since 30d --ask";

        # Search and inspect. ns queries search.nixos.org against
        # nixos-unstable, which is the nixpkgs this flake tracks; nsp is slower
        # but evaluates the *pinned* nixpkgs and works offline.
        ns = "nh search";
        nso = "nh search options";
        nsp = "nix search nixpkgs";
        nrepl = "nh os repl -H ${host.name}";
        nwhy = "nix why-depends";
      };
    };

  den.aspects.nix.nixos =
    { lib, ... }:
    {
      nix = {
        # Makes "nix run nixpkgs#..." use the same nixpkgs the system was built
        # from. Only nixpkgs: mapping every input pulls each source into the
        # system closure, pushed on every rebuild and held for the GC window.
        registry.nixpkgs.flake = inputs.nixpkgs;

        settings = {
          # See https://jackson.dev/post/nix-reasonable-defaults/ for
          # explanation of sensible defaults.
          connect-timeout = 5;
          log-lines = 25;
          # Trust wheel so 'nixos-rebuild --target-host' can push closures I
          # built locally to my other hosts. Single admin, LAN only.
          trusted-users = [
            "root"
            "@wheel"
          ];
          # Hard-link identical store paths as they're written instead of
          # running nix.optimise later. Slightly slower builds, but I never
          # have to remember to run it.
          auto-optimise-store = true;

          # Leave IFD on. Stylix reads its base16 scheme yaml out of a
          # derivation at eval time, so turning this off breaks the theming.
          allow-import-from-derivation = true;

          warn-dirty = false;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          max-jobs = "auto";
          cores = 0;
          show-trace = true;
          sandbox = true;
          keep-build-log = true;
          fallback = true;

          # Free space mid-build once under 512MB, up to 1GB. mkDefault so a
          # host with a small disk can lower it.
          min-free = lib.mkDefault 536870912;
          max-free = lib.mkDefault 1073741824;
        };
        # Automatically clean up stale generations and store paths.
        gc = {
          automatic = true;
          dates = "weekly";
          # Delete generations older than 30 days.
          options = "--delete-older-than 30d";
        };
      };

      programs.nix-ld.enable = true;
    };
}
