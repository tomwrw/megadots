{ pkgs, ... }:
{
  home.packages = with pkgs; [
    element-desktop
  ];

  home.persistence."/persist" = {
    directories = [
      ".config/Element"
    ];
  };
}
