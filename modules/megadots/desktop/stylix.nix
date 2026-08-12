{ inputs, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # The mechanism lives here, the taste lives at the call site. This aspect
  # used to hardcode a scheme, a wallpaper and the path to my Obsidian vault,
  # which made it the one thing under modules/megadots/ that nobody else could
  # take without editing it first.
  #
  # Options rather than a callable aspect. den reads a bare function at an
  # aspect path as parametric over *scope* arguments - host, user, home - so
  # 'megadots.desktop.stylix = { scheme, wallpaper }: ...' would ask den for
  # a scope argument called "scheme", not find one, and drop the aspect with no
  # error at all. That footgun is worth avoiding for a setting as visible as
  # the desktop theme; options fail loudly and are self-documenting besides.
  megadots.desktop.stylix.description = "System-wide theming. Declares megadots.theme options rather than hardcoding a scheme or wallpaper.";

  megadots.desktop.stylix.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      options.megadots.theme = {
        scheme = lib.mkOption {
          type = lib.types.str;
          example = "rose-pine-moon";
          description = ''
            A base16 scheme name from the base16-schemes package, without the
            .yaml. Stylix reads the file out of that derivation at eval time,
            which is the import-from-derivation core/nix.nix has to allow.
          '';
        };

        wallpaper = lib.mkOption {
          type = lib.types.path;
          description = ''
            The image Stylix themes from. Also the desktop background, so it is
            both an input to the palette and a thing I have to look at.
          '';
        };

        polarity = lib.mkOption {
          type = lib.types.enum [
            "dark"
            "light"
            "either"
          ];
          default = "dark";
          description = ''
            Kept in step with GNOME's color-scheme by Stylix's gnome target.
            Neither side uses mkDefault, so changing this to "light" without
            changing desktop/gnome.nix would be an eval conflict rather than a
            silent mismatch.
          '';
        };
      };

      config.stylix = {
        enable = true;
        autoEnable = true;
        overlays.enable = false;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.megadots.theme.scheme}.yaml";
        image = config.megadots.theme.wallpaper;
        inherit (config.megadots.theme) polarity;
        targets = {
          firefox = {
            firefoxGnomeTheme.enable = true;
            profileNames = [ "default" ];
          };
          # No obsidian.vaultNames here. Stylix needs the vault's absolute path
          # to drop a CSS snippet in, but where I keep my notes is not
          # something a reusable theming aspect should know - it is set next to
          # the rest of my choices in users/tomwrw.
          qt.enable = false;
        };
      };
    };
}
