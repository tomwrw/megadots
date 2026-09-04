{ inputs, ... }:
let
  # GNOME's own defaults, so a themed desktop still looks like the desktop it
  # is. Shared by both halves below so the session and the machine underneath it
  # cannot drift.
  #
  # Stylix's gnome target writes these three dconf keys from the values here:
  #
  #   font-name            = sansSerif  + sizes.applications      -> Adwaita Sans 11
  #   monospace-font-name  = monospace  + sizes.applications      -> Adwaita Mono 11
  #   document-font-name   = serif      + sizes.applications - 1  -> Adwaita Sans 10
  #
  # The first two are exactly what gsettings-desktop-schemas ships. The document
  # font is the one that cannot match: GNOME defaults it to Adwaita Sans 12 and
  # Stylix derives the size from sizes.applications, so it lands at 10. Not
  # worth an mkForce on the dconf key to chase.
  #
  # serif is Adwaita Sans because that is what GNOME's document font is - GNOME
  # ships no serif at all. The cost is that fontconfig's generic "serif" now
  # resolves to a sans; swap it for pkgs.dejavu_fonts / "DejaVu Serif" if
  # something that asks for a serif starts looking wrong.
  #
  # Family names verified with fc-scan, not guessed: a name fontconfig cannot
  # match fails by silently substituting DejaVu.
  fonts = pkgs: {
    monospace = {
      package = pkgs.adwaita-fonts;
      name = "Adwaita Mono";
    };
    sansSerif = {
      package = pkgs.adwaita-fonts;
      name = "Adwaita Sans";
    };
    serif = {
      package = pkgs.adwaita-fonts;
      name = "Adwaita Sans";
    };
    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };

    # GNOME's interface size, and not deletable: the gnome target writes
    # font-name and monospace-font-name whatever happens, so dropping this line
    # does not fall back to GNOME's 11 - it falls back to Stylix's own default
    # of 12. Every dconf font key was a point larger than stock for exactly that
    # reason, back when the families were Stylix's DejaVu too.
    #
    # 'terminal' follows 'applications' unless set, so ghostty moves with it.
    sizes.applications = 11;
  };

  cursor = pkgs: {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  # Both halves read the same pool. One entry is the only sane state: empty
  # means nothing emitted the quirk, more than one means two aspects are
  # claiming the look and the winner would be whichever den collected first.
  pick = lib: theme: if theme == [ ] then null else lib.head theme;

  guard = lib: theme: [
    {
      assertion = lib.length theme == 1;
      message = "desktop.stylix: the theme quirk pool holds ${toString (lib.length theme)} entries, not one. It is set in modules/users/<user>.";
    }
  ];
in
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Theming at both scopes: the Home Manager session, and the host underneath it
  # so GDM, the TTY palette and plymouth match. Which scheme and which wallpaper
  # come from the theme quirk, set in the user aspect - this file owns the
  # wiring and none of the taste.
  den.aspects.stylix.homeManager =
    {
      lib,
      pkgs,
      theme,
      ...
    }:
    let
      chosen = pick lib theme;
    in
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      config = lib.mkMerge [
        { assertions = guard lib theme; }

        (lib.mkIf (chosen != null) {
          stylix = {
            enable = true;
            autoEnable = true;
            # Home Manager borrows the host's pkgs through useGlobalPkgs, so an
            # overlay here rebuilds packages the system already has.
            overlays.enable = false;
            base16Scheme = "${pkgs.base16-schemes}/share/themes/${chosen.scheme}.yaml";
            image = chosen.wallpaper;
            polarity = chosen.polarity or "dark";
            fonts = fonts pkgs;
            cursor = cursor pkgs;
            targets = {
              firefox = {
                firefoxGnomeTheme.enable = true;
                profileNames = [ "default" ];
              };
              # No obsidian.vaultNames here: Stylix needs the vault's absolute
              # path, and where the notes live is set with the rest of the
              # personal choices in users/tomwrw.
              qt.enable = false;
            };
          };
        })
      ];
    };

  # Delivered to the host from user scope, the same route apps/ssh.nix takes, so
  # the quirk resolves in the scope its producer sits in.
  #
  # homeManagerIntegration.autoImport is off, and has to be. Left on, Stylix
  # pushes its own Home Manager module into home-manager.sharedModules while the
  # block above imports the same module through den; the module system keys the
  # two differently, evaluates both, and eval dies on 'stylix.base16' being
  # read-only and set twice. Turning it off also drops followSystem, which is no
  # loss: both halves read one quirk and set the same values.
  den.aspects.stylix.nixos =
    {
      lib,
      pkgs,
      theme,
      ...
    }:
    let
      chosen = pick lib theme;
    in
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      config = lib.mkIf (chosen != null) {
        stylix = {
          enable = true;
          autoEnable = true;
          homeManagerIntegration.autoImport = false;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/${chosen.scheme}.yaml";
          image = chosen.wallpaper;
          polarity = chosen.polarity or "dark";
          fonts = fonts pkgs;
          cursor = cursor pkgs;
          # Off for the same reason as the session half, and it has to be said
          # twice because targets are per scope. autoEnable turns it on at
          # system level and costs +44 MiB of Qt5 platform theme (qtbase 5.15,
          # adwaita-qt, qgnomeplatform) to theme applications neither host
          # installs.
          targets.qt.enable = false;
        };
      };
    };
}
