_: {
  # The Bitwarden desktop client.
  den.aspects.bitwarden = {
    persist.home.directories = [ ".config/Bitwarden CLI" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.bitwarden-cli ];
      };
  };
}
