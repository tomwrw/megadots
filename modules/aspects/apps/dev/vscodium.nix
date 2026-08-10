_: {
  den.aspects.apps.dev.vscodium = {
    # The Marketplace build of the extension, not the CLI in apps/dev/claude-code
    # - separate derivation, separate licence. core.unfree matches on
    # lib.getName, which is the pname rather than the attribute path.
    unfree = [ "vscode-extension-anthropic-claude-code" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        programs.vscodium = {
          enable = true;

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
            };
          };
        };

        # Extension state: auth tokens, recently opened, workspace storage. None
        # of it covered by the declarative settings.
        home.persistence."/persist".directories = [ ".config/VSCodium" ];
      };
  };
}
