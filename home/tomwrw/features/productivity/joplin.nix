{ pkgs, ... }:
{
  home.packages = with pkgs; [
    joplin
    joplin-desktop
  ];

  home.persistence."/persist" = {
    directories = [
      ".config/Joplin"
      ".config/joplin-desktop"
    ];
  };
}
