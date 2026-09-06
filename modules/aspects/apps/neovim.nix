{ inputs, ... }:
let
  # The text types Omarchy points at nvim.desktop in
  # default/applications/mimeapps.list. That list is neovim's own desktop entry
  # MimeType line plus the two xml types, so this is the set that makes
  # double-clicking a text file in Files land in the editor.
  #
  # text/html and application/pdf are deliberately absent: apps/firefox.nix
  # claims those, and two aspects claiming one type is a race, not a merge.
  textTypes = [
    "text/plain"
    "text/english"
    "text/x-makefile"
    "text/x-c++hdr"
    "text/x-c++src"
    "text/x-chdr"
    "text/x-csrc"
    "text/x-java"
    "text/x-moc"
    "text/x-pascal"
    "text/x-tcl"
    "text/x-tex"
    "text/x-c"
    "text/x-c++"
    "application/x-shellscript"
    "application/xml"
    "text/xml"
  ];
in
{
  flake-file.inputs.nvf = {
    url = "github:notashelf/nvf";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Neovim through nvf, which is a Nix module system for the editor rather than
  # a pile of lua: a plugin is one option, a language is one line that brings
  # its LSP, treesitter grammar and formatter together.
  #
  # Nothing here sets a colour. Stylix's nvf target writes the scheme from the
  # theme quirk straight into vim.theme, and it is gated on
  # "options.programs ? nvf" - so importing the module below is what switches
  # theming on, and setting vim.theme here would fight it.
  den.aspects.neovim = {
    # Everything nvf configures is rewritten on activation. The state directory
    # is the only thing neovim writes at runtime: shada (marks, registers,
    # command history, last cursor position) and the undo files that
    # vim.undoFile puts under stdpath('state').
    #
    # The directory, NOT the files in it - shada is saved by renaming a temp
    # file over the target, which is the same trap apps/zsh.nix documents for
    # .zsh_history: the rename replaces impermanence's symlink with a real file
    # and the next activation dies on "A file already exists at ...".
    persist.home.directories = [ ".local/state/nvim" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [ inputs.nvf.homeManagerModules.nvf ];

        programs.nvf = {
          enable = true;

          # Exports EDITOR=nvim. VISUAL is set below - nvf only claims EDITOR,
          # and the two disagreeing is how you end up with git using one editor
          # and sudoedit another.
          defaultEditor = true;

          settings.vim = {
            viAlias = true;
            vimAlias = true;

            # Persistent undo across sessions, which is what makes the persist
            # entry above worth having.
            undoFile.enable = true;

            # What this repo is actually made of. Each line brings that
            # language's LSP, grammar and formatter, per the enable* flags.
            languages = {
              enableTreesitter = true;
              enableFormat = true;
              enableExtraDiagnostics = true;

              nix.enable = true;
              bash.enable = true;
              lua.enable = true;
              markdown.enable = true;
              just.enable = true;
              json.enable = true;
              yaml.enable = true;
              toml.enable = true;
            };

            lsp.enable = true;
            treesitter.context.enable = true;

            # Completion and snippets.
            autocomplete.blink-cmp.enable = true;
            snippets.luasnip.enable = true;

            # The bits that make it feel like a configured editor rather than a
            # bare nvim: fuzzy finder, file tree, statusline, buffer line,
            # git gutter, and which-key so the bindings are discoverable
            # instead of memorised.
            telescope.enable = true;
            filetree.neo-tree.enable = true;
            statusline.lualine.enable = true; # theme comes from Stylix
            tabline.nvimBufferline.enable = true;
            git.gitsigns.enable = true;
            binds.whichKey.enable = true;

            autopairs.nvim-autopairs.enable = true;
            comments.comment-nvim.enable = true;
            utility.surround.enable = true;
            utility.motion.flash-nvim.enable = true;
            utility.undotree.enable = true;

            # Only the direnv.vim wrapper - it shells out to a direnv binary,
            # which apps/direnv.nix installs. Not an include of that aspect:
            # direnv is a shell tool in its own right, wanted by the terminal
            # and VSCodium too, so it hangs off the user rather than off the
            # editor. If this ever prints "no direnv executable found" again,
            # den.aspects.direnv has gone missing from users/tomwrw.
            utility.direnv.enable = true;

            terminal.toggleterm.enable = true;

            visuals = {
              nvim-web-devicons.enable = true;
              indent-blankline.enable = true;
              fidget-nvim.enable = true;
              nvim-cursorline.enable = true;
            };

            ui.noice.enable = true;
            notify.nvim-notify.enable = true;
            dashboard.alpha.enable = true;
          };
        };

        # nvf sets EDITOR through defaultEditor; VISUAL is ours.
        home.sessionVariables.VISUAL = "nvim";

        # As Omarchy has it. Free: no binary on PATH is called n, and it cannot
        # be confused with the nr/nb/nt set in core/nix.nix.
        home.shellAliases.n = "nvim";

        # The entry that makes double-click work, and the reason it names its
        # own terminal: nvf's package ships its own share/applications/
        # nvim.desktop with "Terminal=true" and "Exec=nvim %F", and the glib in
        # this closure has no terminal-discovery left in libgio - no
        # xdg-terminals.list, no hardcoded fallback list - so nothing resolves
        # it and double-clicking that entry does nothing at all.
        #
        # This deliberately reuses the id "nvim" to shadow it: Home Manager
        # writes to ~/.local/share/applications, and XDG_DATA_HOME takes
        # precedence over the profile in XDG_DATA_DIRS, so ours is the one that
        # resolves. A distinct id would leave two "Neovim" entries in the menu,
        # one of them the broken one. If a double-click ever silently does
        # nothing, this shadowing is the first thing to check.
        #
        # Store paths rather than bare "ghostty" and "nvim", for the reason
        # apps/vscodium.nix gives about nix.serverPath: a desktop entry runs
        # with whatever PATH the session handed the launcher, not the shell's.
        # Naming pkgs.ghostty directly also keeps this from becoming an
        # invisible dependency on apps/ghostty.nix being included, which is the
        # trap apps/firefox.nix records for xdg.mimeApps.enable.
        xdg.desktopEntries.nvim = {
          name = "Neovim";
          genericName = "Text Editor";
          comment = "Edit text files";
          icon = "nvim";
          exec = "${lib.getExe pkgs.ghostty} -e ${config.programs.nvf.finalPackage}/bin/nvim %F";
          terminal = false;
          type = "Application";
          categories = [
            "Utility"
            "TextEditor"
            "Development"
          ];
          mimeType = textTypes;
        };

        # Home Manager only writes mimeapps.list if this is set, and relying on
        # desktop/gnome.nix happening to set it is the invisible dependency
        # apps/firefox.nix already got caught by.
        xdg.mimeApps.enable = true;
        xdg.mimeApps.defaultApplications = lib.genAttrs textTypes (_: [ "nvim.desktop" ]);
      };
  };
}
