{ inputs, ... }:
{
  flake-file.inputs = {
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixpkgs.config.allowUnfreePackages = [
    "spotify"
    "spotify-unwrapped"
  ];

  flake.modules.homeManager.gaming =
    { pkgs, ... }:
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
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
