{ den, ... }:
{
  # VSCodium with a fully declarative extension list and no mutable extension
  # directory.
  den.aspects.vscodium = {
    # The Marketplace build of the extension, not the CLI in apps/claude-code:
    # separate derivation, separate licence. den's predicate matches on
    # lib.getName, which is the pname rather than the attribute path.
    includes = [ (den.batteries.unfree [ "vscode-extension-anthropic-claude-code" ]) ];

    # Three separate directories, and missing any one of them costs something
    # that looks like a different bug entirely.
    persist.home.directories = [
      # Extension state: auth tokens, recently opened, workspace storage.
      ".config/VSCodium"

      # The *data folder*, which is not the config directory. Holds argv.json,
      # the cli directory and the first-run bookkeeping - without it every boot
      # is a first run, with no icons or highlighting on nix files until the
      # editor is quit and reopened.
      #
      # The extensions symlink Home Manager writes in here is fine inside a
      # persisted directory: activation replaces it every boot, so the copy in
      # /persist is only ever a stale pointer between generations.
      ".vscode-oss"

      # Application-scoped storage, a *third* location, and the one that holds
      # workspace trust:
      #
      #   .vscode-oss-shared/sharedStorage/state.vscdb
      #     content.trust.model.key -> {"uriTrustInfo":[{ ..., "trusted":true}]}
      #
      # VSCodium keeps it outside the user-data-dir entirely - the data folder
      # name with "-shared" appended - so persisting the config directory does
      # not cover it. Lose it and the first launch after a reboot asks whether
      # this repo is trusted, and an untrusted folder opens in Restricted Mode
      # with every code-running extension disabled.
      ".vscode-oss-shared"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        programs.vscodium = {
          enable = true;

          # Same stance as users.mutableUsers: the list below is the only source
          # of truth. Left mutable, anything installed from the UI lands in
          # ~/.vscode-oss/extensions and disappears on the next boot with no
          # error, the way a missing persist entry always does.
          mutableExtensionsDir = false;

          profiles.default = {
            extensions = [
              pkgs.vscode-extensions.jnoortheen.nix-ide
              pkgs.vscode-extensions.anthropic.claude-code
              pkgs.vscode-extensions.nefrob.vscode-just-syntax
            ];

            # Nix IDE ships with the language server off, so without this the
            # extension is syntax highlighting and nothing else. The paths are
            # store paths on purpose: the defaults are the bare names "nixd" and
            # "nixfmt", resolved against whatever PATH the desktop entry started
            # VSCodium with.
            userSettings = {
              "nix.enableLanguageServer" = true;
              "nix.serverPath" = lib.getExe pkgs.nixd;
              "nix.formatterPath" = lib.getExe pkgs.nixfmt;
              "git.enableSmartCommit" = true;
              "git.confirmSync" = false;
            };
          };
        };
      };
  };
}
