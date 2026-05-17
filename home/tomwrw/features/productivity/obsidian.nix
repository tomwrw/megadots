{ pkgs, ... }:
{
  home.packages = with pkgs; [
    obsidian
  ];

  home.persistence."/persist" = {
    directories = [
      ".config/obsidian"
    ];
  };
}
