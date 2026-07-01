{ lib, ... }:
{
  imports = [
    # Import my global Home Manager configs. These are configs
    # I apply to all my Home Manager hosts for this user.
    ./global
    # Import my features for the user on this host.
    ./features/comms
    ./features/development
    ./features/gaming
    ./features/media
    ./features/productivity
    ./features/security
    ./features/services
    # Import my desktop/window manager/compositor.
    ./features/desktop/gnome
  ];
  # Set up my Home Manager instance.
  home = {
    stateVersion = lib.mkDefault "26.05";
  };
}
