{inputs, ...}: {
  flake-file.inputs = {
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.homeManager.pc = {pkgs, ...}: {
    imports = [inputs.stylix.homeModules.stylix];

    stylix = {
      enable = true;
      polarity = "dark";
      image = ../assets/wallpaper/snake.png;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
      overlays.enable = false;
      targets = {
        firefox = {
          profileNames = ["default"];
          firefoxGnomeTheme.enable = true;
        };
        qt.enable = false;
      };
    };
  };
}
