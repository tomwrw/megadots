{
  pkgs,
  inputs,
  ...
}:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in
{
  imports = [
    # Import the spicetify-nix module for Home Manager.
    inputs.spicetify-nix.homeManagerModules.default
  ];
  # Enable spicetify-nix and extensions.
  programs.spicetify = {
    enable = true;
    wayland = false;
    enabledExtensions = with spicePkgs.extensions; [
      playlistIcons
      historyShortcut
      fullAppDisplay
      shuffle
    ];
    enabledCustomApps = with spicePkgs.apps; [
      newReleases
      ncsVisualizer
      historyInSidebar
    ];
  };
}
