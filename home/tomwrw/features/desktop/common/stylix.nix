{ inputs, ... }:
{
  imports = [
    # Import stylix as this is used throughout this
    # configuration to theme applications.
    inputs.stylix.homeModules.stylix
  ];
  # Turn on stylix for themes. This is a very minimal
  # enablement, as most of the actual configuration I
  # perform in the hostname.nix file.
  stylix = {
    enable = true;
    autoEnable = true;
    # Disable overlays in home-manager as they conflict
    # with useGlobalPkgs. These should be applied at the
    # NixOS level instead.
    overlays.enable = false;
    # Set up firefox target and disable any targets that
    # use custom coloring in the module itself.
    targets = {
      firefox = {
        firefoxGnomeTheme.enable = true;
        profileNames = [ "default" ];
      };
    };
  };
}
