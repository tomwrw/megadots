{ inputs, pkgs, ... }:
{
  imports = [
    # Import stylix as this is used throughout this
    # configuration to theme applications.
    inputs.stylix.homeModules.stylix
  ];
  # Turn on stylix and set the base16 scheme, wallpaper and
  # polarity that drive theming across the whole desktop.
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
    image = ../../../../../assets/wallpaper/snake.png;
    polarity = "dark";
    # Disable overlays in home-manager as they conflict
    # with useGlobalPkgs. These should be applied at the
    # NixOS level instead.
    overlays.enable = false;
    # Set up firefox target and disable any targets that
    # use custom coloring in the module itself.
    targets = {
      firefox = {
        firefoxGnomeTheme.enable = true;
        profileNames = [ "default" ];
      };
      qt.enable = false;
    };
  };
  # Disable gtk4 theme as it interferes with stylix config.
  gtk.gtk4.theme = null;
}
