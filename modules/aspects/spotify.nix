{ inputs, ... }:
{
  flake-file.inputs.spicetify-nix = {
    url = "github:Gerg-L/spicetify-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.spotify.unfree = [
    "spotify"
    # The spicetify wrapper (themed by stylix) inherits spotify's licence
    # under its own name.
    "spicetify-stylix"
  ];

  den.aspects.spotify.homeManager =
    { pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
    in
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.default ];

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
    };
}
