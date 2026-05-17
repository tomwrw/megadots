{ pkgs, ... }:
{
  home.packages = with pkgs; [
    code-cursor
  ];

  home.persistence."/persist" = {
    directories = [
      ".cursor"
      ".config/cursor"
      ".config/Cursor"
    ];
  };
}
