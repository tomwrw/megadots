{ inputs, pkgs, ... }:
{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
    image = ../../../../../assets/wallpaper/snake.png;
    polarity = "dark";
    overlays.enable = false;
    targets = {
      firefox = {
        firefoxGnomeTheme.enable = true;
        profileNames = [ "default" ];
      };
      qt.enable = false;
    };
  };
}
