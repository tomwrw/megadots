{ den, ... }:
{
  megadots.apps.dev.vscodium = {
    description = "VSCodium with a fully declarative extension list and no mutable extension directory.";

    # The Marketplace build of the extension, not the CLI in apps/dev/claude-code
    # - separate derivation, separate licence. den's predicate matches on
    # lib.getName, which is the pname rather than the attribute path.
    includes = [ (den.batteries.unfree [ "vscode-extension-anthropic-claude-code" ]) ];

    home-persist.directories = [
      # Extension state: auth tokens, recently opened, workspace storage. None
      # of it covered by the declarative settings.
      ".config/VSCodium"

      # VSCodium's *data folder*, which is a different thing to its config and
      # was the one I missed. It holds argv.json, the cli directory, and the
      # first-run bookkeeping that decides whether a launch is a fresh install.
      #
      # Without it every boot was a first run: no icons and no highlighting on
      # nix files, a "do you trust this workspace" prompt, and everything
      # correct only after quitting and reopening. Confirmed rather than
      # guessed - the machine booted at 08:44:36 and argv.json was created at
      # 08:45:15, on the first launch after it, every time.
      #
      # The extensions symlink Home Manager writes in here is fine to have
      # inside a persisted directory: settings.json already works that way
      # inside .config/VSCodium above. Activation replaces the symlink on every
      # boot, so the copy in /persist is only ever a stale pointer between
      # generations.
      ".vscode-oss"

      # Application-scoped storage, which is a *third* location and the one
      # that actually holds workspace trust:
      #
      #   .vscode-oss-shared/sharedStorage/state.vscdb
      #     content.trust.model.key -> {"uriTrustInfo":[{ ..., "trusted":true}]}
      #     history.recentlyOpenedPathsList
      #
      # VSCodium keeps this outside the user-data-dir entirely - it is the data
      # folder name with "-shared" appended, a sibling of .vscode-oss rather
      # than anything under .config/VSCodium - so persisting the config
      # directory does not cover it and no amount of looking in there finds it.
      #
      # Losing it every boot is why the first launch after a reboot always
      # asked whether I trusted my own config repo, and why the extensions were
      # missing until I restarted: an untrusted folder opens in Restricted
      # Mode, which disables every extension that runs code. nix-ide and
      # claude-code both do, so the editor came up with syntax highlighting and
      # nothing else.
      #
      # This persisted for free while /home was its own subvolume. Moving to
      # per-directory home persistence dropped it, because nothing in this repo
      # knew the directory existed.
      ".vscode-oss-shared"
    ];

    homeManager =
      { lib, pkgs, ... }:
      {
        programs.vscodium = {
          enable = true;

          # Same stance as users.mutableUsers: the list below is the only source
          # of truth. Left mutable, anything installed from the UI lands in
          # ~/.vscode-oss/extensions, which is not persisted - so it would
          # disappear on the next boot with no error, the way a missing
          # home.persistence entry always does.
          mutableExtensionsDir = false;

          profiles.default = {
            extensions = [
              pkgs.vscode-extensions.jnoortheen.nix-ide
              pkgs.vscode-extensions.anthropic.claude-code
              pkgs.vscode-extensions.nefrob.vscode-just-syntax
            ];

            # Nix IDE ships with the language server switched off, so without
            # this the extension is syntax highlighting and nothing else.
            #
            # serverPath and formatterPath already default to the bare names
            # "nixd" and "nixfmt", and both are installed in
            # apps/shell/cli-apps.nix - but that resolves against whatever PATH
            # the desktop entry starts VSCodium with. Store paths do not.
            userSettings = {
              "nix.enableLanguageServer" = true;
              "nix.serverPath" = lib.getExe pkgs.nixd;
              "nix.formatterPath" = lib.getExe pkgs.nixfmt;
              "git.enableSmartCommit" = true;
            };
          };
        };
      };
  };
}
