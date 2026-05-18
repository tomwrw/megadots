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
  # Set up theming for this user on this host using stylix.
  # This is important as I refer to stylix lib and colors
  # throughout many modules within this configuration.
  stylix = {
    # Set up the initial stylix config.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";
    image = ../../assets/wallpaper/snake.png;
    polarity = "dark";
  };
}
