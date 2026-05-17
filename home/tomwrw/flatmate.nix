{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Import my global Home Manager configs. These are configs
    # I apply to all my Home Manager hosts for this user.
    ./global
    # Import my features for the user on this host.
    ./features/comms
    ./features/development
    ./features/media
    ./features/productivity
    ./features/security
    ./features/services
    # Import my desktop/window manager/compositor.
    ./features/desktop/gnome
  ];
  # Set up my Home Manager instance.
  home = {
    stateVersion = lib.mkDefault "25.11";
  };
  gtk.gtk4.theme = null;
  # Set up theming for this user on this host using stylix.
  # This is important as I refer to stylix lib and colors
  # throughout many modules within this configuration.
  stylix = {
    # Set up the initial stylix config.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
    image = ../../assets/wallpaper/hanged-man-tree.png;
    polarity = "dark";
    # Set my cursor preferences.
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 20;
    };
    # Set my font preferences for the user on this host.
    fonts = {
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      monospace = {
        package = pkgs.nerd-fonts.dejavu-sans-mono;
        name = "CaskaydiaMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.source-han-sans;
        name = "Source Han Sans SC";
      };
      serif = {
        package = pkgs.source-han-serif;
        name = "Source Han Serif SC";
      };
    };
  };
}
