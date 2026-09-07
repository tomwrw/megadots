_: {
  # The repo's tasks, plus what I reach for by hand. 'nix develop' is the way
  # in, and inside it every task in flake/tasks.nix is a bare command:
  # 'rebuild endgame' rather than 'nix run .#rebuild endgame'.
  #
  # core/system-packages.nix only carries what my hosts need at runtime, not
  # what working on this repo needs.
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages =
          # Every task, from the one place they are defined.
          builtins.attrValues config.packages
          ++ (with pkgs; [
            # Not tasks, but the tools I use directly on this tree. The tasks
            # declare their own runtimeInputs and do not rely on these.
            age
            nixfmt
            nvd
            sops
            ssh-to-age
          ]);
      };
    };
}
