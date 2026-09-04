{ inputs, den, ... }:
{
  flake-file.inputs.spicetify-nix = {
    url = "github:Gerg-L/spicetify-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # The Spotify desktop client.
  den.aspects.spotify.includes = [
    (den.batteries.unfree [
      "spotify"
      "spicetify-stylix"
    ])
  ];

  den.aspects.spotify.persist.home.directories = [ ".config/spotify" ];

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
        # 'with' here is spicetify-nix's own namespaced extension/app lists,
        # not pkgs/lib, so it doesn't carry the usual "obscures where
        # bindings come from" risk that with pkgs;/with lib; would.
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
