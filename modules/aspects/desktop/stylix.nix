{ inputs, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.desktop.stylix.homeManager =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        autoEnable = true;
        overlays.enable = false;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
        image = ../../../assets/wallpaper/snake.png;
        polarity = "dark";
        targets = {
          firefox = {
            firefoxGnomeTheme.enable = true;
            profileNames = [ "default" ];
          };
          obsidian = {
            vaultNames = [ "/home/tomwrw/Sync/Notes" ];
          };
          qt.enable = false;
        };
      };
    };
}
